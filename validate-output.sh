#! /bin/bash

( frictionless validate --schema schemas/vacunas_covid_fabricante-schema.yaml datos/vacunas_covid_fabricante.csv && \
frictionless validate --schema schemas/vacunas_covid_rangoedad_deciles-schema.yaml datos/vacunas_covid_rangoedad_deciles.csv && \
frictionless validate --schema schemas/vacunas_covid_rangoedad_owid-schema.yaml datos/vacunas_covid_rangoedad_owid.csv && \
frictionless validate --schema schemas/vacunas_covid_rangoedad_quintiles-schema.yaml datos/vacunas_covid_rangoedad_quintiles.csv && \
frictionless validate --schema schemas/vacunas_covid_rangoedad_veintiles-schema.yaml datos/vacunas_covid_rangoedad_veintiles.csv && \
frictionless validate --schema schemas/vacunas_covid_resumen-schema.yaml datos/vacunas_covid_resumen.csv && \
frictionless validate --schema schemas/vacunas_covid_totales_por_semana-schema.yaml datos/vacunas_covid_totales_por_semana.csv )
exit $?
