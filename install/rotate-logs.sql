/*
 * Supprimer les statistiques datant de plus de deux semaines.
 */
DELETE FROM stat_events
 WHERE stat_events.time < NOW() - INTERVAL '14 DAYS';

/*
 * Attention, seul un VACUUM FULL peut permettre de récupérer l’espace disque
 * occupé par les entrées de stat_events. On ne le fait pas ici parce que
 * l’opération est lourde et bloque la table, mais il peut être nécessaire de
 * le faire soi-même si on a laissé la table croître davantage que de raison.
 */
