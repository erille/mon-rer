/*
 * Cette fonction retrouve le passage d’un ou plusieurs trains dans une gare
 * donnée en fonction de son numéro, son horaire temps réel ou théorique et la
 * gare de passage.
 */

-- Exemples de données pour tester :
-- \set station '''EVC'''
-- \set rt 'timestamp with time zone ''2021-07-28 00:01:00'''
-- \set train_numbers 'ARRAY[''155903'', ''150524'', ''155905'', ''155977'', ''155027'', ''129600-129601'']'

DROP FUNCTION IF EXISTS adjacent_train_numbers;

CREATE OR REPLACE FUNCTION adjacent_train_numbers(train_number TEXT)
  RETURNS SETOF TEXT
  LANGUAGE SQL
AS $$
  WITH other_train_number(other_number) AS (
    SELECT
      CASE
      WHEN train_number ~ '^[0-9]+$'
        THEN CASE
      WHEN train_number ~ '[02468]$'
        THEN train_number ||
            '-' ||
        SUBSTRING(train_number FOR 5) ||
        TRANSLATE(SUBSTRING(train_number FROM 6 FOR 1), '02468', '13579')
      WHEN train_number ~ '[13579]$'
        THEN SUBSTRING(train_number FOR 5) ||
        TRANSLATE(SUBSTRING(train_number FROM 6 FOR 1), '13579', '02468') ||
            '-' ||
        train_number
      END
      END
  )
  SELECT train_number
  UNION ALL
  SELECT other_number
  FROM other_train_number
  WHERE other_number IS NOT NULL
$$
IMMUTABLE
ROWS 2;

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
  SELECT row_number,
         train_number.train_number,
         adjacent.adjacent_train_numbers
    FROM unnest(train_numbers) WITH ORDINALITY
           AS train_number(train_number, row_number)
         JOIN LATERAL (
           SELECT array_agg(adjacent_train_number)
             FROM adjacent_train_numbers(train_number.train_number)
                    AS adjacent(adjacent_train_number)
         ) AS adjacent(adjacent_train_numbers) ON TRUE
), today_trips AS (
  SELECT train_numbers_set."row_number",
         dates.date,
         trips.trip_id,
         trips.trip_headsign,
         trips.trip_short_name,
         trips.route_id
    FROM dates,
         today_services(dates.date) AS services
         JOIN raw.trips ON (trips.service_id = services.service_id)
         JOIN (
           SELECT "row_number",
                  adjacent.train_number
             FROM train_numbers_set,
                  unnest(adjacent_train_numbers) AS adjacent(train_number)
         ) AS train_numbers_set
             ON (trips.trip_short_name = train_numbers_set.train_number)
         JOIN raw.routes ON (trips.route_id = routes.route_id)
   WHERE routes.route_type = 2
), timetable AS (
  SELECT today_trips."row_number",
         today_trips.date,
         routes.route_short_name AS "line",
         times.trip_id,
         today_trips.trip_headsign AS "train_name",
         today_trips.trip_short_name AS "train_number",
         today_trips.date + times.due_time AS "due_time",
         stop_id_pa_ids.pa_id AS "stop_pa_id",
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
         JOIN stop_id_pa_ids ON (times.stop_id = stop_id_pa_ids.stop_id)
   WHERE stop_id_pa_ids.pa_id = (SELECT pa_id FROM station_codes WHERE code = station_code)
     AND rt - interval '6 hours' <= today_trips.date + times.due_time
     AND today_trips.date + times.due_time <= rt + interval '6 hours'
), info AS (
  SELECT timetable."row_number",
         timetable.line,
         timetable.train_name,
         timetable.train_number,
         train_direction(line, stop_pa_id, next_stops[1].pa_id) AS direction,
         timetable.due_time,
         (SELECT array_agg(E'\x1F' || unnest.name) FROM unnest(next_stops)) AS next_stops,
         E'\x1F' || next_stops[array_upper(next_stops, 1)].name AS destination
    FROM timetable
         JOIN LATERAL (
           SELECT array_agg(names ORDER BY stop_times.stop_sequence) AS next_stops
             FROM raw.stop_times
                  LEFT JOIN stop_id_pa_ids
                      ON (stop_times.stop_id = stop_id_pa_ids.stop_id)
                  LEFT JOIN station_names AS names
                      ON (stop_id_pa_ids.pa_id = names.pa_id)
            WHERE stop_times.trip_id = timetable.trip_id
              AND stop_times.stop_sequence > timetable.stop_sequence
         ) AS next_stops ON TRUE
)
SELECT info.line,
       info.train_name,
       train_number_from_direction(
         info.line,
         COALESCE(info.train_number, train_numbers_set.train_number),
         info.direction) AS "train_number",
       info.due_time,
       info.next_stops,
       info.destination
  FROM train_numbers_set
  LEFT JOIN info ON (train_numbers_set."row_number" = info."row_number")
  ORDER BY train_numbers_set."row_number"
$$
STABLE;
