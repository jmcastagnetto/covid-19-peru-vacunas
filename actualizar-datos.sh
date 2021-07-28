#! /bin/bash

# use aria2c multithreaded multiple connection download
aria2c -c -x8 -d datos/orig/ -o vacunas_covid.7z --file-allocation=falloc https://cloud.minsa.gob.pe/s/To2QtqoNjKqobfw/download
sha256sum --status -c sha256sum.txt

if [ $? -eq 0 ]
then
	echo "Los datos no han cambiado"
	rm datos/orig/vacunas_covid.7z
else
	echo "Datos han cambiado... Procesando ..."
	md5sum datos/orig/vacunas_covid.7z > md5sum.txt
	Rscript get-data.R
	now=`date -I`
    git add datos
	git commit -a -m "Actualizado automáticamente el $now"
	git push origin main
fi
