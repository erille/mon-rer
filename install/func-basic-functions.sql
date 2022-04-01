/*
 * ATTENTION : Les fonctions définies dans ce fichier doivent UNIQUEMENT
 * être IMMUTABLE (et être déclarées comme telles). En d’autres termes : elles
 * ne doivent effectuer AUCUN accès aux tables de la base de données, même
 * juste en lecture. Certaines fonctions définies ici servent en effet pour
 * des contraintes d’intégrité.
 */

/*
 * Ces fonctions permettent de calculer la clef de contrôle pour un code UIC.
 * C'est une formule de Luhn appliquée sur les chiffres du code UIC à partir
 * du troisième.
 */

CREATE OR REPLACE FUNCTION check_digit(digit_string TEXT)
  RETURNS INTEGER
  LANGUAGE SQL
AS $$
  WITH weighted_digits AS (
    SELECT 2 - (row_number() OVER () % 2) AS weight,
           digit::int
      FROM regexp_split_to_table(reverse(digit_string), '') AS digits(digit)
  ), coefficients(c) AS (
    SELECT CASE
           WHEN weight * digit >= 10 THEN 1 + ((weight * digit) % 10)
           ELSE weight * digit
           END
      FROM weighted_digits
  )
  SELECT (10 - (SUM(c) % 10)) % 10 AS check_digit
  FROM coefficients;
$$
IMMUTABLE;

CREATE OR REPLACE FUNCTION uic8_is_valid(uic8 TEXT)
  RETURNS BOOLEAN
  LANGUAGE SQL
AS $$
  SELECT (uic8 ~ '^[0-9]{8}$'
          AND check_digit(SUBSTRING(uic8 FROM 3)) = 0);
$$
IMMUTABLE;

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
