BEGIN;

ALTER TABLE station_names
  DROP COLUMN IF EXISTS transilien_api_ok;

DROP FUNCTION find_station_by_key(TEXT, TEXT);

CREATE TABLE IF NOT EXISTS valid_transilien_api_uics (
  uic8 TEXT);

\copy valid_transilien_api_uics from 'install/valid_transilien_api_uics.csv' (format csv, header)

\ir ../func-basic-functions.sql

ALTER TABLE valid_transilien_api_uics
  ADD CONSTRAINT valid_transilien_api_uics_pkey PRIMARY KEY (uic8),
  ADD CONSTRAINT valid_transilien_api_uics_uic8_check
      CHECK (uic8_is_valid(uic8));

\ir ../func-find-station-by-key.sql

COMMIT;
