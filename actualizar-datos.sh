#! /bin/bash

#Rscript get-data.R
now=`date -I`
git commit -a --no-gpg-sign -m "Actualizado automáticamente el $now"


#Rscript vacunados-covid19-plots.R
#Rscript distribucion-dias-entre-dosis.R
