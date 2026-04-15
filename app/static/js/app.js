const FAVORITE_STATIONS_STORAGE_KEY = "idf-trains.favorite-stations";
const DEFAULT_THEME = "moderne";
const DEFAULT_LANGUAGE = "en";
const LINE_COLORS = {
  A: "#e5412f",
  B: "#5a9ddb",
  C: "#f0c33b",
  D: "#19984f",
  E: "#d25ba6",
  H: "#b07b31",
  J: "#b79b5b",
  K: "#a6aa2a",
  L: "#ffce00",
  N: "#00a7de",
  P: "#8fc73f",
  R: "#ef7d00",
  U: "#cb8f00",
  T4: "#c05f8d",
  T11: "#b56ca9",
  T12: "#d19f12",
  T13: "#7dc8c3",
};

const appData = window.__APP_DATA__;
const appTheme = appData.theme || DEFAULT_THEME;
const appLang = appData.lang || DEFAULT_LANGUAGE;
const appStrings = appData.strings || {};
const appLocale = appStrings.locale || "en-GB";
const appName = appStrings.title || "IDF Trains by Ketah";

function formatString(template, values = {}) {
  return String(template).replace(/\{(\w+)\}/g, (_, key) => values[key] ?? "");
}

function t(key, values = {}) {
  return formatString(appStrings[key] || key, values);
}

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
  clockMain: document.getElementById("clock-main"),
  clockSeconds: document.getElementById("clock-seconds"),
  favoriteStations: document.getElementById("favorite-stations"),
  favoriteStationsEmpty: document.getElementById("favorite-stations-empty"),
  languageLinks: [...document.querySelectorAll("[data-lang-link]")],
  lineFilters: document.getElementById("line-filters"),
  messages: document.getElementById("messages"),
  refreshState: document.getElementById("refresh-state"),
  refreshTime: document.getElementById("refresh-time"),
  searchInput: document.getElementById("station-search"),
  searchResults: document.getElementById("search-results"),
  searchTrigger: document.getElementById("station-search-trigger"),
  stationFavoriteToggle: document.getElementById("station-favorite-toggle"),
  stationTitle: document.getElementById("station-title"),
  themeLinks: [...document.querySelectorAll("[data-theme-link]")],
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

function lineColor(line) {
  return LINE_COLORS[line] || "#1f9a52";
}

function shouldScrollMarquee(text) {
  return text.includes("•") && text.length > 34 && text !== "Desserte indisponible";
}

function parseIsoDate(value) {
  return value ? new Date(value) : null;
}

function formatBoardTime(value) {
  return value
    ? value.toLocaleTimeString(appLocale, {
        hour: "2-digit",
        minute: "2-digit",
      })
    : "--:--";
}

function formatDelayDelta(minutes) {
  if (minutes === 0) {
    return t("on_time");
  }

  const sign = minutes > 0 ? "+" : "-";
  const absolute = Math.abs(minutes);
  const hours = Math.floor(absolute / 60);
  const remainder = absolute % 60;
  if (!hours) {
    return `${sign}${remainder} min`;
  }
  return `${sign}${hours} h ${String(remainder).padStart(2, "0")}`;
}

function standardRowTime(train) {
  if (train.status === "S") {
    return train.time;
  }

  const expected = parseIsoDate(train.expected_time);
  if (expected) {
    return formatBoardTime(expected);
  }

  return train.time;
}

function standardRowStatus(train) {
  const expected = parseIsoDate(train.expected_time);
  const planned = parseIsoDate(train.planned_time);

  if (train.status === "S") {
    return t("cancelled");
  }

  if (train.time === "A quai") {
    return t("at_platform");
  }

  if (expected && planned) {
    const minutes = Math.round((expected.getTime() - planned.getTime()) / 60000);
    return formatDelayDelta(minutes);
  }

  if (train.retard === "on time") {
    return t("on_time");
  }

  if (train.retard) {
    return train.retard;
  }

  if (train.status === "R") {
    return t("delayed");
  }

  return t("on_time");
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
    ? t("remove_station_from_favorites", { station: station.name })
    : t("add_station_to_favorites", { station: station.name });
  elements.stationFavoriteToggle.setAttribute("aria-label", elements.stationFavoriteToggle.title);
}

