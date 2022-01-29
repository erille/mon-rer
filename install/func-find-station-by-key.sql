/* 
 * Cette fonction recherche une gare par un code UIC ou un code TR3.
 * Si key = 'uic', alors la recherche se fait par code UIC.
 * Si key = 'code', alors la recherche se fait par code TR3.
 */

CREATE OR REPLACE FUNCTION find_station_by_key(key TEXT, value TEXT)
  RETURNS TABLE (code TEXT, uic TEXT, name TEXT, lines TEXT[],
                 transilien_api_ok BOOL)
  LANGUAGE SQL
AS $$
WITH stations_by_key AS (
  SELECT pa_id,
         'uic' AS key,
         uic AS value
    FROM station_codes
   UNION ALL SELECT pa_id,
                    'code' AS key,
                    code AS value
    FROM station_codes
)
SELECT station_codes.code,
       station_codes.uic,
       station_names.name,
       array_agg(station_lines.line ORDER BY line) AS lines,
       station_names.transilien_api_ok
 FROM stations_by_key
      JOIN station_codes
     ON (CASE
         WHEN stations_by_key.key = 'uic'
           THEN stations_by_key.value = station_codes.uic
         WHEN stations_by_key.key = 'code'
           THEN stations_by_key.value = station_codes.code
         END)
      JOIN station_names ON (stations_by_key.pa_id = station_names.pa_id)
      JOIN station_lines ON (stations_by_key.pa_id = station_lines.pa_id)
  WHERE stations_by_key.key = find_station_by_key.key
    AND stations_by_key.value = find_station_by_key.value
  GROUP BY station_codes.code,
           station_codes.uic,
           station_names.name,
           station_names.transilien_api_ok;
$$
