/* 
 * Cette fonction recherche une gare par un code UIC ou un code TR3.
 * Si key = 'uic', alors la recherche se fait par code UIC.
 * Si key = 'code', alors la recherche se fait par code TR3.
 */

DROP FUNCTION IF EXISTS find_station_by_key(text, text);

CREATE OR REPLACE FUNCTION find_station_by_key(key TEXT, value TEXT)
  RETURNS TABLE (code TEXT, uic TEXT, name TEXT, lines TEXT[],
                 transilien_api_search_key TEXT,
                 prim_api_search_key TEXT)
  LANGUAGE SQL
AS $$
WITH stations_by_key(key, value) AS (
  VALUES (find_station_by_key.key, find_station_by_key.value)
), station_search_keys AS (
  SELECT station_codes.pa_id,
         station_codes.code,
         station_codes.uic,
         prim_relations."ZdAId" AS zda_id,
         prim_relations."ArRId" AS arr_id,
         valid_transilien_api_uics.uic8 AS transilien_key,
         'STIF:StopArea:SP:' || prim_relations."ZdAId" || ':' AS prim_key_zda,
         'STIF:StopPoint:Q:' || prim_relations."ArRId" || ':' AS prim_key_arr
    FROM station_codes
         LEFT JOIN valid_transilien_api_uics
             ON (station_codes.uic = SUBSTRING(valid_transilien_api_uics.uic8 FOR 7))
         JOIN transco_icar
             ON (station_codes.pa_id = transco_icar.pa_id
                 AND transco_icar.zde_mode = 'TRAIN')
         JOIN prim_zda
             ON (transco_icar.zdlr_id::INTEGER = prim_zda."ZdAId"
                 AND prim_zda."ZdAType" = 'railStation')
         JOIN prim_relations
             ON (prim_relations."ZdAId" = prim_zda."ZdAId")
), station_lines_agg AS (
  SELECT pa_id, array_agg(line ORDER BY line) AS lines
    FROM station_lines
   GROUP BY pa_id
)
SELECT preferred_station_code.code,
       preferred_station_code.uic,
       station_names.name,
       station_lines_agg.lines,
       preferred_station_code.transilien_key AS "transilien_api_search_key",
       found_pa.prim_key_zda AS "prim_api_search_key"
  FROM stations_by_key
         JOIN LATERAL (
           SELECT pa_id, prim_key_zda
             FROM station_search_keys
            WHERE stations_by_key.value =
                  CASE stations_by_key.key
                  WHEN 'uic' THEN uic
                  WHEN 'code' THEN code
                  WHEN 'prim_key_zda' THEN prim_key_zda
                  WHEN 'prim_key_arr' THEN prim_key_arr
                  END
            LIMIT 1) AS found_pa
             ON TRUE
       JOIN LATERAL (
         SELECT code,
                uic,
                v.uic8 AS transilien_key
           FROM station_codes
                LEFT JOIN valid_transilien_api_uics AS v
                    ON (station_codes.uic = SUBSTRING(v.uic8 FOR 7))
          WHERE station_codes.pa_id = found_pa.pa_id
          ORDER BY v.uic8 NULLS LAST
          LIMIT 1
       ) AS preferred_station_code
           ON TRUE
       JOIN station_names
           ON (found_pa.pa_id = station_names.pa_id)
       LEFT JOIN station_lines_agg
           ON (found_pa.pa_id = station_lines_agg.pa_id);
$$
STABLE;
