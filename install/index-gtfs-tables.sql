/*
 * NOTE: Pour chaque nouvel index ou nouvelle contrainte ajoutée ici,
 * le symétrique doit être ajouté dans le fichier deindex-gtfs-tables.sql.
 */


/*
 * On ne peut pas créer de contrainte de clef étrangère pour raw.trips
 * (service_id) parce que ces service_id peuvent référencer tantôt des entrées
 * dans calendar, tantôt dans calendar_dates ; or un service_id donné peut ne
 * pas apparaître dans l’un ou dans l’autre.
 */

CREATE INDEX "idx_stop_times_stop_id"
  ON raw.stop_times (stop_id, trip_id);
