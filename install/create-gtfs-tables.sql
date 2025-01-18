CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.agency (
  agency_id TEXT NOT NULL PRIMARY KEY,
  agency_name TEXT,
  agency_url TEXT,
  agency_timezone TEXT,
  agency_lang TEXT,
  agency_phone TEXT,
  agency_email TEXT,
  agency_fare_url TEXT,
  ticketing_deep_link_id TEXT);

CREATE TABLE IF NOT EXISTS raw.calendar (
  service_id TEXT NOT NULL PRIMARY KEY,
  monday BOOLEAN NOT NULL,
  tuesday BOOLEAN NOT NULL,
  wednesday BOOLEAN NOT NULL,
  thursday BOOLEAN NOT NULL,
  friday BOOLEAN NOT NULL,
  saturday BOOLEAN NOT NULL,
  sunday BOOLEAN NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL);

CREATE TABLE IF NOT EXISTS raw.calendar_dates (
  service_id TEXT NOT NULL,
  date DATE NOT NULL,
  exception_type INTEGER NOT NULL,
  PRIMARY KEY (service_id, date));

CREATE TABLE IF NOT EXISTS raw.routes (
  route_id TEXT NOT NULL PRIMARY KEY,
  agency_id TEXT NOT NULL,
  route_short_name TEXT,
  route_long_name TEXT,
  route_desc TEXT,
  route_type INTEGER NOT NULL,
  route_url TEXT,
  route_color TEXT,
  route_text_color TEXT,
  route_sort_order INTEGER);

CREATE TABLE IF NOT EXISTS raw.stop_extensions (
  object_id TEXT NOT NULL,
  object_system TEXT NOT NULL,
  object_code TEXT NOT NULL);

CREATE TABLE IF NOT EXISTS raw.stops (
  stop_id TEXT NOT NULL PRIMARY KEY,
  stop_code TEXT,
  stop_name TEXT NOT NULL,
  stop_desc TEXT,
  stop_lon DOUBLE PRECISION,
  stop_lat DOUBLE PRECISION,
  zone_id TEXT,
  stop_url TEXT,
  location_type INTEGER,
  parent_station TEXT,
  stop_timezone TEXT,
  wheelchair_boarding INTEGER,
  level_id TEXT,
  platform_code TEXT);

CREATE TABLE IF NOT EXISTS raw.stop_times (
  trip_id TEXT NOT NULL,
  arrival_time INTERVAL,
  departure_time INTERVAL,
  start_pickup_drop_off_window TEXT,
  end_pickup_drop_off_window TEXT,
  stop_id TEXT NOT NULL,
  stop_sequence INTEGER NOT NULL,
  pickup_type INTEGER,
  drop_off_type INTEGER,
  local_zone_id TEXT,
  stop_headsign TEXT,
  timepoint INTEGER,
  pickup_booking_rule_id TEXT,
  drop_off_booking_rule_id TEXT,
  PRIMARY KEY (trip_id, stop_sequence));

CREATE TABLE IF NOT EXISTS raw.transfers (
  from_stop_id TEXT NOT NULL,
  to_stop_id TEXT NOT NULL,
  transfer_type INTEGER NOT NULL,
  min_transfer_time INTEGER NOT NULL,
  PRIMARY KEY (from_stop_id, to_stop_id));

CREATE TABLE IF NOT EXISTS raw.trips (
  route_id TEXT NOT NULL,
  service_id TEXT NOT NULL,
  trip_id TEXT NOT NULL PRIMARY KEY,
  trip_headsign TEXT,
  trip_short_name TEXT,
  direction_id INTEGER,
  block_id TEXT,
  shape_id TEXT,
  wheelchair_accessible INTEGER,
  bikes_allowed INTEGER);
