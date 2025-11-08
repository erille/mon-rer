CREATE SCHEMA IF NOT EXISTS raw;

/* On ne crée de tables que pour les fichiers de tables GTFS que nous
 * utilisons. */

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
  route_short_name TEXT,
  route_type INTEGER NOT NULL);

CREATE TABLE IF NOT EXISTS raw.stop_times (
  trip_id TEXT NOT NULL,
  arrival_time INTERVAL,
  departure_time INTERVAL,
  stop_id TEXT NOT NULL,
  stop_sequence INTEGER NOT NULL,
  PRIMARY KEY (trip_id, stop_sequence));

CREATE TABLE IF NOT EXISTS raw.trips (
  route_id TEXT NOT NULL,
  service_id TEXT NOT NULL,
  trip_id TEXT NOT NULL PRIMARY KEY,
  trip_headsign TEXT,
  trip_short_name TEXT);
