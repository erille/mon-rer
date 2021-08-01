/*
 * Cette fonction retrouve le passage d’un ou plusieurs trains dans une gare
 * donnée en fonction de son numéro, son horaire temps réel ou théorique et la
 * gare de passage.
 */

-- Exemples de données pour tester :
-- \set station '''EVC'''
-- \set rt 'timestamp with time zone ''2021-07-28 00:01:00'''
-- \set train_numbers 'ARRAY[''155903'', ''150524'', ''155905'', ''155977'', ''155027'', ''129600-129601'']'

DROP FUNCTION IF EXISTS schedule_info_for_trains;

CREATE OR REPLACE FUNCTION schedule_info_for_trains(rt TIMESTAMP WITH TIME ZONE,
                                                    station_code TEXT,
                                                    train_numbers TEXT[])
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
), train_numbers_set AS (
  SELECT unnest(train_numbers) AS train_number
), today_trips AS (
  SELECT dates.date,
         trips.trip_id,
         trips.trip_headsign,
         trips.trip_short_name,
         trips.route_id
    FROM dates
         JOIN LATERAL today_services(dates.date) AS services ON TRUE
         JOIN raw.trips ON (trips.service_id = services.service_id)
         JOIN train_numbers_set
             ON (train_numbers_set.train_number = trips.trip_short_name)
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
         JOIN stop_id_station_codes ON (stops.stop_id = stop_id_station_codes.stop_id)
   WHERE stop_id_station_codes.code = station_code
     AND rt - interval '6 hours' <= today_trips.date + times.due_time
     AND today_trips.date + times.due_time <= rt + interval '6 hours'
), info AS (
  SELECT timetable.line,
         timetable.train_name,
         timetable.train_number,
         timetable.due_time,
         COALESCE(next_stops.next_stops, ARRAY[]::TEXT[])
           AS next_stops,
         COALESCE(next_stops.destination, E'\x1F0\x1FTrain terminus')
           AS destination
    FROM timetable
         LEFT JOIN LATERAL (
           SELECT DISTINCT array_agg(E'\x1F0\x1F' || stop_id_station_names.name)
                             OVER w
                             AS next_stops,
                           last_value(E'\x1F0\x1F' || stop_id_station_names.name)
                             OVER w
                             AS destination
             FROM raw.stop_times
                  LEFT JOIN stop_id_station_names
                      ON (stop_times.stop_id = stop_id_station_names.stop_id)
            WHERE stop_times.trip_id = timetable.trip_id
              AND stop_times.stop_sequence > timetable.stop_sequence
           WINDOW w AS (ORDER BY stop_sequence
                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
            LIMIT 1
         ) AS next_stops ON TRUE
)
SELECT info.line,
       info.train_name,
       train_numbers_set.train_number,
       info.due_time,
       info.next_stops,
       info.destination
  FROM train_numbers_set
       LEFT JOIN info ON (train_numbers_set.train_number = info.train_number)
 ORDER BY array_position(train_numbers, train_numbers_set.train_number);
$$
