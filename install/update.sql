/* Utilisé pour la mise à jour. */

BEGIN;

\i install/deindex-gtfs-tables.sql
\i install/deindex-rer-web-tables.sql
\i install/clear-gtfs-data.sql
\i install/clear-prim-data.sql
\i install/clear-rer-web-data.sql
\i install/import-gtfs-data.sql
\i install/import-prim-data.sql
\i install/import-rer-web-data.sql
\i install/index-gtfs-tables.sql
\i install/index-rer-web-tables.sql

COMMIT;

\i install/rotate-logs.sql
