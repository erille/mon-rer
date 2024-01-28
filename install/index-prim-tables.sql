/*
 * NOTE: Pour chaque nouvel index ou nouvelle contrainte ajoutée ici,
 * le symétrique doit être ajouté dans le fichier deindex-prim-tables.sql.
 */

CREATE INDEX "idx_prim_relations_arrid_zdaid"
  ON "prim_relations" (('STIF:StopPoint:Q:' || "ArRId" || ':'), "ZdAId");
