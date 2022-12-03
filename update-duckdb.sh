#! /bin/bash

eval $(keychain --agents gpg)

# figure out the current data URL using the dkan API
dataurl=`curl -s 'https://www.datosabiertos.gob.pe/api/3/action/package_show?id=24af4ff4-226d-4e3d-90cb-d26a1849796e' |  jq '.result| map(.resources)| .[] | .[] | .url' | head -1 | tr -d '"'`
echo "Datos del $dataurl"
echo ""
mv datos/orig/vacunas_covid.7z datos/orig/vacunas_covid-prev.7z
# get the data including the appropriate headers to it lowers the risk of been blocked
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
  exit 1
else
  today=`date +%Y-%m-%d`
  echo "Datos han cambiado"
  sha256sum datos/orig/vacunas_covid.7z > sha256sum.txt
  echo "Extrayendo el CSV"
  7z e -aoa -odatos/orig/ datos/orig/vacunas_covid.7z
  ls -lh datos/orig/
  head -5 datos/orig/vacunas_covid.csv
  echo "Validando datos de entrada"
  # Validate input data
  # sample 1M entries to validate
  xsv sample 1000000 datos/orig/vacunas_covid.csv > tmp/sample_vacunas.csv
  frictionless validate --type resource --schema schemas/vacunas_covid-orig-schema.yaml tmp/sample_vacunas.csv
  fstatus=$?
  if [ $fstatus -eq 0 ]
  then
    rm tmp/sample_vacunas.csv
    echo ">> Muestra de 1M de datos de entrada validados"
  else
    echo "** Error: Datos de entrada no tienen el formato esperado **"
    exit $fstatus
  fi
  # Load data into duckdb
  echo "Backup de BD previa"
  mv tmp/ddb/peru-vacunas-covid19.duckdb tmp/ddb/peru-vacunas-covid19-backup.duckdb
  echo "Inicializando duckdb"
  Rscript create-duckdb-tables.R
  echo "Cargando en duckdb"
  duckdb -init tmp/ddb/duckdb-config.sql tmp/ddb/peru-vacunas-covid19.duckdb < tmp/ddb/duckdb-load-csv.sql
  echo "Generando los resúmenes"
  Rscript process-data-from-duckdb.R
  # Get the cut-off date using the "-list" option as "-ascii" produces an RS (0x1e) char
  fcorte=`duckdb -list -noheader -c "SELECT FECHA_CORTE FROM vacunas_proc LIMIT 1;" tmp/ddb/peru-vacunas-covid19.duckdb`
  # Just in case, there is a need to remove RS 0x1e in the future
  # fcorte=$(echo $fcorte | sed 's/[\x1e]//g')
  # Validate output data
  echo "Validando datos"
  ( frictionless validate --schema schemas/vacunas_covid_fabricante-schema.yaml datos/vacunas_covid_fabricante.csv && \
    frictionless validate --schema schemas/vacunas_covid_rangoedad_deciles-schema.yaml datos/vacunas_covid_rangoedad_deciles.csv && \
    frictionless validate --schema schemas/vacunas_covid_rangoedad_owid-schema.yaml datos/vacunas_covid_rangoedad_owid.csv && \
    frictionless validate --schema schemas/vacunas_covid_rangoedad_quintiles-schema.yaml datos/vacunas_covid_rangoedad_quintiles.csv && \
    frictionless validate --schema schemas/vacunas_covid_rangoedad_veintiles-schema.yaml datos/vacunas_covid_rangoedad_veintiles.csv && \
    frictionless validate --schema schemas/vacunas_covid_resumen-schema.yaml datos/vacunas_covid_resumen.csv && \
    frictionless validate --schema schemas/vacunas_covid_totales_por_semana-schema.yaml datos/vacunas_covid_totales_por_semana.csv )
  outvalstat=$?
  if [ $outvalstat -ne 0 ]
  then
    echo "** Validación de los datos ha fallado, revisar antes de publicar **"
    exit $outvalstat
  else
    echo "Estado del repo"
    git status
    tail datos/vacunas_covid_resumen.csv
	git commit -a -m "Datos al $fcorte, procesados automáticamente el $today"
    git push origin main
  fi
  exit 0
fi
