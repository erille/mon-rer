const APP_NAME = "IDF Trains by Ketah";
const FAVORITE_STATIONS_STORAGE_KEY = "idf-trains.favorite-stations";
const appData = window.__APP_DATA__;

function findStation(code) {
  return appData.stations.find((station) => station.codes.includes(code));
}

function normalizeStationCode(code) {
  return findStation(code)?.codes[0] || null;
}

function sortStationCodesByName(codes) {
  return [...codes].sort((leftCode, rightCode) => {
    const leftStation = findStation(leftCode);
    const rightStation = findStation(rightCode);
    return (leftStation?.name || leftCode).localeCompare(rightStation?.name || rightCode);
  });
}

function loadFavoriteStations() {
  try {
    const raw = window.localStorage.getItem(FAVORITE_STATIONS_STORAGE_KEY);
    if (!raw) {
      return [];
    }

    return sortStationCodesByName(
      [...new Set(JSON.parse(raw).map((code) => normalizeStationCode(code)).filter(Boolean))]
    );
  } catch {
    return [];
  }
}

const state = {
  currentLines: [],
  favoriteStations: loadFavoriteStations(),
  refreshTimer: null,
  searchIndex: -1,
  searchResults: [],
  selectedLine: null,
  selectedStationCode: appData.selectedStationCode,
  stations: appData.stations,
};

const elements = {
  board: document.getElementById("board"),
  clearFilter: document.getElementById("clear-filter"),
  clock: document.getElementById("clock"),
  favoriteStations: document.getElementById("favorite-stations"),
  favoriteStationsEmpty: document.getElementById("favorite-stations-empty"),
  lineFilters: document.getElementById("line-filters"),
  messages: document.getElementById("messages"),
  refreshState: document.getElementById("refresh-state"),
  refreshTime: document.getElementById("refresh-time"),
  searchInput: document.getElementById("station-search"),
  searchResults: document.getElementById("search-results"),
  stationFavoriteToggle: document.getElementById("station-favorite-toggle"),
  stationTitle: document.getElementById("station-title"),
};

function saveFavoriteStations() {
  window.localStorage.setItem(FAVORITE_STATIONS_STORAGE_KEY, JSON.stringify(state.favoriteStations));
}

function setCookie(name, value) {
  const expires = new Date(Date.now() + 28 * 24 * 60 * 60 * 1000).toUTCString();
  document.cookie = `${name}=${value}; expires=${expires}; path=/`;
}

