ALTER TABLE metadata
  DROP CONSTRAINT metadata_pkey;

DROP INDEX IF EXISTS "gares_idx_uic";

DROP INDEX IF EXISTS "gares_idx_name";

ALTER TABLE gares_lines
  DROP CONSTRAINT IF EXISTS gares_lines_fk_gares,
  DROP CONSTRAINT IF EXISTS gares_lines_pkey;

ALTER TABLE gares
  DROP CONSTRAINT IF EXISTS gares_code_check,
  DROP CONSTRAINT IF EXISTS gares_uic_check,
  DROP CONSTRAINT IF EXISTS gares_uic_unique,
  DROP CONSTRAINT IF EXISTS gares_pkey;
                                                        
