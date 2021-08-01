/*
 * NOTE: Pour chaque nouvel index ou nouvelle contrainte ajoutée ici,
 * le symétrique doit être ajouté dans le fichier deindex-rer-web-tables.sql.
 */

ALTER TABLE metadata
  ADD CONSTRAINT metadata_pkey PRIMARY KEY (key);

CREATE INDEX "gares_idx_uic" ON gares (uic);

CREATE INDEX "gares_idx_name" ON gares (name);

ALTER TABLE gares
  ADD CONSTRAINT gares_code_check CHECK (length(code) <= 3),
  ADD CONSTRAINT gares_uic_check CHECK (length(code) <= 7),
  ADD CONSTRAINT gares_uic_unique UNIQUE (uic),
  ADD CONSTRAINT gares_pkey PRIMARY KEY (code);

ALTER TABLE gares_lines
  ADD CONSTRAINT gares_lines_fk_gares FOREIGN KEY (uic) REFERENCES gares (uic),
  ADD CONSTRAINT gares_lines_pkey PRIMARY KEY (uic, line);
