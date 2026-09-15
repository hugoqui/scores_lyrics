# Constitución del proyecto

Principios que no se negocian. Sirven para **rechazar** decisiones futuras: si
una propuesta contradice uno de estos puntos, la propuesta se cambia o el
principio se modifica aquí de forma explícita y razonada. Nunca en silencio.

## 1. El culto manda

Nada puede interrumpir un servicio en curso. Ni una licencia vencida, ni una
actualización, ni un fallo de sincronización, ni un corte de internet.

Consecuencias concretas:
- El nodo local nunca se actualiza solo cerca de un servicio.
- Una licencia vencida degrada funciones administrativas, jamás la proyección.
- Ningún aviso de cobro, error o estado aparece en la pantalla del templo.

## 2. El servicio dominical funciona sin internet

Proyección, versículos, lista de alabanza, login de músicos y entrega de
partituras en la red local deben funcionar con la conexión caída. Solo el alta
de iglesias, la licencia y la sincronización del catálogo requieren internet.

Todo lo que se necesita el domingo tiene que estar replicado en el nodo local
**antes** del domingo.

## 3. Ninguna iglesia ve datos de otra

El aislamiento se verifica, no se supone. Conocer una URL o un identificador
nunca concede acceso. Una consulta sin filtro de iglesia es un defecto, no un
descuido.

## 4. Ningún módulo se da por terminado sin pruebas

El criterio de terminado de cada módulo incluye sus pruebas unitarias. Sin
ellas, el módulo sigue abierto aunque el código funcione.

## 5. Nunca se borran datos de un músico en silencio

Las partituras descargadas y las anotaciones a mano alzada son trabajo personal
de alguien. Ante cualquier duda en una migración, se conserva y se avisa; nunca
se descarta.

## 6. Toda decisión de arquitectura se registra antes de implementarse

Va en `docs/adr/`, con el porqué y el costo aceptado. Un ADR no se reescribe:
si la decisión cambia, se escribe uno nuevo que sustituye al anterior.

## 7. Ningún secreto vive en el repositorio

Credenciales, claves y tokens salen de variables de entorno. La configuración
falla ruidosamente al arrancar si falta una variable, en vez de recurrir a un
valor por defecto de producción.

## 8. La documentación es la fuente, no el resumen

Se escribe el spec antes que el código. Si el código y el documento discrepan,
lo que está mal es que nadie actualizó el documento al cambiar la decisión.

## 9. Todo lo que ve un usuario está traducido

Español e inglés desde el primer día, en la app de escritorio, la app móvil y
el panel del SaaS. El idioma se toma del dispositivo y se puede cambiar.

Ningún texto visible se escribe directo en el código: sale de un archivo de
traducciones. Añadir un idioma nuevo no debe obligar a tocar la lógica.

No aplica al contenido que carga la iglesia —letras de cantos, anotaciones—,
que va en el idioma en que lo escribieron.
