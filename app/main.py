from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import Cookie, FastAPI, Query, Request, Response
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.config import get_settings
from app.logging_config import configure_logging
from app.models import AutocompleteSuggestion, DepartureBoard
from app.services.departures import DepartureService
from app.services.idfm import (
    IdfmApiClient,
    ServiceConfigurationError,
    UpstreamInvalidTokenError,
    UpstreamRateLimitError,
    UpstreamUnavailableError,
)
from app.services.schedules import ScheduleIndex
from app.services.stations import StationCatalog

settings = get_settings()
configure_logging(settings.log_level)

stations = StationCatalog()
idfm_client = IdfmApiClient(settings.idfm_api_token, settings.request_timeout_seconds)
schedule_index = ScheduleIndex()
departure_service = DepartureService(settings, stations, idfm_client, schedule_index)
templates = Jinja2Templates(directory="app/templates")
DEFAULT_THEME = "moderne"
SUPPORTED_THEMES = {DEFAULT_THEME, "standard"}


@asynccontextmanager
async def lifespan(_: FastAPI):
    yield
    await idfm_client.close()
    schedule_index.close()


app = FastAPI(title="rer-web", lifespan=lifespan)
app.mount("/static", StaticFiles(directory="app/static"), name="static")


def no_cache(response: Response) -> None:
    response.headers["Cache-Control"] = "no-store"


def line_filter_from_query(line: str | None, legacy_line: str | None) -> str | None:
    return (line or legacy_line or "").strip().upper() or None


def resolve_theme(theme: str | None, theme_cookie: str | None) -> str:
    candidate = (theme or theme_cookie or DEFAULT_THEME).strip().lower()
    return candidate if candidate in SUPPORTED_THEMES else DEFAULT_THEME


def render_api_error(status_code: int, message: str) -> JSONResponse:
    return JSONResponse(status_code=status_code, content={"error": message})


@app.get("/", response_class=HTMLResponse)
async def index(
    request: Request,
    s: str | None = Query(default=None),
    station: str | None = Cookie(default=None),
    theme: str | None = Query(default=None),
    theme_cookie: str | None = Cookie(default=None, alias="theme"),
) -> HTMLResponse:
    station_code = s or station or settings.default_station
    selected_theme = resolve_theme(theme, theme_cookie)
    selected_station = stations.find_by_code(station_code)
    if s is None:
        if selected_station is None:
            selected_station = stations.default_station(settings.default_station)
        redirect_url = f"/?s={selected_station.primary_code}"
        if selected_theme != DEFAULT_THEME:
            redirect_url = f"{redirect_url}&theme={selected_theme}"
        return RedirectResponse(url=redirect_url, status_code=302)
    if selected_station is None:
        response = templates.TemplateResponse(
            request,
            "error.html",
            {
                "request": request,
                "message": "The requested station code was not found.",
                "status_code": 404,
                "selected_station": stations.default_station(settings.default_station),
                "theme": selected_theme,
            },
            status_code=404,
        )
        response.set_cookie("theme", selected_theme, max_age=60 * 60 * 24 * 28, httponly=False)
        return response

    response = templates.TemplateResponse(
        request,
        "index_standard.html" if selected_theme == "standard" else "index.html",
        {
            "request": request,
            "selected_station": selected_station,
            "stations": [station.to_autocomplete().model_dump() for station in stations.stations],
            "default_station": settings.default_station,
            "theme": selected_theme,
        },
    )
    response.set_cookie("station", selected_station.primary_code, max_age=60 * 60 * 24 * 28, httponly=False)
    response.set_cookie("theme", selected_theme, max_age=60 * 60 * 24 * 28, httponly=False)
    return response


@app.get("/api/departures", response_model=DepartureBoard, response_model_by_alias=True)
@app.get("/json", response_model=DepartureBoard, response_model_by_alias=True)
async def departures(
    response: Response,
    s: str = Query(...),
    line: str | None = Query(default=None),
    l: str | None = Query(default=None),
) -> DepartureBoard | JSONResponse:
    no_cache(response)
    station = stations.find_by_code(s)
    if station is None:
        return render_api_error(404, "Station not found.")

    try:
        board = await departure_service.get_board(station, line_filter_from_query(line, l))
    except ServiceConfigurationError as exc:
        return render_api_error(503, str(exc))
    except UpstreamInvalidTokenError as exc:
        return render_api_error(503, str(exc))
    except UpstreamRateLimitError as exc:
        return render_api_error(429, str(exc))
    except UpstreamUnavailableError as exc:
        return render_api_error(503, str(exc))

    return board


@app.get("/api/stations/autocomplete", response_model=list[AutocompleteSuggestion])
@app.get("/autocomp", response_model=list[AutocompleteSuggestion])
async def autocomplete(response: Response, s: str = Query(default="")) -> list[AutocompleteSuggestion]:
    no_cache(response)
    return stations.autocomplete(s)


@app.get("/health")
async def health() -> JSONResponse:
    token_configured = bool(settings.idfm_api_token)
    payload = {
        "status": "ok" if token_configured else "degraded",
        "token_configured": token_configured,
        "station_count": stations.count(),
        "cache_ttl_seconds": settings.cache_ttl_seconds,
    }
    return JSONResponse(status_code=200 if token_configured else 503, content=payload)
