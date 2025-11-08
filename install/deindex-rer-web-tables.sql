ALTER TABLE metadata
  DROP CONSTRAINT metadata_pkey;

ALTER TABLE station_codes
  DROP CONSTRAINT station_codes_code_check;

ALTER TABLE station_names
  DROP CONSTRAINT station_names_pkey;

ALTER TABLE station_lines
  DROP CONSTRAINT station_lines_pkey;

DROP INDEX "idx_station_codes_pa_id";

DROP INDEX "idx_transco_icar_station_ids";

DROP INDEX "idx_transco_icar_station_ids_2";
