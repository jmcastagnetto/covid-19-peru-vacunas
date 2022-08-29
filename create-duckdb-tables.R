library(tidyverse)
library(DBI)
library(duckdb)
library(lubridate)
library(cli)

# Conectar a duckdb y generar tablas accesorias ---------------------------

# Open the duckdb database file
con = dbConnect(duckdb(),
                dbdir = "tmp/ddb/peru-vacunas-covid19.duckdb",
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
      (FECHA_VACUNACION >= (DATE '2022-04-02') AND DOSIS = 4)
    )
  )
);
"

dbExecute(con, ddl_vacunas)

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

dbDisconnect(con, shutdown = TRUE)
