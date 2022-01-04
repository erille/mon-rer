/*
 * Ces vues permettent de passer du « monde GTFS » à mes propres sources de
 * données pour les noms, les trigrammes et les codes UIC des gares.
 */

/* Notre identifiant central est le pa_id. */

CREATE OR REPLACE VIEW stop_id_pa_ids AS (
  WITH ids AS (
    SELECT DISTINCT pa_id,
                    'IDFM:monomodalStopPlace:' || zdlr_id AS stop_id_zdlr,
                    'IDFM:' || lda_id AS stop_id_lda
      FROM transco_icar
     WHERE zde_mode = 'TRAIN'
  )
  SELECT stop_id_zdlr AS stop_id, pa_id
    FROM ids
   UNION SELECT stop_id_lda, pa_id
           FROM ids
);

/* Cette vue fait l’association stop_id GTFS -> nom de gare. */

CREATE OR REPLACE VIEW stop_id_station_names AS (
  SELECT stop_id, name
    FROM stop_id_pa_ids
         JOIN station_names ON (stop_id_pa_ids.pa_id = station_names.pa_id)
);

/* Cette vue fait l’association stop_id GTFS vers codes trigramme et UIC */

CREATE OR REPLACE VIEW stop_id_station_codes AS (
  SELECT stop_id, stop_id_pa_ids.pa_id, code, uic
    FROM stop_id_pa_ids
         JOIN station_codes ON (stop_id_pa_ids.pa_id = station_codes.pa_id)
);
