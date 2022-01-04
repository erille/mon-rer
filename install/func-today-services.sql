/* 
 * Cette fonction renvoie la liste de tous les service_id correspondant
 * à des services actifs pour la date donnée en paramètre.
 *
 * Mais attention, cela ne donne qu’une vue incomplète pour les horaires des
 * gares. En réalité, pour une date d donnée, il faudrait examiner
 * l’intervalle [d-1, d+1] pour avoir la vue complète, puis filtrer.
 */

CREATE OR REPLACE FUNCTION today_services(d DATE) RETURNS TABLE(service_id TEXT)
  LANGUAGE SQL
  AS
$$
SELECT COALESCE(c.service_id, cd.service_id) AS service_id
  FROM raw.calendar AS c
       FULL OUTER JOIN (
         SELECT service_id, date, exception_type
           FROM raw.calendar_dates
          WHERE date = d
       ) AS cd
                      ON (c.service_id = cd.service_id)
 WHERE (exception_type IS NOT DISTINCT FROM 1)
    OR (start_date <= d AND d <= end_date
        AND CASE EXTRACT(DOW FROM d)
        WHEN 0 THEN sunday
        WHEN 1 THEN monday
        WHEN 2 THEN tuesday
        WHEN 3 THEN wednesday
        WHEN 4 THEN thursday
        WHEN 5 THEN friday
        WHEN 6 THEN saturday
        END
        AND exception_type IS DISTINCT FROM 2);
$$
ROWS 150;
