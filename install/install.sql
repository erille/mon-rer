/* Utilisé pour l’installation. */
/* Attention : À utiliser dans une transaction ! */

CREATE EXTENSION unaccent;

\i install/create-gtfs-tables.sql
\i install/create-prim-tables.sql
\i install/create-rer-web-tables.sql
\i install/create-rer-web-views.sql
\i install/create-cache-tables.sql
\i install/create-stats-tables.sql
\i install/func-basic-functions.sql
\i install/func-train-direction.sql
\i install/func-today-services.sql
\i install/func-autocomplete-stations.sql
\i install/func-find-station-by-key.sql
\i install/func-next-scheduled-trains.sql
\i install/func-schedule-info-for-trains.sql

\i install/import-all-data.sql
