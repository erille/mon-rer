/*
 * Cette vue permet de passer d’un code UIC à un stop_id du GTFS en utilisant
 * la table de transcodage fournie par la SNCF.
 */

CREATE OR REPLACE VIEW uic_stop_id AS (
  WITH ids AS (
    SELECT DISTINCT uic7,
                    'IDFM:monomodalStopPlace:' || zdlr_id AS stop_id_zdlr,
                    'IDFM:' || lda_id AS stop_id_lda
      FROM transco_icar
     WHERE uic7 IS NOT NULL
       AND zde_mode = 'TRAIN'
  )
  SELECT uic7, stop_id_zdlr AS stop_id
    FROM ids
   UNION SELECT uic7, stop_id_lda
           FROM ids
);
