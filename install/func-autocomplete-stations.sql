/*
 * Passe la chaîne de caractères en minuscules et remplace toute suite d'au
 * moins un caractère non alphanumérique par un espace.
 */

CREATE OR REPLACE FUNCTION simplify_phrase(text TEXT)
  RETURNS TEXT
  LANGUAGE SQL
AS $$
  SELECT regexp_replace(lower(unaccent(text)), '\W+', ' ', 'g');
$$
IMMUTABLE;

/*
 * Crée un tsquery permettant de rechercher une suite exacte de mots.
 */

CREATE OR REPLACE FUNCTION unaccent_phraseto_tsquery(query TEXT)
  RETURNS tsquery
  LANGUAGE SQL
AS $$
  SELECT phraseto_tsquery('fr_unaccent', simplify_phrase(query));
$$
IMMUTABLE;

/*
 * Crée un tsquery permettant de rechercher une suite de mots, dont le
 * dernier est un préfixe (par exemple, pour trouver "Saint-Denis" en
 * tapant juste "saint-de").
 */

CREATE OR REPLACE FUNCTION prefix_phraseto_tsquery(query TEXT)
  RETURNS tsquery
  LANGUAGE SQL
AS $$
  WITH tsq(q) AS (
    SELECT NULLIF(unaccent_phraseto_tsquery(query)::text, '')
  )
  SELECT CASE
         WHEN tsq.q IS NULL THEN NULL
         ELSE to_tsquery('fr_unaccent', tsq.q::text || ':*')
         END
  FROM tsq;
$$
IMMUTABLE;

/*
 * Crée un tsvector en supprimant les accents et les autres caractères non
 * alphanumériques, facilitant la recherche et l'indexation.
 */

CREATE OR REPLACE FUNCTION unaccent_to_tsvector(config regconfig, text TEXT)
  RETURNS tsvector
  LANGUAGE SQL
AS $$
  SELECT to_tsvector(config, simplify_phrase(text));
$$
IMMUTABLE;

/*
 * Cette fonction renvoie une liste de suggestions d’autocomplétions pour une
 * recherche partielle de nom ou de code de gare.
 *
 * Les résultats sont, par ordre de préférence décroissante :
 *
 * (a) les correspondances exactes sur le code ou le nom (par exemple, "CL" va
 *     faire monter "Creil" en tout premier car son code est "CL") ;
 * (b) les correspondances partielles au début du code ou du nom (par exemple,
 *     toutes les gares dont le code ou le nom commence par "cl") ;
 * (c) les correspondances survenant partout ailleurs dans le nom en début de
 *     mot (par exemple, toutes les gares dont le nom comporte un mot
 *     commençant par "cl").
 */

DROP FUNCTION IF EXISTS autocomplete_stations;

CREATE OR REPLACE FUNCTION autocomplete_stations(query TEXT)
  RETURNS TABLE(codes TEXT[], name TEXT, lines TEXT[], score FLOAT)
  LANGUAGE SQL
  AS $$
WITH tsq AS (
  SELECT '''<begin>''' <-> unaccent_phraseto_tsquery(query) <-> '''<end>'''
           AS exact,
         '''<begin>''' <-> prefix_phraseto_tsquery(query)
           AS at_start,
         prefix_phraseto_tsquery(query) AS anywhere
), code_matches AS (
  SELECT pa_id,
         MAX(ts_rank_cd(code_tsv, tsq.exact)) AS score_exact,
         MAX(ts_rank_cd(code_tsv, tsq.at_start)) AS score_at_start
    FROM (SELECT pa_id,
                 setweight('<begin>:1'::tsvector
                               || to_tsvector('simple', code)
                               || '<end>:1'::tsvector,
                           'A')
                   AS code_tsv
            FROM station_codes) AS station_codes_tsq
         JOIN tsq ON (code_tsv @@ tsq.anywhere)
   GROUP BY pa_id
), name_matches AS (
  SELECT pa_id,
         ts_rank_cd(name_tsv, tsq.exact) AS score_exact,
         ts_rank_cd(name_tsv, tsq.at_start) AS score_at_start,
         ts_rank_cd(name_tsv, tsq.anywhere) AS score_anywhere
    FROM (SELECT pa_id,
                 '<begin>:1'::tsvector
                   || unaccent_to_tsvector('fr_unaccent', name)
                   || '<end>:1'::tsvector
                   AS name_tsv
            FROM station_names) AS station_names_tsv
         JOIN tsq ON (name_tsv @@ tsq.anywhere)
), ranked_matches AS (
  SELECT pa_id,
         SUM(score_exact) AS score_exact,
         SUM(score_at_start) AS score_at_start,
         SUM(score_anywhere) AS score_anywhere
    FROM (
      SELECT pa_id, score_exact, score_at_start, 0 AS score_anywhere
        FROM code_matches
       UNION ALL
      SELECT pa_id, score_exact, score_at_start, score_anywhere
        FROM name_matches)
           AS scores
   GROUP BY pa_id
)
SELECT codes,
       name,
       lines,
       100 * score_exact + 10 * score_at_start + score_anywhere AS score
  FROM ranked_matches
       JOIN (
         SELECT pa_id, array_agg(code) AS codes
           FROM station_codes
          GROUP BY pa_id)
              AS station_codes
           ON (ranked_matches.pa_id = station_codes.pa_id)
       JOIN (
         SELECT pa_id, array_agg(line ORDER BY line) AS lines
           FROM station_lines
          GROUP BY pa_id)
              AS station_lines
           ON (ranked_matches.pa_id = station_lines.pa_id)
       JOIN station_names ON (ranked_matches.pa_id = station_names.pa_id)
 ORDER BY score_exact DESC,
          score_at_start DESC,
          score_anywhere DESC
 LIMIT 10;
$$
ROWS 10
STABLE;
