BEGIN;

DROP TABLE IF EXISTS valid_transilien_api_uics;

DROP VIEW stop_id_station_codes;

ALTER TABLE station_codes DROP COLUMN uic;

DROP FUNCTION IF EXISTS check_digit(TEXT);

DROP FUNCTION IF EXISTS uic8_is_valid(TEXT);

\i install/create-rer-web-views.sql

\i install/func-basic-functions.sql

\i install/func-find-station-by-key.sql

\i install/func-next-scheduled-trains.sql

\i install/func-schedule-info-for-trains.sql

COMMIT;
