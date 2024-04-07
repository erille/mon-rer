/*
 * Cette requête permet, étant donné un datetime et une gare, d’obtenir les
 * prochains départs théoriques avec la desserte restante. Cette requête a été
 * très fortement optimisée pour rester sous la barre des 20 ms la plupart du
 * temps sans nécessiter de CREATE MATERIALIZED VIEW.
 */

DROP FUNCTION IF EXISTS next_scheduled_trains;

CREATE OR REPLACE FUNCTION next_scheduled_trains(rt TIMESTAMP WITH TIME ZONE,
                                                 station_code TEXT)
  RETURNS TABLE(line TEXT,
                train_name TEXT,
                train_number TEXT,
                due_time TIMESTAMP WITH TIME ZONE,
                next_stops TEXT[],
                destination TEXT)
  LANGUAGE SQL
AS $$
WITH dates(date) AS (
  SELECT (rt - INTERVAL '6 HOURS')::date
   UNION SELECT (rt)::date
   UNION SELECT (rt + INTERVAL '6 HOURS')::date
), today_trips AS (
  SELECT dates.date,
         trips.trip_id,
         trips.trip_headsign,
         trips.trip_short_name,
         trips.route_id
    FROM dates
         JOIN LATERAL today_services(dates.date) AS services ON TRUE
         JOIN raw.trips ON (trips.service_id = services.service_id)
         JOIN raw.routes ON (trips.route_id = routes.route_id)
   WHERE routes.route_type = 2
), timetable AS (
  SELECT today_trips.date,
         routes.route_short_name AS "line",
         times.trip_id,
         today_trips.trip_headsign AS "train_name",
         today_trips.trip_short_name AS "train_number",
         today_trips.date + times.due_time AS "due_time",
         stop_id_station_codes.pa_id AS "stop_pa_id",
         times.stop_id,
         times.stop_sequence
    FROM today_trips
         JOIN LATERAL (
           SELECT stop_times.trip_id,
                  COALESCE(stop_times.departure_time, stop_times.arrival_time) AS "due_time",
                  stop_times.stop_id,
                  stop_times.stop_sequence
             FROM raw.stop_times
            WHERE stop_times.trip_id = today_trips.trip_id
         ) AS times ON TRUE
         JOIN raw.routes ON (today_trips.route_id = routes.route_id)
         JOIN stop_id_station_codes ON (times.stop_id = stop_id_station_codes.stop_id)
   WHERE stop_id_station_codes.code = station_code
     AND rt <= today_trips.date + times.due_time
     AND today_trips.date + times.due_time <= rt + interval '6 hours'
)
SELECT timetable.line,
       override_train_name_from_ratp(
         timetable.train_name,
         timetable.train_number) AS "train_name",
       train_number_from_direction(timetable.line,
                                   timetable.train_number,
                                   extra_info.direction) AS "train_number",
       timetable.due_time,
       extra_info.next_stops,
       extra_info.destination
  FROM timetable
       JOIN LATERAL (
         SELECT DISTINCT array_agg(E'\x1F' || names.name)
                           OVER w
                           AS next_stops,
                         last_value(E'\x1F' || names.name)
                           OVER w
                           AS destination,
                         train_direction(line,
                                         stop_pa_id,
                                         first_value(stop_id_pa_ids.pa_id) OVER w)
                           AS direction
           FROM raw.stop_times
                LEFT JOIN stop_id_pa_ids
                    ON (stop_times.stop_id = stop_id_pa_ids.stop_id)
                LEFT JOIN station_names AS names
                    ON (stop_id_pa_ids.pa_id = names.pa_id)
          WHERE stop_times.trip_id = timetable.trip_id
            AND stop_times.stop_sequence > timetable.stop_sequence
                WINDOW w AS (ORDER BY stop_sequence
                             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
          LIMIT 1
       ) AS extra_info ON TRUE
  ORDER BY due_time
  LIMIT 30;
$$;
