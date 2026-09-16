# Migraciones — PostgreSQL

SQL plano, numerado, aplicado en orden ([ADR 0010](../../../docs/adr/0010-migraciones-sql-planas.md)).

- El nombre es `NNNN_nombre.sql`. Cualquier otro archivo hace fallar el arranque.
- **Una migración aplicada nunca se edita.** Se corrige con una nueva. El
  ejecutor guarda el hash de lo que aplicó; si el archivo cambia, no arranca.
- **Solo hacia adelante.** No hay `down`: revertir es restaurar el respaldo.
- El número siempre sube. Una migración nueva con número menor al último
  aplicado se rechaza, porque rompería la convergencia del esquema.
- Este SQL no se comparte con el otro motor. Los dialectos difieren.
