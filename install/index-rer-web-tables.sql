/*
 * NOTE: Pour chaque nouvel index ou nouvelle contrainte ajoutée ici,
 * le symétrique doit être ajouté dans le fichier deindex-rer-web-tables.sql.
 */

ALTER TABLE metadata
  ADD CONSTRAINT metadata_pkey PRIMARY KEY (key);

ALTER TABLE station_codes
  ADD CONSTRAINT station_codes_code_check
      CHECK (code ~ '^[A-Z]{1,3}$' OR code ~ '^N[CD][0-9]$'),
  ADD CONSTRAINT station_codes_uic_check
      CHECK (uic ~ '^87[0-9]{5}$');

ALTER TABLE station_names
  ADD CONSTRAINT station_names_pkey PRIMARY KEY (pa_id);

ALTER TABLE station_lines
  ADD CONSTRAINT station_lines_pkey PRIMARY KEY (pa_id, line);
