#! /bin/bash

Rscript get-data.R
now=`date -I`
git commit -a -m "Actualizado el $now"
git push origin main

#Rscript vacunados-covid19-plots.R
#Rscript distribucion-dias-entre-dosis.R
