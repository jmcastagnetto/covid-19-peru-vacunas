library(tidyverse)
library(DBI)
library(duckdb)
library(lubridate)
library(cli)

# Conectar a duckdb y generar tablas accesorias ---------------------------

ddb_fn <- "tmp/ddb/peru-vacunas-covid19.duckdb"

if (file.exists(ddb_fn)) {
  unlink(ddb_fn) # make sure we start from a newly created db file
}
# Open the duckdb database file
con = dbConnect(duckdb(),
                dbdir = ddb_fn,
                read_only = FALSE)
tmp <- dbExecute(con, "SET memory_limit='6GB';")

# vacunas
ddl_vacunas <- "
CREATE OR REPLACE TABLE vacunas (
  FECHA_CORTE       DATE,
  UUID              VARCHAR,
  GRUPO_RIESGO      VARCHAR,
  EDAD              INTEGER,
  SEXO              VARCHAR,
  FECHA_VACUNACION  DATE,
  DOSIS             INTEGER,
  FABRICANTE        VARCHAR,
  DIRESA            VARCHAR,
  DEPARTAMENTO      VARCHAR,
  PROVINCIA         VARCHAR,
  DISTRITO          VARCHAR,
  TIPO_EDAD         VARCHAR,
  -- convertir edades a años
  edad_años         INTEGER GENERATED ALWAYS AS (
    CASE WHEN TIPO_EDAD = 'M'
      THEN 0 -- FLOOR(CAST(EDAD AS DOUBLE)/12)
      ELSE EDAD
    END
  ),
  -- generar un flag para vacunacion general
  flag_vacunacion_general BOOLEAN GENERATED ALWAYS AS (
    (
      (FABRICANTE = 'SINOPHARM' AND
        FECHA_VACUNACION > (DATE '2021-02-07')) OR
      (FABRICANTE = 'PFIZER' AND
        FECHA_VACUNACION > (DATE '2021-03-03')) OR
      (FABRICANTE = 'ASTRAZENECA' AND
        FECHA_VACUNACION > (DATE '2021-04-18')) OR
      (FABRICANTE = 'MODERNA' AND
        FECHA_VACUNACION > (DATE '2022-03-25'))
    )
    AND
    (
      (FECHA_VACUNACION >= (DATE '2021-02-09') AND DOSIS = 1) OR
      (FECHA_VACUNACION >= (DATE '2021-03-02') AND DOSIS = 2) OR
      (FECHA_VACUNACION >= (DATE '2021-10-15') AND DOSIS = 3) OR
      (FECHA_VACUNACION >= (DATE '2022-04-02') AND DOSIS = 4) OR
      (FECHA_VACUNACION >= (DATE '2023-01-01') AND (DOSIS = 4 OR DOSIS = 5))
    )
  )
);
"

dbExecute(con, ddl_vacunas)

# Almacenar los datos procesados, incluyendo los campos
# dinámicamente calculados para evitar "out of memory" en duckdb
# vacunas_proc
ddl_vacunas_proc <- "
CREATE OR REPLACE TABLE vacunas_proc (
  FECHA_CORTE       DATE,
  UUID              VARCHAR,
  GRUPO_RIESGO      VARCHAR,
  EDAD              INTEGER,
  SEXO              VARCHAR,
  FECHA_VACUNACION  DATE,
  DOSIS             INTEGER,
  FABRICANTE        VARCHAR,
  DIRESA            VARCHAR,
  DEPARTAMENTO      VARCHAR,
  PROVINCIA         VARCHAR,
  DISTRITO          VARCHAR,
  TIPO_EDAD         VARCHAR,
  edad_años         INTEGER,
  flag_vacunacion_general BOOLEAN
);
"

dbExecute(con, ddl_vacunas_proc)

# Populate vacunas_proc
# pop_data_vacunas_proc <- "INSERT INTO vacunas_proc SELECT * from vacunas;"
# dbExecute(con, pop_data_vacunas_proc)


