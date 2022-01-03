# Datos de vacunación en Peru procesados, corregidos y resumidos


[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5748333.svg)](https://doi.org/10.5281/zenodo.5748333)


## Fuente

Datos procesados y aumentados, usando los datos abiertos sobre vacunaciones COVID-19 en Perú: https://www.datosabiertos.gob.pe/dataset/vacunacion

**Nota importante**:

La primera vacuna de la campaña general de vacunación contra el COVID-19 en Perú, se puso el 2021-02-08, por lo que las fechas anteriores a ese día en los datos abiertos que publica el MINSA, corresponden a registros (parciales) de las dosis aplicadas durante los ensayos clínicos que se hicieron en el país.


## Contenido y estructura de los datos

Los datos procesados incluyen:

- Datos acumulados por día y fabricante
- Datos acumulados por semana epidemiológica, y rango de edades (tres agrupaciones: quintiles, deciles, y los rangos empleados por OWID)

### Estructura de datos acumulados por día, fabricante y dosis:

- [datos/vacunas_covid_resumen.csv](datos/vacunas_covid_resumen.csv)

| Campo              | Contenido                                                   |
| :----------------- | :---------------------------------------------------------- |
| `fecha_corte`      | Fecha de corte para los datos (YYYY-MM-DD)                  |
| `fecha_vacunacion` | Fecha de vacunación (YYYY-MM-DD)                            |
| `fabricante`       | Fabricante de la vacuna                                     |
| `dosis`            | Dosis de la vacuna (1 = primera, 2 = segunda, 3 = refuerzo) |
| `n_reg`            | Número de vacunaciones (registros)                          |


### Estructura de datos acumulados por día, fabricante:

[datos/vacunas_covid_fabricante.csv](datos/vacunas_covid_fabricante.csv)

| Campo                | Contenido                                         |
| :------------------- | :------------------------------------------------ |
| `location`           | Peru                                              |
| `date`               | Fecha de vacunación (YYYY-MM-DD)                  |
| `vaccine`            | Fabricante de la vacuna                           |
| `vaccinations`       | Número de vacunaciones del fabricante en la fecha |
| `total_vaccinations` | Número acumulado de vacunaciones por fabricante   |


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


### Estructura de datos por semana epidemiológica y rango de edades:

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
| `people_recieving_booster_per_hundred` | Personas por cada cien que han recibido refuerzo (dosis = 3)            |





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
- 2021-09-09: Los datos de la fuente oficial de los últimos tenían inconsitencias, hoy ya parecen estar bien, pero ha cambiado la estructura de los mismos: se ha agregado el campo de edad (que antes se obtenía de la tabla de personas).
- 2021-10-01: A partir de hoy, estoy acumulando otro conjunto de datos, resumiendo el número de vacunados por UBIGEO (a nivel de distrito), fabricante y dosis
- 2021-11-04: El formato de fechas ya no es mas "dd/mm/yyyy" sino "yyyymmdd"
- 2021-12-03: OWID está usando los datos acumulados de vacunas por fabricante de este repositorio, para el Perú (ref: https://github.com/owid/covid-19-data/commit/e94d0639760d3a95f715c2d5e4db37814bd9c25b)
