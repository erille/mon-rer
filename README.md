# rer-web

Modern rewrite of the legacy departures board for Ile-de-France Mobilites train data.

## Stack

- Python 3.12+
- FastAPI
- Jinja templates
- Vanilla JavaScript
- Docker for deployment

## What Changed

The old Perl/Dancer + PostgreSQL + GTFS import pipeline has been replaced with a smaller FastAPI app that is easier to run and maintain.

Preserved behavior:

- station selection with `/?s=CODE`
- live departures board
- station autocomplete
- line filtering
- saved station cookie
- compatibility endpoints: `/json` and `/autocomp`

Improvements:

- typed configuration from environment variables
- explicit handling for invalid token, rate limits, upstream failures, and empty results
- health endpoint at `/health`
- simpler deployment with Docker
- cleaner responsive UI
- structured Python service layer and tests

## Important Migration Assumptions

- The rewrite intentionally removes the legacy PostgreSQL + GTFS schedule database to avoid the largest operational burden in the original project.
- The app still shows planned and expected departure times from the live IDFM payload when available.
- Downstream stopping patterns from the old GTFS enrichment are not rebuilt in this version, so `dessertes` currently falls back to `Desserte indisponible`.
- A compact station dataset is bundled from the legacy repository data. A small number of stations in that snapshot do not have a usable real-time stop-area reference and will return a clear message instead of departures.
- Line reference mapping is bundled from the SNCF GTFS routes dataset so line badges and filters still work without keeping a live GTFS database.

## Environment Variables

Required:

- `IDFM_API_TOKEN`: API token for `prim.iledefrance-mobilites.fr`

Optional:

- `APP_ENV`: application environment, default `development`
- `HOST`: bind host, default `0.0.0.0`
- `PORT`: bind port, default `8000`
- `LOG_LEVEL`: logging level, default `INFO`
- `DEFAULT_STATION`: default station code, default `GDS`
- `CACHE_TTL_SECONDS`: upstream cache TTL, default `20`
- `REQUEST_TIMEOUT_SECONDS`: upstream request timeout, default `8`
- `MAX_DEPARTURES`: number of departures to display, default `6`

See `.env.example`.

## Local Run

1. Copy `.env.example` to `.env`.
2. Set `IDFM_API_TOKEN` in `.env`.
3. Install dependencies:

```bash
python -m pip install -e .[dev]
```

4. Start the app:

```bash
python -m app
```

Open `http://127.0.0.1:8000`.

For auto-reload during development:

```bash
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Docker

Build and run with Docker Compose:

```bash
docker compose up --build -d
```

Or plain Docker:

```bash
docker build -t rer-web .
docker run --env-file .env -p 8000:8000 --restart unless-stopped rer-web
```

The container binds to `HOST` and `PORT` from the environment. For a standard reverse proxy setup, keep `HOST=0.0.0.0` and proxy to the configured `PORT`.

## Endpoints

- `/`: HTML app
- `/json`: legacy-compatible departures JSON
- `/api/departures`: canonical departures JSON
- `/autocomp`: legacy-compatible station autocomplete JSON
- `/api/stations/autocomplete`: canonical station autocomplete JSON
- `/health`: health check

## Tests

```bash
python -m pytest
```

## Footer Credits

The footer now shows:

- `ketah.info`
- `Original author: https://x0r.fr`
