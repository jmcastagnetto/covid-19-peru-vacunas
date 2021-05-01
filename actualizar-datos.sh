#! /bin/bash

wget -O datos/orig/vacunas_covid.csv  https://cloud.minsa.gob.pe/s/ZgXoXqK2KLjRLxD/download
gzip -9 datos/orig/vacunas_covid.csv
Rscript get-data.R
now=`date -I`
git commit -a -m "Actualizado el $now"
git push origin main

#Rscript vacunados-covid19-plots.R
#Rscript distribucion-dias-entre-dosis.R
