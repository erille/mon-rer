/*
 * Cette fonction renvoie une liste de suggestions d’autocomplétions pour une
 * recherche partielle de nom de gare.
 */

DROP FUNCTION IF EXISTS autocomplete_stations;

CREATE OR REPLACE FUNCTION autocomplete_stations(query TEXT)
  RETURNS TABLE(code TEXT, name TEXT, uic TEXT, lines TEXT[],
                matched_name TEXT,
                score FLOAT, score2 FLOAT)
  LANGUAGE SQL
AS $$
WITH tsq(tsq_name, tsq_code) AS (
  SELECT to_tsquery('fr_unaccent',
                    array_to_string(
                      regexp_split_to_array(unaccent(btrim(query)), E'\\s'),
                      ' <-> ')
                      || ':*'),
         phraseto_tsquery('simple', query)
), results AS (
  SELECT gares.code,
         gares.name,
         gares.uic, array_agg(line) AS lines,
         ts_headline('fr_unaccent', name, tsq_name) AS matched_name,
         ts_rank_cd(to_tsvector('fr_unaccent', unaccent(name)), tsq_name) AS score,
         ts_rank_cd(to_tsvector('simple', code), tsq_code) AS score2
    FROM gares
         JOIN tsq ON (to_tsvector('fr_unaccent', unaccent(name)) @@ tsq.tsq_name
                      OR to_tsvector('simple', code) @@ tsq.tsq_code)
         JOIN gares_lines ON (gares.uic = gares_lines.uic)
   GROUP BY gares.code, tsq_name, tsq_code
)
  SELECT code, name, uic, lines, matched_name, 50*score2+score, 0
  FROM results
  ORDER BY 50*score2+score DESC
  LIMIT 10;
$$
