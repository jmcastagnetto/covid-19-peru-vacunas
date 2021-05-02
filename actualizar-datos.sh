#! /bin/bash

wget -nv -O datos/orig/vacunas_covid.csv  https://cloud.minsa.gob.pe/s/ZgXoXqK2KLjRLxD/download
md5sum --status -c md5sum.txt

if [ $? -eq 0 ]
then
	echo "Los datos no han cambiado"
	rm datos/orig/vacunas_covid.csv
else
	echo "Datos han cambiado... Procesando ..."
	md5sum datos/orig/vacunas_covid.csv > md5sum.txt
	gzip -9 -f datos/orig/vacunas_covid.csv
	Rscript get-data.R
	now=`date -I`
	git commit -a -m "Actualizado el $now"
	HOME=/home/jesus git push origin main
fi

#Rscript vacunados-covid19-plots.R
#Rscript distribucion-dias-entre-dosis.R
