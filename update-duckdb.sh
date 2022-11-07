#! /bin/bash

dataurl=`curl -s 'https://www.datosabiertos.gob.pe/api/3/action/package_show?id=24af4ff4-226d-4e3d-90cb-d26a1849796e' |  jq '.result| map(.resources)| .[] | .[] | .url' | head -1 | tr -d '"'`
echo "Datos del $dataurl"
echo ""
mv datos/orig/vacunas_covid.7z datos/orig/vacunas_covid-prev.7z
# aria2c -c -x4 -d datos/orig --force-save -o vacunas_covid.7z --file-allocation=falloc $dataurl
curl -o datos/orig/vacunas_covid.7z -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" --referer 'https://www.datosabiertos.gob.pe/dataset/vacunaci%C3%B3n-contra-covid-19-ministerio-de-salud-minsa' $dataurl
dwnlstat=$?
if [ $dwnlstat -ne 0 ];
then
	echo "** Error descargando los datos, intentar luego **"
	exit $dwnlstat
fi

ls -lh datos/orig/vacunas_covid.7z
sha256sum --status -c sha256sum.txt

if [ $? -eq 0 ]
then
  echo "Los datos no han cambiado"
else
  echo "Datos han cambiado"
  sha256sum datos/orig/vacunas_covid.7z > sha256sum.txt
  echo "Extrayendo el CSV"
  7z e -aoa -odatos/orig/ datos/orig/vacunas_covid.7z
  ls -lh datos/orig/
  head -5 datos/orig/vacunas_covid.csv
  echo "Validando datos de entrada"
  ./validate-input-data.sh
  invalstat=$?
  if [ $invalstat -ne 0 ]
  then
	  echo "** Error: Datos de entrada no tienen el formato esperado **"
	  exit $invalstat
  else
	  echo ">> Muestra de 1M de datos de entrada validados"
  fi
  echo "Backup de BD previa"
  mv tmp/ddb/peru-vacunas-covid19.duckdb tmp/ddb/peru-vacunas-covid19-backup.duckdb
  echo "Inicializando duckdb"
  Rscript create-duckdb-tables.R
  echo "Cargando en duckdb"
  duckdb -init tmp/ddb/duckdb-config.sql tmp/ddb/peru-vacunas-covid19.duckdb < tmp/ddb/duckdb-load-csv.sql
  echo "Generando los resúmenes"
  Rscript process-data-from-duckdb.R
  echo "Validando datos"
  ./validate-output.sh
  outvalstat=$?
  if [ $outvalstat -ne 0 ];
  then
	  echo "** Validación de los datos ha fallado, revisar antes de publicar **"
  fi
  echo "Estado del repo"
  git status
  tail datos/vacunas_covid_resumen.csv
fi