function normalize(text) {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

function iconPathForLine(line) {
  return line ? `${appData.staticBase}img/rer${line}.svg` : null;
}

function isFavoriteStation(code) {
  const normalizedCode = normalizeStationCode(code);
  return Boolean(normalizedCode && state.favoriteStations.includes(normalizedCode));
}

function toggleFavoriteStation(code) {
  const normalizedCode = normalizeStationCode(code);
  if (!normalizedCode) {
    return;
  }

  if (state.favoriteStations.includes(normalizedCode)) {
    state.favoriteStations = state.favoriteStations.filter((item) => item !== normalizedCode);
  } else {
    state.favoriteStations = sortStationCodesByName([...state.favoriteStations, normalizedCode]);
  }

  saveFavoriteStations();
  renderFavoriteStations();
  renderSearchResults(state.searchResults);
  updateStationFavoriteToggle();
}

function updateStationFavoriteToggle() {
  const station = findStation(state.selectedStationCode);
  if (!station) {
    return;
  }

  const active = isFavoriteStation(station.codes[0]);
  elements.stationFavoriteToggle.className = `favorite-toggle station-favorite-toggle ${active ? "active" : ""}`.trim();
  elements.stationFavoriteToggle.title = active
    ? `Remove ${station.name} from favorites`
    : `Add ${station.name} to favorites`;
  elements.stationFavoriteToggle.setAttribute("aria-label", elements.stationFavoriteToggle.title);
}

function updateClock() {
  elements.clock.textContent = new Date().toLocaleTimeString("fr-FR", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function setRefreshState(text, mode = "ok") {
  elements.refreshState.textContent = text;
  elements.refreshState.className = `status-pill ${mode}`;
}

function renderFavoriteStations() {
  elements.favoriteStations.innerHTML = "";

  state.favoriteStations = sortStationCodesByName(
    state.favoriteStations.filter((code) => Boolean(findStation(code)))
  );

  const favorites = state.favoriteStations.map((code) => findStation(code)).filter(Boolean);
  elements.favoriteStationsEmpty.hidden = favorites.length > 0;

  for (const station of favorites) {
    const row = document.createElement("div");
    row.className = "favorite-station-item";

    const button = document.createElement("button");
    button.type = "button";
    button.className = `favorite-station-button ${state.selectedStationCode === station.codes[0] ? "active" : ""}`;
    button.title = `Open ${station.name}`;

    const label = document.createElement("span");
    label.textContent = station.name;
    button.append(label);

    const meta = document.createElement("span");
    meta.className = "favorite-station-meta";
    meta.textContent = station.codes.join(", ");
    button.append(meta);

    button.addEventListener("click", () => selectStation(station.codes[0]));

    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "favorite-toggle active";
    toggle.textContent = "★";
    toggle.title = `Remove ${station.name} from favorites`;
    toggle.setAttribute("aria-label", toggle.title);
    toggle.addEventListener("click", () => toggleFavoriteStation(station.codes[0]));

    row.append(button, toggle);
    elements.favoriteStations.append(row);
  }
}

function renderLineFilters(lines) {
  state.currentLines = lines || [];
  elements.lineFilters.innerHTML = "";
  elements.clearFilter.hidden = !(state.selectedLine || state.currentLines.length > 1);

  for (const line of state.currentLines) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = `line-button ${state.selectedLine === line ? "active" : ""}`;
    button.title = `Filter departures to line ${line}`;

    const icon = document.createElement("img");
    icon.className = "train-line-icon";
    icon.src = iconPathForLine(line);
    icon.alt = line;
    button.append(icon);

    const label = document.createElement("span");
    label.textContent = line;
    button.append(label);

    button.addEventListener("click", () => {
      state.selectedLine = state.selectedLine === line ? null : line;
      renderLineFilters(state.currentLines);
      refreshBoard(true);
    });

    elements.lineFilters.append(button);
  }
}

function formatRefreshTime(value) {
  if (!value) {
    return "--";
  }
  const date = new Date(value);
  return `Updated ${date.toLocaleTimeString("fr-FR", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  })}`;
}

function renderMessages(messages) {
  elements.messages.innerHTML = "";
  for (const message of messages) {
    const card = document.createElement("div");
    card.className = `message-card ${message.priority || "medium"}`;

    const label = document.createElement("strong");
    label.textContent = (message.priority || "info").toUpperCase();
    card.append(label);

    const content = document.createElement("p");
    content.textContent = message.content;
    card.append(content);

    elements.messages.append(card);
  }
}

function createStopsMarquee(text) {
  const section = document.createElement("div");
  section.className = "train-stops";

  const label = document.createElement("span");
  label.className = "train-stops-label";
  label.textContent = "Stops";
  section.append(label);

  const marquee = document.createElement("div");
  marquee.className = "marquee";

  const track = document.createElement("div");
  track.className = "marquee-track";

  const primary = document.createElement("span");
  primary.textContent = text;
  track.append(primary);

  const shouldScroll = text.includes("•") && text.length > 34 && text !== "Desserte indisponible";
  if (shouldScroll) {
    const secondary = document.createElement("span");
    secondary.textContent = text;
    track.append(secondary);
    track.classList.add("is-scrolling");
  }

  marquee.append(track);
  section.append(marquee);
  return section;
}

function renderDepartureCard(train) {
  const card = document.createElement("article");
  card.className = `train-card ${train.status === "S" ? "cancelled" : ""} ${train.status === "R" ? "delayed" : ""}`;

  const top = document.createElement("div");
  top.className = "train-top";

  const mission = document.createElement("div");
  mission.className = "train-mission";

  if (train.ligne) {
    const icon = document.createElement("img");
    icon.className = "train-line-icon";
    icon.src = iconPathForLine(train.ligne);
    icon.alt = train.ligne;
    mission.append(icon);
  }

  const missionLabel = document.createElement("span");
  missionLabel.textContent = train.mission || train.ligne || "Train";
  mission.append(missionLabel);

  const time = document.createElement("div");
  time.className = `train-time ${train.time.length > 6 ? "small" : ""}`;
  time.textContent = train.time;

  top.append(mission, time);
  card.append(top);

  const destination = document.createElement("h3");
  destination.className = "train-destination";
  destination.textContent = train.destination;
  card.append(destination);

  const meta = document.createElement("p");
  meta.className = "train-meta";
  meta.textContent = `No. ${train.numero}${train.expected_time ? ` • ${new Date(train.expected_time).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}` : ""}`;
  card.append(meta);

  card.append(createStopsMarquee(train.dessertes));

  const bottom = document.createElement("div");
  bottom.className = "train-bottom";

  if (train.retard) {
    const badge = document.createElement("span");
    badge.className = "badge";
    badge.textContent = train.retard;
    bottom.append(badge);
  }

  if (train.platform) {
    const badge = document.createElement("span");
    badge.className = "badge";
    badge.textContent = `Platform ${train.platform}`;
    bottom.append(badge);
  }

  if (train.planned_time && train.expected_time && train.planned_time !== train.expected_time) {
    const badge = document.createElement("span");
    badge.className = "badge";
    badge.textContent = `Planned ${new Date(train.planned_time).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}`;
    bottom.append(badge);
  }

  card.append(bottom);
  return card;
}

function renderBoard(board) {
  const station = findStation(board.from.code) || findStation(state.selectedStationCode);
  elements.stationTitle.textContent = board.from.name;
  document.title = `${board.from.name} | ${APP_NAME}`;
  renderLineFilters(board.from.lines || station?.lines || []);
  renderFavoriteStations();
  updateStationFavoriteToggle();
  renderMessages(board.messages || []);

  elements.board.innerHTML = "";
  for (const train of board.trains) {
    elements.board.append(renderDepartureCard(train));
  }

  if (!board.trains.length) {
    const emptyCard = document.createElement("article");
    emptyCard.className = "train-card";
    emptyCard.innerHTML = `
      <div class="train-top"><div class="train-mission"><span>No departures</span></div></div>
      <h3 class="train-destination">Nothing to show right now</h3>
      <p class="train-meta">The upstream feed returned no upcoming departures for this selection.</p>
    `;
    elements.board.append(emptyCard);
  }

  elements.refreshTime.textContent = formatRefreshTime(board.refreshed_at);
  setRefreshState("Live", "ok");
}

async function fetchBoard() {
  const params = new URLSearchParams({ s: state.selectedStationCode });
  if (state.selectedLine) {
    params.set("line", state.selectedLine);
  }

  const response = await fetch(`${appData.apiDeparturesUrl}?${params.toString()}`, {
    cache: "no-store",
  });

  if (!response.ok) {
    let message = `Request failed (${response.status})`;
    try {
      const body = await response.json();
      if (body.error) {
        message = body.error;
      }
    } catch {
      // Ignore JSON parsing failures.
    }
    throw new Error(message);
  }

  return response.json();
}

function queueRefresh() {
  window.clearTimeout(state.refreshTimer);
  state.refreshTimer = window.setTimeout(() => refreshBoard(false), 15000);
}

async function refreshBoard(resetTimer) {
  if (resetTimer) {
    window.clearTimeout(state.refreshTimer);
  }

  setRefreshState("Refreshing", "ok");
  try {
    const board = await fetchBoard();
    renderBoard(board);
  } catch (error) {
    renderMessages([{ priority: "high", content: error.message }]);
    setRefreshState("Error", "error");
  } finally {
    queueRefresh();
  }
}

function selectStation(stationCode, pushState = true) {
  const station = findStation(stationCode);
  if (!station) {
    return;
  }

  state.selectedStationCode = station.codes[0];
  state.selectedLine = null;
  setCookie("station", state.selectedStationCode);
  elements.searchInput.value = station.name;
  renderSearchResults([]);
  renderFavoriteStations();
  updateStationFavoriteToggle();

  const url = new URL(window.location.href);
  url.searchParams.set("s", state.selectedStationCode);
  if (pushState) {
    window.history.pushState({ stationCode: state.selectedStationCode }, "", url);
  } else {
    window.history.replaceState({ stationCode: state.selectedStationCode }, "", url);
  }

  refreshBoard(true);
}

function stationScore(station, query) {
  const normalizedName = normalize(station.name);
  const normalizedCodes = station.codes.map((code) => code.toLowerCase());
  if (normalizedCodes.includes(query)) return 500;
  if (normalizedName === query) return 450;
  if (normalizedCodes.some((code) => code.startsWith(query))) return 400;
  if (normalizedName.startsWith(query)) return 350;
  if (normalizedName.split(" ").some((part) => part.startsWith(query))) return 250;
  if (normalizedName.includes(query)) return 100;
  return 0;
}

function searchStations(query) {
  const normalized = normalize(query);
  if (!normalized) {
    return [];
  }

  return state.stations
    .map((station) => [stationScore(station, normalized), station])
    .filter(([score]) => score > 0)
    .sort((left, right) => right[0] - left[0] || left[1].name.localeCompare(right[1].name))
    .slice(0, 8)
    .map(([, station]) => station);
}

function renderSearchResults(results = state.searchResults) {
  state.searchResults = results;
  state.searchIndex = results.length ? 0 : -1;
  elements.searchResults.innerHTML = "";

  if (!results.length) {
    elements.searchResults.hidden = true;
    return;
  }

  results.forEach((station, index) => {
    const row = document.createElement("div");
    row.className = "search-result-row";

    const item = document.createElement("button");
    item.type = "button";
    item.className = `search-item ${index === state.searchIndex ? "active" : ""}`;

    const head = document.createElement("div");
    head.className = "search-item-head";

    const title = document.createElement("strong");
    title.textContent = station.name;
    head.append(title);

    const codes = document.createElement("span");
    codes.className = "search-item-codes";
    codes.textContent = station.codes.join(", ");
    head.append(codes);
    item.append(head);

    const lines = document.createElement("div");
    lines.className = "search-item-lines";
    for (const line of station.lines) {
      const icon = document.createElement("img");
      icon.className = "train-line-icon";
      icon.src = iconPathForLine(line);
      icon.alt = line;
      lines.append(icon);
    }
    item.append(lines);

    item.addEventListener("click", () => selectStation(station.codes[0]));

    const favoriteToggle = document.createElement("button");
    favoriteToggle.type = "button";
    favoriteToggle.className = `favorite-toggle ${isFavoriteStation(station.codes[0]) ? "active" : ""}`.trim();
    favoriteToggle.textContent = "★";
    favoriteToggle.title = isFavoriteStation(station.codes[0])
      ? `Remove ${station.name} from favorites`
      : `Add ${station.name} to favorites`;
    favoriteToggle.setAttribute("aria-label", favoriteToggle.title);
    favoriteToggle.addEventListener("click", () => toggleFavoriteStation(station.codes[0]));

    row.append(item, favoriteToggle);
    elements.searchResults.append(row);
  });

  elements.searchResults.hidden = false;
}

function moveSearchSelection(delta) {
  if (!state.searchResults.length) {
    return;
  }
  state.searchIndex = (state.searchIndex + delta + state.searchResults.length) % state.searchResults.length;
  [...elements.searchResults.querySelectorAll(".search-item")].forEach((child, index) => {
    child.classList.toggle("active", index === state.searchIndex);
  });
}

function bindEvents() {
  elements.clearFilter.addEventListener("click", () => {
    state.selectedLine = null;
    renderLineFilters(state.currentLines);
    refreshBoard(true);
  });

  elements.stationFavoriteToggle.addEventListener("click", () => {
    toggleFavoriteStation(state.selectedStationCode);
  });

  elements.searchInput.addEventListener("input", (event) => {
    renderSearchResults(searchStations(event.target.value));
  });

  elements.searchInput.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      moveSearchSelection(1);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      moveSearchSelection(-1);
    } else if (event.key === "Enter" && state.searchResults.length) {
      event.preventDefault();
      selectStation(state.searchResults[state.searchIndex].codes[0]);
    } else if (event.key === "Escape") {
      renderSearchResults([]);
    }
  });

  document.addEventListener("click", (event) => {
    if (!elements.searchResults.contains(event.target) && event.target !== elements.searchInput) {
      renderSearchResults([]);
    }
  });

  window.addEventListener("popstate", (event) => {
    if (event.state?.stationCode) {
      selectStation(event.state.stationCode, false);
    }
  });
}

function init() {
  updateClock();
  window.setInterval(updateClock, 1000);
  bindEvents();
  const station = findStation(state.selectedStationCode);
  if (station) {
    state.currentLines = station.lines;
    renderLineFilters(station.lines);
  }
  renderFavoriteStations();
  updateStationFavoriteToggle();
  window.history.replaceState({ stationCode: state.selectedStationCode }, "", window.location.href);
  refreshBoard(true);
}

init();
