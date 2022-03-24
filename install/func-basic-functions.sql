/*
 * Étant donné deux gares consécutives sur une ligne donnée, cette fonction renvoie
 * « I » si cela correspond à un parcours dans le sens impair et « P » s’il s’agit
 * d’un parcours dans le sens pair.
 */

DROP FUNCTION IF EXISTS train_direction;

CREATE OR REPLACE FUNCTION train_direction(
  line TEXT, this_pa_id INTEGER, next_pa_id INTEGER)
  RETURNS TEXT
  LANGUAGE SQL
AS $$
  SELECT CASE
         WHEN (station_lines_2.line_index > station_lines.line_index
               AND station_lines.increasing_index_is_outbound)
           OR (station_lines_2.line_index < station_lines.line_index
               AND NOT station_lines.increasing_index_is_outbound)
           THEN 'I'
         WHEN (station_lines_2.line_index < station_lines.line_index
               AND station_lines.increasing_index_is_outbound)
           OR (station_lines_2.line_index > station_lines.line_index
               AND NOT station_lines.increasing_index_is_outbound)
           THEN 'P'
         END
          AS direction
    FROM station_lines
         JOIN station_lines AS station_lines_2
             ON (station_lines_2.pa_id = next_pa_id
                 AND station_lines_2.line = station_lines.line)
   WHERE station_lines.pa_id = this_pa_id
     AND station_lines.line = train_direction.line
$$;

/*
 * Étant donné un numéro de train de la ligne C ou D de la forme 123456-123457
 * (numéro pair d’abord, impair ensuite), renvoie le premier numéro pair si
 * direction est « P » et le second si direction vaut « I ». Dans tous les
 * autres cas, renvoie le numéro de train d’origine.
 */

DROP FUNCTION IF EXISTS train_number_from_direction;

CREATE OR REPLACE FUNCTION train_number_from_direction(
  line TEXT, train_number TEXT, direction TEXT)
  RETURNS TEXT
  LANGUAGE SQL
AS $$
  SELECT CASE
         WHEN (line = 'C' OR line = 'D')
           AND train_number ~ '^([0-9]{5})[02468]-\1[13579]$'
         THEN
           CASE direction
           WHEN 'P' THEN substring(train_number FOR 6)
           WHEN 'I' THEN substring(train_number FROM 8)
           ELSE train_number
           END
         ELSE train_number
         END
$$;