function updateThemeLinks() {
  for (const link of elements.themeLinks) {
    const nextTheme = link.dataset.themeLink;
    const url = new URL(window.location.href);
    url.searchParams.set("s", state.selectedStationCode);
    url.searchParams.set("theme", nextTheme);
    url.searchParams.set("lang", appLang);
    link.href = url.toString();
    link.classList.toggle("is-active", nextTheme === appTheme);
  }
}

function updateLanguageLinks() {
  for (const link of elements.languageLinks) {
    const nextLanguage = link.dataset.langLink;
    const url = new URL(window.location.href);
    url.searchParams.set("s", state.selectedStationCode);
    url.searchParams.set("theme", appTheme);
    url.searchParams.set("lang", nextLanguage);
    link.href = url.toString();
    link.classList.toggle("is-active", nextLanguage === appLang);
  }
}

function updateClock() {
  const now = new Date();
  if (elements.clock) {
    elements.clock.textContent = now.toLocaleTimeString(appLocale, {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
  }
  if (elements.clockMain) {
    elements.clockMain.textContent = now.toLocaleTimeString(appLocale, {
      hour: "2-digit",
      minute: "2-digit",
    });
  }
  if (elements.clockSeconds) {
    elements.clockSeconds.textContent = now.toLocaleTimeString(appLocale, {
      second: "2-digit",
    });
  }
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
    button.title = t("open_station", { station: station.name });

    const label = document.createElement("span");
    label.textContent = station.name;
    button.append(label);

    if (appTheme !== "standard") {
      const meta = document.createElement("span");
      meta.className = "favorite-station-meta";
      meta.textContent = station.codes.join(", ");
      button.append(meta);
    }

    button.addEventListener("click", () => selectStation(station.codes[0]));

    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "favorite-toggle active";
    toggle.textContent = "★";
    toggle.title = t("remove_station_from_favorites", { station: station.name });
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
    button.title = t("filter_line", { line });

    if (appTheme === "standard") {
      const badge = document.createElement("span");
      badge.className = "standard-line-badge";
      badge.style.setProperty("--line-color", lineColor(line));
      badge.textContent = line;
      button.append(badge);
    } else {
      const icon = document.createElement("img");
      icon.className = "train-line-icon";
      icon.src = iconPathForLine(line);
      icon.alt = line;
      button.append(icon);

      const label = document.createElement("span");
      label.textContent = line;
      button.append(label);
    }

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
  return `${t("updated_prefix")} ${date.toLocaleTimeString(appLocale, {
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
    label.textContent = t(`priority_${message.priority || "info"}`).toUpperCase();
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
  label.textContent = t("stops");
  section.append(label);

  const marquee = document.createElement("div");
  marquee.className = "marquee";

  const track = document.createElement("div");
  track.className = "marquee-track";

  const primary = document.createElement("span");
  primary.textContent = text;
  track.append(primary);

  if (shouldScrollMarquee(text)) {
    const secondary = document.createElement("span");
    secondary.textContent = text;
    track.append(secondary);
    track.classList.add("is-scrolling");
  }

  marquee.append(track);
  section.append(marquee);
  return section;
}

function createStandardStopsMarquee(text) {
  const section = document.createElement("div");
  section.className = "station-row-stops";

  const marquee = document.createElement("div");
  marquee.className = "station-row-marquee";

  const track = document.createElement("div");
  track.className = "station-row-marquee-track";

  const primary = document.createElement("span");
  primary.textContent = text;
  track.append(primary);

  if (shouldScrollMarquee(text)) {
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
  missionLabel.textContent = train.mission || train.ligne || t("train");
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
  meta.textContent = `${t("train_number_prefix")} ${train.numero}${train.expected_time ? ` • ${new Date(train.expected_time).toLocaleTimeString(appLocale, { hour: "2-digit", minute: "2-digit" })}` : ""}`;
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
    badge.textContent = `${t("platform")} ${train.platform}`;
    bottom.append(badge);
  }

  if (train.planned_time && train.expected_time && train.planned_time !== train.expected_time) {
    const badge = document.createElement("span");
    badge.className = "badge";
    badge.textContent = `${t("planned")} ${new Date(train.planned_time).toLocaleTimeString(appLocale, { hour: "2-digit", minute: "2-digit" })}`;
    bottom.append(badge);
  }

  card.append(bottom);
  return card;
}

function renderDepartureRow(train, index) {
  const row = document.createElement("article");
  row.className = `station-row ${index % 2 === 0 ? "tone-a" : "tone-b"} ${train.status === "S" ? "cancelled" : ""} ${train.status === "R" ? "delayed" : ""}`.trim();
  const displayTime = standardRowTime(train);

  const mission = document.createElement("div");
  mission.className = "station-row-mission";

  const missionCode = document.createElement("span");
  missionCode.className = "station-row-mission-code";
  missionCode.textContent = train.mission || train.ligne || t("train");
  mission.append(missionCode);

  const status = document.createElement("span");
  status.className = "station-row-status";
  status.textContent = standardRowStatus(train);
  mission.append(status);

  const time = document.createElement("div");
  time.className = `station-row-time ${displayTime.length > 6 ? "small" : ""}`;
  time.textContent = displayTime;

  const line = document.createElement("div");
  line.className = "station-row-line";
  if (train.ligne) {
    const badge = document.createElement("span");
    badge.className = "standard-line-badge";
    badge.style.setProperty("--line-color", lineColor(train.ligne));
    badge.textContent = train.ligne;
    line.append(badge);
  }

  const main = document.createElement("div");
  main.className = "station-row-main";

  const destination = document.createElement("h3");
  destination.className = "station-row-destination";
  destination.textContent = train.destination;
  main.append(destination);
  main.append(createStandardStopsMarquee(train.dessertes));

  const platform = document.createElement("div");
  platform.className = "station-row-platform";
  platform.textContent = train.platform || "·";
  platform.title = train.platform ? `${t("platform")} ${train.platform}` : t("platform_unavailable");

  row.append(mission, time, line, main, platform);
  return row;
}

function renderEmptyState() {
  if (appTheme === "standard") {
    const emptyRow = document.createElement("article");
    emptyRow.className = "station-row station-row-empty";
    emptyRow.innerHTML = `
      <div class="station-row-empty-copy">
        <strong>${t("no_departures")}</strong>
        <span>${t("empty_board_message")}</span>
      </div>
    `;
    return emptyRow;
  }

  const emptyCard = document.createElement("article");
  emptyCard.className = "train-card";
  emptyCard.innerHTML = `
    <div class="train-top"><div class="train-mission"><span>${t("no_departures")}</span></div></div>
    <h3 class="train-destination">${t("nothing_to_show")}</h3>
    <p class="train-meta">${t("empty_board_message")}</p>
  `;
  return emptyCard;
}

function renderBoard(board) {
  const station = findStation(board.from.code) || findStation(state.selectedStationCode);
  if (elements.stationTitle) {
    elements.stationTitle.textContent = board.from.name;
  }
  if (elements.searchInput && document.activeElement !== elements.searchInput) {
    elements.searchInput.value = board.from.name;
  }
  document.title = `${board.from.name} | ${appName}`;
  renderLineFilters(board.from.lines || station?.lines || []);
  renderFavoriteStations();
  updateStationFavoriteToggle();
  renderMessages(board.messages || []);

  elements.board.innerHTML = "";
  const renderer = appTheme === "standard" ? renderDepartureRow : renderDepartureCard;
  for (const [index, train] of board.trains.entries()) {
    elements.board.append(renderer(train, index));
  }

  if (!board.trains.length) {
    elements.board.append(renderEmptyState());
  }

  elements.refreshTime.textContent = formatRefreshTime(board.refreshed_at);
  setRefreshState(t("live"), "ok");
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
    let message = t("request_failed", { status: response.status });
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

  setRefreshState(t("refreshing"), "ok");
  try {
    const board = await fetchBoard();
    renderBoard(board);
  } catch (error) {
    renderMessages([{ priority: "high", content: error.message }]);
    setRefreshState(t("error"), "error");
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

  updateLanguageLinks();
  updateThemeLinks();
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
      ? t("remove_station_from_favorites", { station: station.name })
      : t("add_station_to_favorites", { station: station.name });
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

  if (elements.searchTrigger) {
    elements.searchTrigger.addEventListener("click", () => {
      elements.searchInput.focus();
      elements.searchInput.select();
    });
  }

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
  updateLanguageLinks();
  updateThemeLinks();
  refreshBoard(true);
}

init();
