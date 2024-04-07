/*
 * ATTENTION : Les fonctions définies dans ce fichier doivent UNIQUEMENT
 * être IMMUTABLE (et être déclarées comme telles). En d’autres termes : elles
 * ne doivent effectuer AUCUN accès aux tables de la base de données, même
 * juste en lecture. Certaines fonctions définies ici servent en effet pour
 * des contraintes d’intégrité.
 */

/*
 * Étant donné un nom de train extrait de la base de données et un numéro
 * de train, si ce numéro est dans le style RATP, alors renvoie les quatre
 * premiers caractères ; sinon, renvoie le nom original.
 */
CREATE OR REPLACE FUNCTION override_train_name_from_ratp(
  orig_train_name TEXT, train_number TEXT)
  RETURNS TEXT
  LANGUAGE SQL
AS $$
  SELECT CASE
         WHEN train_number ~ '^[A-Z]{4}[0-9]{2}$'
         THEN substring(train_number FOR 4)
         ELSE orig_train_name
         END;
$$
IMMUTABLE;
