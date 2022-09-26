# Datos de vacunación en Peru procesados, corregidos y resumidos

[![DOI](https://zenodo.org/badge/342131396.svg)](https://zenodo.org/badge/latestdoi/342131396)
[![License](https://img.shields.io/github/license/jmcastagnetto/covid-19-peru-vacunas)](LICENSE)
[![Data_validation](https://github.com/jmcastagnetto/covid-19-peru-vacunas/actions/workflows/data_validation.yaml/badge.svg)](https://repository.frictionlessdata.io/report?user=jmcastagnetto&repo=covid-19-peru-vacunas&flow=data_validation)

## Fuente

Datos procesados y aumentados, usando los datos abiertos sobre vacunaciones COVID-19 en Perú: https://www.datosabiertos.gob.pe/dataset/vacunacion

~~Desde inicios de Junio del 2022, los datos publicados ya no son "abiertos" en sentido estricto, pues ahora están siendo geo-bloqueados desde cualquier sitio que no corresponda a una dirección de IP de PerúC~~ (esto ha cambiado ~2022-09-17)

**Notas importantes**:

- La primera vacuna (Sinopharm) de la campaña general de vacunación contra el COVID-19 en Perú se puso el 2021-02-09 (el primer lote de vacunas llegó el 2021-02-07), por lo que las fechas anteriores a ese día en los datos abiertos que publica el MINSA, corresponden a un número parcial y comparativamente pequeño de registros de las dosis aplicadas durante los ensayos clínicos que se hicieron en el país, y, posiblemente, de dosis aplicadas a peruanos en el extranjero.

- Para poder distinguir si los registros de fechas posteriores al 2021-02-08 puedan corresponder a vacunaciones que no son parte de la campaña general, se pueden tomar en cuenta las siguientes fechas:

**Fechas de llegada de primeros lotes por fabricante**

| Fabricante | Fecha de llegada del primer lote | Referencia |
| ---------- | ----------- | ---------- |
| Sinopharm (Beijing) | 2021-02-07 | https://andina.pe/agencia/noticia-lote-vacunas-llega-a-los-almacenes-talma-832838.aspx |
| Pfizer/BioNTech | 2021-03-03 | https://elperuano.pe/noticia/116268-primer-lote-de-50000-vacunas-de-pfizer-llegara-manana-al-pais-anuncia-jefe-del-estado |
| Oxford/AstraZeneca | 2021-04-18 | https://www.minsa.gob.pe/newsletter/2021/edicion-64/nota2/index.html |
| Moderna | 2022-03-27 | https://andina.pe/agencia/noticia-covid19-llego-al-peru-lote-mas-12-millones-dosis-de-vacuna-moderna-886436.aspx |

- Adicionalmente, los inicios de cada campaña de vacunación por número de dosis han sido:

| Dosis | Fecha de inicio | Referencia |
| ----- | --------------- | ---------- |
| Primera | 2021-02-09 | https://gestion.pe/peru/vacuna-covid-19-peru-presidente-sagasti-recibio-dosis-de-vacuna-sinopharm-contra-covid-19-coronavirus-segunda-ola-nndc-noticia/ |
| Segunda | 2021-03-02 | https://andina.pe/agencia/noticia-presidente-sagasti-recibe-segunda-dosis-de-vacuna-contra-covid19-835719.aspx |
| Tercera (Primer refuerzo) | 2021-10-15 | https://elcomercio.pe/lima/sucesos/tercera-dosis-en-peru-hoy-se-inicia-la-inmunizacion-a-personal-de-salud-y-esto-es-todo-lo-que-tienes-que-saber-covid-19-tercera-ola-coronavirus-nndc-noticia/ |
| Cuarta (Segundo refuerzo) | 2022-04-02 | https://www.swissinfo.ch/spa/coronavirus-per%C3%BA_per%C3%BA-aplicar%C3%A1-una-cuarta-dosis-de-la-vacuna-contra-la-covid-19/47484482 |

## Contenido y estructura de los datos

Los datos procesados incluyen:

- Datos acumulados por día y fabricante
- Datos acumulados por semana epidemiológica, y rango de edades (tres agrupaciones: quintiles, deciles, y los rangos empleados por OWID)

En las estructuras siguientes, el campo `flag_vacunacion_general` se define de las siguiente manera:

```
flag_vacunacion_general = IF 
  (
    (fabricante == "SINOPHARM" AND fecha_vacunacion > 2021-02-07)   OR
    (fabricante == "PFIZER" AND fecha_vacunacion > 2021-03-03)      OR
    (fabricante == "ASTRAZENECA" AND fecha_vacunacion > 2021-04-18) OR
    (fabricante == "MODERNA" AND fecha_vacunacion > 2022-03-25)
  ) 
  AND
  (
    (fecha_vacunacion >= 2021-02-09 AND dosis == 1) OR
    (fecha_vacunacion >= 2021-03-02 AND dosis == 2) OR
    (fecha_vacunacion >= 2021-10-15 AND dosis == 3) OR
    (fecha_vacunacion >= 2022-04-02 AND dosis == 4)
  )
THEN
  TRUE
ELSE
  FALSE
```

### Estructura de datos acumulados por día, fabricante y dosis:

- [datos/vacunas_covid_resumen.csv](datos/vacunas_covid_resumen.csv)

| Campo              | Contenido                                                   |
| :----------------- | :---------------------------------------------------------- |
| `fecha_corte`      | Fecha de corte para los datos (YYYY-MM-DD)                  |
| `fecha_vacunacion` | Fecha de vacunación (YYYY-MM-DD)                            |
| `fabricante`       | Fabricante de la vacuna                                     |
| `dosis`            | Dosis de la vacuna (1 = primera, 2 = segunda, 3 = refuerzo) |
| `n_reg`            | Número de vacunaciones (registros)                          |
| `flag_vacunacion_general` | Si los datos parecen corresponder al proceso general de vacunación |


### Estructura de datos acumulados por día, fabricante:

[datos/vacunas_covid_fabricante.csv](datos/vacunas_covid_fabricante.csv)

| Campo                | Contenido                                         |
| :------------------- | :------------------------------------------------ |
| `location`           | Peru                                              |
| `date`               | Fecha de vacunación (YYYY-MM-DD)                  |
| `vaccine`            | Fabricante de la vacuna                           |
| `vaccinations`       | Número de vacunaciones del fabricante en la fecha |
| `total_vaccinations` | Número acumulado de vacunaciones por fabricante   |
| `flag_vacunacion_general` | Si los datos parecen corresponder al proceso general de vacunación |


### Estructura de datos acumulados por semana epidemiológica y dosis

- [datos/vacunas_covid_totales_por_semana.csv](datos/vacunas_covid_totales_por_semana.csv)

| Campo                    | Contenido                                                                                            |
| :----------------------- | :--------------------------------------------------------------------------------------------------- |
| `location`               | Peru                                                                                                 |
| `epi_year`               | Año epidemiológico                                                                                   |
| `epi_week`               | Semana epidemiológica                                                                                |
| `last_day_of_epi_week`   | Fecha (YYYY-MM-DD) del último día de la semana epidemiológica (Sábado)                               |
| `complete_epi_week`      | Datos corresponden a una semana completa (1) o incompleta (0)                                        |
| `vaccine_dose`           | Dosis de la vacuna (1, 2, etc.)                                                                      |
| `vaccinations_epi_week`  | Número de vacunaciones en la semana epidemiológica por dosis                                         |
| `total_vaccinations`     | Número acumulado de vacunaciones por dosis                                                           |
| `pct_total_vaccinations` | Porcentaje de la población total (Perú, 2021) correspondiente al acumulado de vacunaciones por dosis |
| `flag_vacunacion_general` | Si los datos parecen corresponder al proceso general de vacunación |


### Estructura de datos por semana epidemiológica y rango de edades:

_Nota_: Estos datos contemplan solamente los registros para los cuales `flag_vacunacion_general == TRUE`

*Para veintiles, deciles y quintiles*

- [datos/vacunas_covid_rangoedad_veintiles.csv](datos/vacunas_covid_rangoedad_veintiles.csv)
- [datos/vacunas_covid_rangoedad_deciles.csv](datos/vacunas_covid_rangoedad_deciles.csv)
- [datos/vacunas_covid_rangoedad_quintiles.csv](datos/vacunas_covid_rangoedad_quintiles.csv)

| Campo                  | Contenido                                                                             |
| :--------------------- | :------------------------------------------------------------------------------------ |
| `fecha_corte`          | Fecha de corte para los datos (YYYY-MM-DD)                                            |
| `epi_year`             | Año epidemiológico                                                                    |
| `epi_year`             | Semana epidemiológica                                                                 |
| `last_day_of_epi_week` | Fecha (YYYY-MM-DD) del último día de la semana epidemiológica (Sábado)               |
| `complete_epi_week`    | Datos corresponden a una semana completa (1) o incompleta (0)                         |
| `rango_edad`           | Rango de edades considerado                                                           |
| `dosis`                | Dosis de la vacuna (1 = primera, 2 = segunda, 3 = refuerzo)                           |
| `n`                    | Número de vacunaciones (registros)                                                    |
| `n_acum`               | Número de vacunaciones (registros) acumulados a la fecha                              |
| `pob2021`              | Población en el rango de edad considerado                                             |
| `pct_acum`             | Porcentaje de la población (acumulada) en el rango de edad y con la dosis considerada |


*Para rangos de edad de OWID*

- [datos/vacunas_covid_rangoedad_owid.csv](datos/vacunas_covid_rangoedad_owid.csv)

_Notas_: Estos datos contemplan solamente los registros para los cuales `flag_vacunacion_general == TRUE`

| Campo                                  | Contenido                                                               |
| :------------------------------------- | :---------------------------------------------------------------------- |
| `location`                             | País (Peru)                                                             |
| `fecha_corte`                          | Fecha de corte para los datos (YYYY-MM-DD)                              |
| `epi_year`                             | Año epidemiológico                                                      |
| `epi_year`                             | Semana epidemiológica                                                   |
| `last_day_of_epi_week`                 | Fecha (YYYY-MM-DD) del último día de la seamana epidemiológica (Sábado) |
| `complete_epi_week`                    | Datos corresponden a una semana completa (1) o incompleta (0)           |
| `age_group_min`                        | Edad mínima del rango de edades                                         |
| `age_group_max`                        | Edad máxima del rango de edades                                         |
| `people_vaccinated_per_hundred`        | Personas por cada cien que han recibido al menos una dosis (dosis = 1)  |
| `people_fully_vaccinated_per_hundred`  | Personas por cada cien completamente vacunadas (dosis = 2)              |
| `people_receiving_booster_per_hundred` | Personas por cada cien que han recibido refuerzo (dosis = 3)            |
| `people_receiving_second_booster_per_hundred` | Personas por cada cien que han recibido un segundo refuerzo (dosis = 4)            |




## Datos que no se están actualizando

Debido al cambio en la estructura de los datos originales, ya no es simple el enlazar la información con datos como el UBIGEO, macroregiones, etc., de manera que los datos listados a continuación ya no van a actualizar.

### Estructura de datos acumulados por UBIGEO, fabricante y dosis

- [datos/vacunas_covid_totales_fabricante_ubigeo.csv](datos/vacunas_covid_totales_fabricante_ubigeo.csv)

| Campo               | Contenido                                                   |
| :------------------ | :---------------------------------------------------------- |
| `fecha_corte`       | Fecha de corte para los datos (YYYY-MM-DD)                  |
| `ubigeo_persona`    | UBIGEO de la persona                                        |
| `departamento`      | Departamento correspondiente al UBIGEO                      |
| `provincia`         | Provincia correspondiente al UBIGEO                         |
| `distrito`          | Distrito correspondiente al UBIGEO                          |
| `macroregion_inei`  | Macroregión según INEI                                      |
| `macroregion_minsa` | Macroregión según MINSA                                     |
| `fabricante`        | Fabricante de la vacuna                                     |
| `dosis`             | Dosis de la vacuna (1 = primera, 2 = segunda, 3 = refuerzo) |
| `n_reg`             | Número de vacunaciones (registros)                          |
| `flag_vacunacion_general` | Si los datos parecen corresponder al proceso general de vacunación |


## Acerca de clonar este repositorio

Si quieres hacer un clon de este repositorio, cuya historia contiene muchos archivos grandes (blobs), te sugiero que hagas un "blob-less" clone, de manera que sólo descargas lo mas reciente y si lo requieres puedes obtener los anteriores, algo como:

```
$ git clone --filter=blob:none https://github.com/jmcastagnetto/covid-19-peru-vacunas.git
```

Un buen artículo sobre este tema es [Get up to speed with partial clone and shallow clone](https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/)

## Notas

- 2021-04-30: OWID está usando los datos resumidos de vacunación de este repositorio como fuente, para el Perú (ref: https://github.com/owid/covid-19-data/commit/52bb05a0a5954983dca347f92d0af95fada1bbd0)
- 2021-05-13: Los datos procesados y aumentados se están ahora separando en múltiples archivos (cada millón de registros), para evitar llegar al límite máximo en tamaño de Github. Los nombres son de la forma `vacunas_covid_aumentada_NNN.csv.gz`, donde `NNN` es el número de secuencia del archivo.
- 2021-08-19: OWID está usando los datos por rango etáreo de este repositorio como fuente, para el Perú (ref: https://github.com/owid/covid-19-data/commit/2a40909953e4e66687156049f79e88567ab55741)
- 2021-08-30: Por cuarta vez desde que comenzaron a publicar los datos abiertos de vacunas, el URL canónico de los datos ha sido cambiado sin anuncio previo. El código de proceso se ha modificado para tomar esto en cuenta.
- 2021-09-01: He re-escrito todo el flujo del proceso de datos, incluyendo la opción de cargar todo a una BD local para consistencia.
- 2021-09-09: Los datos de la fuente oficial de los últimos días tenían inconsitencias, hoy ya parecen estar bien, pero ha cambiado la estructura de los mismos: se ha agregado el campo de edad (que antes se obtenía de la tabla de personas).
- 2021-10-01: A partir de hoy, estoy acumulando otro conjunto de datos, resumiendo el número de vacunados por UBIGEO (a nivel de distrito), fabricante y dosis
- 2021-11-04: El formato de fechas ya no es mas "dd/mm/yyyy" sino "yyyymmdd"
- 2021-12-03: OWID está usando los datos acumulados de vacunas por fabricante de este repositorio, para el Perú (ref: https://github.com/owid/covid-19-data/commit/e94d0639760d3a95f715c2d5e4db37814bd9c25b)
- 2022-01-30: He agregado un github action para usar [Frictionless Repository](https://repository.frictionlessdata.io/) en la validación de los datos resumidos generados.
- 2022-06-13: En Junio del 2022, los datos estan siendo geo-bloqueados para cualquiera con IP que no esté en Perú. Además, la estructura de datos a cambiado, perdiéndose la información de ubigeos que se tenía antes.
- 2022-08-28: A partir de la actualización de esta fecha, los resultados intermedios ya no se almacenan en formato Parquet de Arrow, sino en una base de datos de duckdb (https://duckdb.org)
- 2022-09-12: Con ayuda de https://twitter.com/Nest0R, quien proveyó una solución, he podido procesar los datos aún estando (por trabajo) fuera del país. Los datos siguen geo-bloqueados en el repositorio del MINSA, lo cual es una gran pena y nunca debió ocurrir.
- 2022-09-20: En algún momento luego del 2022-09-16, el URL de los datos de vacunación cambió otra vez (ahora es: https://cloud.minsa.gob.pe/s/To2QtqoNjKqobfw/download), y ya no están geobloqueados. Ojalá se mantenga así en el futuro.
- 2022-09-25: La estructura de datos ha cambiado nuevamente, ahora se tiene una columna extra: `TIPO_EDAD`
