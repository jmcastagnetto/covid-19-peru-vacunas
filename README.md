Datos procesados y aumentados, usando los datos abiertos sobre vacunaciones COVID-19 en Perú: https://www.datosabiertos.gob.pe/dataset/vacunacion

Los datos procesados incluyen:

- Datos acumulados por día y fabricante
- Datos acumulados por semana epidemiológica, y rango de edades (tres agrupaciones: quintiles, deciles, y los rangos empleados por OWID)


*Notas*

- 2021-05-13: Los datos procesados y aumentados se están ahora separando en múltiples archivos (cada millón de registros), para evitar llegar al límite máximo en tamaño de Github. Los nombres son de la forma `vacunas_covid_aumentada_NNN.csv.gz`, donde `NNN` es el número de secuencia del archivo.
- 2021-08-30: Por cuarta vez desde que comenzaron a publicar los datos abiertos de vacunas, el URL canónico de los datos ha sido cambiado sin anuncio previo. El código de proceso se ha modificado para tomar esto en cuenta.
- 2021-09-01: He re-escrito todo el flujo del proceso de datos, incluyendo la opción de cargar todo a una BD local para consistencia.
- 2021-09-09: Los datos de la fuente oficial de los últimos tenían inconsitencias, hoy ya parecen estar bien, pero ha cambiado la estructura de los mismos: se ha agregado el campo de edad (que antes se obtenía de la tabla de personas).
