/*
 * Ces vues permettent de passer du « monde GTFS » à mes propres sources de
 * données pour les noms, les trigrammes et les codes UIC des gares.
 */

/* Notre identifiant central est le pa_id. */

CREATE OR REPLACE VIEW stop_id_pa_ids AS (
  SELECT 'IDFM:monomodalStopPlace:' || zdlr_id AS stop_id,
         pa_id
    FROM transco_icar
   WHERE zde_mode = 'TRAIN'
   UNION
  SELECT 'IDFM:' || lda_id AS stop_id,
         pa_id
    FROM transco_icar
   WHERE zde_mode = 'TRAIN'
);

/* Cette vue fait l’association stop_id GTFS vers codes TR3. */

CREATE OR REPLACE VIEW stop_id_station_codes AS (
  SELECT stop_id, stop_id_pa_ids.pa_id, code
    FROM stop_id_pa_ids
         JOIN station_codes ON (stop_id_pa_ids.pa_id = station_codes.pa_id)
);
