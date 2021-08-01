/*
 * NOTE : les clefs et index ne sont pas définis ici mais dans
 * index-rer-web-tables.sql.  Ceci afin de permettre de désactiver
 * temporairement les index lors du chargement de données en masse.
 */

CREATE EXTENSION unaccent;

DROP TEXT SEARCH CONFIGURATION IF EXISTS fr_unaccent;

CREATE TEXT SEARCH CONFIGURATION fr_unaccent (COPY = simple);

ALTER TEXT SEARCH CONFIGURATION fr_unaccent
  ALTER MAPPING FOR hword, hword_part, word
WITH unaccent, simple;

CREATE TABLE IF NOT EXISTS metadata (
  key TEXT NOT NULL,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS gares (
  code TEXT,
  uic TEXT NOT NULL,
  name TEXT NOT NULL COLLATE "fr_FR",
  is_transilien BOOL NOT NULL DEFAULT TRUE);

CREATE TABLE IF NOT EXISTS gares_lines (
  uic TEXT NOT NULL,
  line TEXT NOT NULL);

/*
 * La table de transcodage pour faire les conversions entre UIC7, UIC8 et ID
 * d’arrêt du GTFS.
 */
CREATE TABLE IF NOT EXISTS transco_icar (
  transporteur_nom TEXT NOT NULL,
  pa_id INTEGER NOT NULL,
  uic8 TEXT,
  uic7 TEXT,
  pr_id TEXT,
  zde_id INTEGER NOT NULL,
  zde_libelle TEXT NOT NULL,
  zde_type TEXT NOT NULL,
  zde_mode TEXT NOT NULL,
  zdep_id TEXT NOT NULL,
  zdep_nom TEXT NOT NULL,
  zdep_mode TEXT NOT NULL,
  zder_id TEXT NOT NULL,
  zder_nom TEXT NOT NULL,
  zder_mode TEXT NOT NULL,
  zdlr_id TEXT NOT NULL,
  zdlr_nom TEXT NOT NULL,
  lda_id TEXT NOT NULL,
  zde_associee TEXT);
