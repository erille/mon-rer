CREATE TABLE prim_relations (
  "PdEId" INTEGER,
  "PdEVersion" TEXT,
  "ZdCId" INTEGER,
  "ZdCVersion" TEXT,
  "ZdAId" INTEGER,
  "ZdAVersion" TEXT,
  "ArRId" INTEGER,
  "ArRVersion" TEXT,
  "ArTId" INTEGER,
  "ArTVersion" TEXT
  );

CREATE TABLE prim_zda (
  "ZdAId" INTEGER PRIMARY KEY,
  "ZdAVersion" TEXT,
  "ZdACreated" TIMESTAMP WITH TIME ZONE,
  "ZdAChanged" TIMESTAMP WITH TIME ZONE,
  "ZdAName" TEXT,
  "ZdAXEpsg2154" INTEGER,
  "ZdAYEpsg2154" INTEGER,
  "ZdCId" TEXT,
  "ZdAType" TEXT,
  "ZdAPostalRegion" TEXT,
  "ZdATown" TEXT
  );
