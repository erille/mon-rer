/* 
 * Cette fonction recherche une gare par un code TR3 ou PRIM.
 * Si key = 'code', alors la recherche se fait par code TR3.
 * Si key = 'prim_key_zda', alors la recherche se fait par identifiant de zone
 * d'arrêt PRIM.
 * Si key = 'prim_key_arr', alors la recherche se fait par identifiant de
 * point d'arrêt PRIM.
 */

DROP FUNCTION IF EXISTS find_station_by_key(text, text);

CREATE OR REPLACE FUNCTION find_station_by_key(key TEXT, value TEXT)
  RETURNS TABLE (code TEXT, name TEXT, lines TEXT[], prim_api_search_key TEXT)
  LANGUAGE SQL
AS $$
WITH input_query(key, value) AS (
  VALUES (find_station_by_key.key, find_station_by_key.value)
), station_search_keys AS (
  SELECT station_codes.pa_id,
         station_codes.code,
         prim_relations."ZdAId" AS zda_id,
         prim_relations."ArRId" AS arr_id,
         'STIF:StopArea:SP:' || prim_relations."ZdAId" || ':' AS prim_key_zda,
         'STIF:StopPoint:Q:' || prim_relations."ArRId" || ':' AS prim_key_arr
    FROM station_codes
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
), found_pa AS (
  SELECT pa_id, code, prim_key_zda
    FROM station_search_keys
   WHERE find_station_by_key.value =
         CASE find_station_by_key.key
         WHEN 'code' THEN code
         WHEN 'prim_key_zda' THEN prim_key_zda
         WHEN 'prim_key_arr' THEN prim_key_arr
         END
   LIMIT 1
)
SELECT found_pa.code,
       station_names.name,
       station_lines_agg.lines,
       found_pa.prim_key_zda AS "prim_api_search_key"
  FROM found_pa
       JOIN station_names
           ON (found_pa.pa_id = station_names.pa_id)
       LEFT JOIN station_lines_agg
           ON (found_pa.pa_id = station_lines_agg.pa_id);
$$
STABLE
ROWS 1;
