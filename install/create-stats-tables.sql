/*
 * Ces tables sont utilisées comme un journal simplifié, afin de compiler
 * des statistiques sur l’usage d’API d’horaires temps réel.
 */

CREATE TABLE stat_events (
  "time" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "event" TEXT NOT NULL,
  "extra" JSONB);

CREATE INDEX idx_stat_events_time ON stat_events (time);

/*
 * Cette procédure stockée insère un nouvel événement dans la table ci-dessus.
 */

CREATE PROCEDURE stats_add(event TEXT, extra JSONB DEFAULT NULL)
AS $$
  INSERT INTO stat_events(time, event, extra)
  VALUES (CURRENT_TIMESTAMP, event, extra);
$$
LANGUAGE SQL;

/*
 * Cette vue agrège les statistiques minute par minute sous la forme d’objets
 * JSON, dont la clef est le type d’événement et la valeur le nombre
 * d’occurrences. Seules les entrées pour des minutes complètement écoulées
 * sont renvoyées dans cette vue.
 *
 * La colonne « minute » doit être interprétée comme la fin de la période de
 * 60 secondes pendant laquelle les événements ont été comptés. Par exemple,
 * pour une période allant de 0 h inclus à 0 h 1 exclu, la colonne « minute »
 * vaut 0 h 1.
 */

CREATE OR REPLACE VIEW stats_by_minute AS (
  WITH counts AS (
    SELECT date_trunc('minute', time) AS minute, event, count(event)
      FROM stat_events
     WHERE time < date_trunc('minute', CURRENT_TIMESTAMP)
     GROUP BY minute, event
     ORDER BY minute
  )
  SELECT minute + interval '1 minute' AS minute,
         jsonb_object_agg(event, count) AS events
    FROM counts
   GROUP BY minute
   ORDER BY minute
);
