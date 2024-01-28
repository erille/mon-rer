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

ALTER TABLE valid_transilien_api_uics
  ADD CONSTRAINT valid_transilien_api_uics_pkey PRIMARY KEY (uic8),
  ADD CONSTRAINT valid_transilien_api_uics_uic8_check
      CHECK (uic8_is_valid(uic8));

CREATE INDEX "idx_station_codes_pa_id" ON "station_codes" (pa_id);

CREATE INDEX "idx_transco_icar_station_ids"
  ON "transco_icar" ((zdlr_id::INTEGER), zde_mode, pa_id, zdlr_id);

CREATE INDEX "idx_valid_transilien_api_uics_uic7"
  ON "valid_transilien_api_uics" ((SUBSTRING("uic8" FROM 1 FOR 7)));
