/* Utilisé pour la mise à jour. */

BEGIN;

\i install/deindex-gtfs-tables.sql
\i install/deindex-prim-tables.sql
\i install/deindex-rer-web-tables.sql
\i install/clear-gtfs-data.sql
\i install/clear-prim-data.sql
\i install/clear-rer-web-data.sql
\i install/import-all-data.sql

COMMIT;

\i install/rotate-logs.sql

\i install/analyze-tables.sql
