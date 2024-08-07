\copy prim_relations from 'input/prim/relations.csv' (format csv, header, delimiter ';')

\copy prim_zda ("ZdAId", "ZdAVersion", "ZdACreated", "ZdAChanged", "ZdAName", "ZdAXEpsg2154", "ZdAYEpsg2154", "ZdCId", "ZdAPostalRegion", "ZdATown", "ZdAType") from 'input/prim/zda.csv' (format csv, header, delimiter ';')
