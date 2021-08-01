/* Utilisé pour l’installation. */

BEGIN;

\i install/create-gtfs-tables.sql
\i install/create-rer-web-tables.sql
\i install/create-rer-web-views.sql
\i install/create-cache-tables.sql
\i install/import-gtfs-data.sql
\i install/import-rer-web-data.sql
\i install/index-gtfs-tables.sql
\i install/index-rer-web-tables.sql
\i install/func-today-services.sql
\i install/func-autocomplete-stations.sql
\i install/func-find-station-by-key.sql
\i install/func-next-scheduled-trains.sql
\i install/func-schedule-info-for-trains.sql

COMMIT;
