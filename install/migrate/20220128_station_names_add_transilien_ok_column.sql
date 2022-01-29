BEGIN;

ALTER TABLE station_names
  ADD COLUMN IF NOT EXISTS transilien_api_ok BOOL NOT NULL DEFAULT TRUE;

DROP FUNCTION find_station_by_key(TEXT, TEXT);

\ir ../func-find-station-by-key.sql

ALTER TABLE station_names
  ALTER COLUMN transilien_api_ok DROP DEFAULT;

COMMIT;
