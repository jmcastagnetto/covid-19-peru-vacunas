#! /bin/bash

# sample 1M entries to validate

xsv sample 1000000 datos/orig/vacunas_covid.csv > tmp/sample_vacunas.csv
frictionless validate --type resource --schema schemas/vacunas_covid-orig-schema.yaml tmp/sample_vacunas.csv
fstatus=$?
if [ $fstatus -eq 0 ]
then
	rm tmp/sample_vacunas.csv
fi
exit $fstatus
