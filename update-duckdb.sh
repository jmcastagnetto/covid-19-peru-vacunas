#! /bin/bash

dataurl=`curl -s 'https://www.datosabiertos.gob.pe/api/3/action/package_show?id=24af4ff4-226d-4e3d-90cb-d26a1849796e' |  jq '.result| map(.resources)| .[] | .[] | .url' | head -1 | tr -d '"'`
echo "Datos del $dataurl"
echo ""
mv datos/orig/vacunas_covid.7z datos/orig/vacunas_covid-prev.7z
aria2c -c -x8 -d datos/orig --force-save -o vacunas_covid.7z --file-allocation=falloc $dataurl
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
  echo "Backup de bd previa"
  mv tmp/ddb/peru-vacunas-covid19.duckdb tmp/ddb/peru-vacunas-covid19-backup.duckdb
  echo "Init duckdb"
  Rscript create-duckdb-tables.R
  echo "Cargando en duckdb"
  duckdb -init tmp/ddb/duckdb-config.sql tmp/ddb/peru-vacunas-covid19.duckdb < tmp/ddb/duckdb-load-csv.sql
  echo "Generando los resúmenes"
  Rscript process-data-from-duckdb.R
  echo "Validando datos"
  ./validate-output.sh
  echo "Estado del repo"
  git status
  tail datos/vacunas_covid_resumen.csv
fi
