#! /bin/bash

# sample 1M entries to validate

( xsv sample 1000000 datos/orig/vacunas_covid.csv | \
	frictionless validate --type resource --schema schemas/vacunas_covid-orig-schema.yaml -- )
exit $?
