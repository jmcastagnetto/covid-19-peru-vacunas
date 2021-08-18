#! /bin/bash

Rscript 03-proc-secondary-formats.R
# remove the header of the csv
tail -n +2 datos/vacunas_covid_aumentada.csv > datos/tmp.csv
rm datos/vacunas_covid_aumentada.sqlite
sqlite3 datos/vacunas_covid_aumentada.sqlite < vacunas_covid_aumentada-sqlite.sql
ls -lh datos/vacunas_covid_aumentada.sqlite
rm datos/tmp.csv
