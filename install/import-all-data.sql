/* Utilisé par install.sh (oui, sh) et update.sql. */
/* ATTENTION : À utiliser dans une transaction ! */

\i install/import-gtfs-data.sql
\i install/import-prim-data.sql
\i install/import-rer-web-data.sql
\i install/index-gtfs-tables.sql
\i install/index-prim-tables.sql
\i install/index-rer-web-tables.sql
