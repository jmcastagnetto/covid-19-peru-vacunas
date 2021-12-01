Datos procesados y aumentados, usando los datos abiertos sobre vacunaciones COVID-19 en Perú: https://www.datosabiertos.gob.pe/dataset/vacunacion

Los datos procesados incluyen:

- Datos acumulados por día y fabricante
- Datos acumulados por semana epidemiológica, y rango de edades (tres agrupaciones: quintiles, deciles, y los rangos empleados por OWID)

Si quieres hacer un clon de este repositorio, cuya historia contiene muchos archivos grandes (blobs), te sugiero que hagas un "blob-less" clone, de manera que sólo descargas lo mas reciente y si lo requieres puedes obtener los anteriores, algo como:

```
$ git clone --filter=blob:none https://github.com/jmcastagnetto/covid-19-peru-vacunas.git
```

Un buen artículo sobre este tema es [Get up to speed with partial clone and shallow clone](https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/)

*Notas*

- 2021-04-30: OWID está usando los datos resumidos de vacunación de este repositorio como fuente para Perú (ref: https://github.com/owid/covid-19-data/commit/52bb05a0a5954983dca347f92d0af95fada1bbd0)
- 2021-05-13: Los datos procesados y aumentados se están ahora separando en múltiples archivos (cada millón de registros), para evitar llegar al límite máximo en tamaño de Github. Los nombres son de la forma `vacunas_covid_aumentada_NNN.csv.gz`, donde `NNN` es el número de secuencia del archivo.
- 2021-08-19: OWID está usando los datos por rango etáreo de este repositorio como fuente para Perú (ref: https://github.com/owid/covid-19-data/commit/2a40909953e4e66687156049f79e88567ab55741)
- 2021-08-30: Por cuarta vez desde que comenzaron a publicar los datos abiertos de vacunas, el URL canónico de los datos ha sido cambiado sin anuncio previo. El código de proceso se ha modificado para tomar esto en cuenta.
- 2021-09-01: He re-escrito todo el flujo del proceso de datos, incluyendo la opción de cargar todo a una BD local para consistencia.
- 2021-09-09: Los datos de la fuente oficial de los últimos tenían inconsitencias, hoy ya parecen estar bien, pero ha cambiado la estructura de los mismos: se ha agregado el campo de edad (que antes se obtenía de la tabla de personas).
- 2021-10-01: A partir de hoy, estoy acumulando otro conjunto de datos, resumiendo el número de vacunados por UBIGEO (a nivel de distrito), fabricante y dosis
- 2021-11-04: El formato de fechas ya no es mas "dd/mm/yyyy" sino "yyyymmdd"
