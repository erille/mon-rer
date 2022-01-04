/*
 * Cette fonction renvoie une liste de suggestions d’autocomplétions pour une
 * recherche partielle de nom de gare.
 */

DROP FUNCTION IF EXISTS autocomplete_stations;

CREATE OR REPLACE FUNCTION prefix_phraseto_tsquery(query TEXT)
  RETURNS tsquery
  LANGUAGE SQL
AS $$
  WITH tsq(q) AS (
    SELECT NULLIF(phraseto_tsquery('fr_unaccent', query)::text, '')
  )
  SELECT CASE
         WHEN tsq.q IS NULL THEN NULL
         ELSE to_tsquery(tsq.q::text || ':*')
         END
  FROM tsq;
$$
IMMUTABLE;

CREATE OR REPLACE FUNCTION autocomplete_stations(query TEXT)
  RETURNS TABLE(codes TEXT[], name TEXT, lines TEXT[],
                matched_name TEXT,
                score FLOAT, score2 FLOAT)
  LANGUAGE SQL
AS $$
WITH tsq(tsq_name, tsq_code) AS (
  SELECT prefix_phraseto_tsquery(query),
         phraseto_tsquery('simple', query)
), results AS (
  SELECT station_codes_lines.codes,
         station_names.name,
         station_codes_lines.lines,
         ts_headline('fr_unaccent', name, tsq_name) AS matched_name,
         ts_rank_cd(to_tsvector('fr_unaccent', unaccent(name)), tsq_name) AS score,
         ts_rank_cd(to_tsvector('simple', array_to_string(station_codes_lines.codes, ' ')), tsq_code) AS score2
    FROM station_names
         JOIN (SELECT station_codes_2.pa_id,
                      station_codes_2.codes,
                      array_agg(station_lines.line ORDER BY station_lines.line)
                        AS lines
                 FROM (SELECT pa_id, array_agg(code) AS codes
                         FROM station_codes
                        GROUP BY station_codes.pa_id)
                        AS station_codes_2
                      JOIN station_lines
                          ON (station_codes_2.pa_id = station_lines.pa_id)
                GROUP BY station_codes_2.pa_id, station_codes_2.codes)
                AS station_codes_lines
                ON (station_names.pa_id = station_codes_lines.pa_id)
         JOIN tsq ON (to_tsvector('fr_unaccent', unaccent(name)) @@ tsq.tsq_name
                      OR to_tsvector('simple', array_to_string(station_codes_lines.codes, ' ')) @@ tsq.tsq_code)
)
  SELECT codes, name, lines, matched_name, 50*score2+score, 0
  FROM results
  ORDER BY 50*score2+score DESC
  LIMIT 10;
$$
STABLE;