# epidates
ddl_epidates <- "
CREATE OR REPLACE TABLE epidates(
  FECHA_VACUNACION DATE,
  epi_year INTEGER,
  epi_week INTEGER,
  first_day_of_epi_week DATE,
  last_day_of_epi_week DATE,
  complete_epi_week INTEGER
);
"

dbExecute(con, ddl_epidates)

# agegroups
ddl_agegroups <- "
CREATE OR REPLACE TABLE agegroups(
  EDAD INTEGER,
  rango_edad_veintiles VARCHAR,
  rango_edad_deciles VARCHAR,
  rango_edad_quintiles VARCHAR,
  rango_edad_owid VARCHAR
)
"

dbExecute(con, ddl_agegroups)

# views per dose
ddl_dosis1 <- "
create or replace view vacunas_dosis_1 as (
  select * from vacunas_proc where flag_vacunacion_general and DOSIS = 1
);
"
dbExecute(con, ddl_dosis1)

ddl_dosis2 <- "
create or replace view vacunas_dosis_2 as (
  select * from vacunas_proc where flag_vacunacion_general and DOSIS = 2
);
"
dbExecute(con, ddl_dosis2)

ddl_dosis3 <- "
create or replace view vacunas_dosis_3 as (
  select * from vacunas_proc where flag_vacunacion_general and DOSIS = 3
);
"
dbExecute(con, ddl_dosis3)

ddl_dosis4 <- "
create or replace view vacunas_dosis_4 as (
  select * from vacunas_proc where flag_vacunacion_general and DOSIS = 4
);
"
dbExecute(con, ddl_dosis4)

#dosis_1_2_ddl <- "
#create or replace view vacunas_dosis_1_2 as (
#SELECT
#  d1.UUID,
#  d1.SEXO,
#  d1.EDAD as EDAD_1,
#  d1.GRUPO_RIESGO as GRUPO_RIESGO_1,
#  d1.FECHA_VACUNACION as FECHA_VACUNACION_1,
#  d1.FABRICANTE as FABRICANTE_1,
#  d1.DIRESA as DIRESA_1,
#  d1.DEPARTAMENTO as DEPARTAMENTO_1,
#  d1.PROVINCIA as PROVINCIA_1,
#  d1.DISTRITO as DISTRITO_1,
#  d2.EDAD as EDAD_2,
#  d2.GRUPO_RIESGO as GRUPO_RIESGO_2,
#  d2.FECHA_VACUNACION as FECHA_VACUNACION_2,
#  d2.FABRICANTE as FABRICANTE_2,
#  d2.DIRESA as DIRESA_2,
#  d2.DEPARTAMENTO as DEPARTAMENTO_2,
#  d2.PROVINCIA as PROVINCIA_2,
#  d2.DISTRITO as DISTRITO_2
#FROM
#  vacunas_dosis_1 as d1
#  left join vacunas_dosis_2 as d2
#    on d1.UUID = d2.UUID
#);
#"
#
#dbExecute(con, dosis_1_2_ddl)

multidosis_fabricante_ddl <- "
create or replace view multidosis_fabricantes as (
SELECT
  d1.FABRICANTE as FABRICANTE_1,
  d2.FABRICANTE as FABRICANTE_2,
  d3.FABRICANTE as FABRICANTE_3,
  d4.FABRICANTE as FABRICANTE_4,
  count(*) as CANTIDAD
FROM
  vacunas_dosis_1 as d1
  left join vacunas_dosis_2 as d2
    on d1.UUID = d2.UUID
  left join vacunas_dosis_3 as d3
    on d1.UUID = d3.UUID
  left join vacunas_dosis_4 as d4
    on d1.UUID = d4.UUID
GROUP BY
  d1.FABRICANTE,
  d2.FABRICANTE,
  d3.FABRICANTE,
  d4.FABRICANTE
);
"

dbExecute(con, multidosis_fabricante_ddl)

dbDisconnect(con, shutdown = TRUE)

