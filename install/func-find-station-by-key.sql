/* 
 * Cette fonction recherche une gare par un code UIC ou un code TR3.
 * Si key = 'uic', alors la recherche se fait par code UIC.
 * Si key = 'code', alors la recherche se fait par code TR3.
 */

CREATE OR REPLACE FUNCTION find_station_by_key(key TEXT, value TEXT)
  RETURNS TABLE (code TEXT, uic TEXT, name TEXT, lines TEXT[],
                 transilien_api_search_key TEXT)
  LANGUAGE SQL
AS $$
WITH stations_by_key(key, value) AS (
  VALUES (find_station_by_key.key, find_station_by_key.value)
), pa_search_keys AS (
  SELECT sc.pa_id,
         sc.uic,
         v.uic8 AS transilien_api_search_key
    FROM valid_transilien_api_uics AS v
         JOIN station_codes AS sc ON (sc.uic = SUBSTRING(v.uic8 FOR 7))
), station_lines_agg AS (
  SELECT pa_id, array_agg(line ORDER BY line) AS lines
    FROM station_lines
   GROUP BY pa_id
), station_by_codes AS (
  SELECT stations_by_key.key,
         stations_by_key.value,
         sc.code,
         sc.uic,
         sn.name,
         COALESCE(sl.lines, ARRAY[]::TEXT[]) AS lines,
         COALESCE(preferred_keys.transilien_api_search_key,
                  fallback_keys.transilien_api_search_key)
           AS transilien_api_search_key
    FROM stations_by_key
         JOIN station_codes AS sc
             ON (stations_by_key.value =
                 CASE stations_by_key.key
                   WHEN 'uic' THEN sc.uic
                   WHEN 'code' THEN sc.code
                 END)
         LEFT JOIN pa_search_keys AS preferred_keys
             ON (sc.uic = preferred_keys.uic)
         LEFT JOIN pa_search_keys AS fallback_keys
             ON (sc.pa_id = fallback_keys.pa_id
                 AND preferred_keys.uic IS NULL
                 AND fallback_keys.uic IS DISTINCT FROM preferred_keys.uic)
         JOIN station_names AS sn ON (sc.pa_id = sn.pa_id)
         LEFT JOIN station_lines_agg AS sl ON (sl.pa_id = sn.pa_id)
)
SELECT code, uic, name, lines, transilien_api_search_key
  FROM station_by_codes;
$$
STABLE;
