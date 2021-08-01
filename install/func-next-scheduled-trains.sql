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
         times.stop_id,
         times.stop_sequence
    FROM today_trips
         JOIN LATERAL (
           SELECT stop_times.trip_id,
                  COALESCE(stop_times.departure_time, stop_times.arrival_time) AS "due_time",
                  stop_times.stop_id,
                  stop_times.stop_sequence
             FROM raw.stop_times
            WHERE stop_times.trip_id = today_trips.trip_id)
                        AS times ON TRUE
         JOIN raw.routes ON (today_trips.route_id = routes.route_id)
         JOIN raw.stops ON (times.stop_id = stops.stop_id)
         JOIN uic_stop_id ON (stops.stop_id = uic_stop_id.stop_id)
         JOIN gares ON (uic_stop_id.uic7 = gares.uic)
   WHERE gares.code = station_code
     AND rt <= today_trips.date + times.due_time
     AND today_trips.date + times.due_time <= rt + interval '6 hours'
)
SELECT timetable.line,
       timetable.train_name,
       timetable.train_number,
       timetable.due_time,
       next_stops.next_stops,
       COALESCE(next_stops.destination, E'\x1F0\x1FTrain terminus') AS destination
  FROM timetable
       LEFT JOIN LATERAL (
         SELECT DISTINCT array_agg(CONCAT(gares.code, E'\x1F', gares.uic, E'\x1F',
                                         gares.name)) OVER w
                             AS next_stops,
                         last_value(CONCAT(gares.code, E'\x1F', gares.uic, E'\x1F',
                                             gares.name)) OVER w
                             AS destination
           FROM raw.stop_times
                LEFT JOIN uic_stop_id ON (stop_times.stop_id = uic_stop_id.stop_id)
                JOIN gares ON (uic_stop_id.uic7 = gares.uic)
          WHERE stop_times.trip_id = timetable.trip_id
            AND stop_times.stop_sequence > timetable.stop_sequence
         WINDOW w AS (ORDER BY stop_sequence
                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
          LIMIT 1
       ) AS next_stops ON TRUE
  ORDER BY due_time
  LIMIT 30;
$$
