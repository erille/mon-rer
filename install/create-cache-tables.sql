/*
 * Cette table permet de conserver un cache clef/valeur primitif.
 */

CREATE TABLE IF NOT EXISTS cache (
  key TEXT NOT NULL PRIMARY KEY,
  value JSONB,
  preferred_expiry TIMESTAMP WITH TIME ZONE,
  max_expiry TIMESTAMP WITH TIME ZONE,
  CONSTRAINT cache_max_expiry_check
    CHECK (max_expiry >= preferred_expiry));

/*
 * Insère un objet dans le cache.
 *
 * On indique deux durées pour l’expiration : une durée préférée de fraîcheur
 * et une durée maximale. Ainsi, si l’objet n’est plus parfaitement frais mais
 * qu’il l’est encore suffisamment pour ne pas être gênant (un état dit
 * « semi-périmé »), celui-ci peut tout de même être récupéré.
 */

CREATE OR REPLACE PROCEDURE cache_put(
  key TEXT, value JSONB, preferred_expiry INT, max_expiry INT)
  LANGUAGE SQL
AS $$
  INSERT INTO cache (key, value, preferred_expiry, max_expiry)
  VALUES (key,
          value,
          NOW() + preferred_expiry * interval '1 second',
          NOW() + max_expiry * interval '1 second')
  ON CONFLICT (key) DO UPDATE SET
    value = cache_put.value,
    preferred_expiry = NOW() + cache_put.preferred_expiry * interval '1 second',
    max_expiry = NOW() + cache_put.max_expiry * interval '1 second';
$$;

/*
 * Cette fonction renvoie trois résultats.
 * Le première est la valeur stockée en cache (ou NULL si non trouvée).
 * Le deuxième est un booléen indiquant si le résultat a été trouvé dans le cache.
 * Le troisième est un booléen indiquant si le résultat est « semi-périmé ».
 */

CREATE OR REPLACE FUNCTION cache_get(key TEXT)
  RETURNS TABLE (value JSONB, found BOOL, "semi-stale" BOOL)
  LANGUAGE SQL
AS $$
  SELECT value,
         COALESCE(cache_get.key = cache.key, FALSE) AS found,
         (NOW() > cache.preferred_expiry) AS "semi-stale"
  FROM (VALUES(cache_get.key)) AS values(key)
  LEFT JOIN cache ON (values.key = cache.key
                      AND NOW() < cache.max_expiry);
$$
ROWS 1;

/*
 * Cette fonction invalide un élément du cache.
 */

CREATE OR REPLACE PROCEDURE cache_del(key TEXT)
  LANGUAGE SQL
AS $$
  DELETE FROM cache WHERE cache.key = cache_del.key;
$$
