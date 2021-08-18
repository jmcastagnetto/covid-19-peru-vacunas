.mode csv
DROP TABLE IF EXISTS vacunas_covid;
CREATE TABLE `vacunas_covid` (
  `fecha_corte` TEXT,
  `uuid` TEXT,
  `grupo_riesgo` TEXT,
  `edad` NUMERIC,
  `sexo` TEXT,
  `fecha_vacunacion` TEXT,
  `dosis` TEXT,
  `fabricante` TEXT,
  `diresa` TEXT,
  `departamento` TEXT,
  `provincia` TEXT,
  `distrito` TEXT,
  `rango_edad` TEXT,
  `rango_edad2` TEXT,
  `rango_edad_owid` TEXT,
  `epi_week` INTEGER,
  `epi_year` INTEGER
);
.import datos/tmp.csv vacunas_covid
CREATE INDEX uuid_idx ON vacunas_covid(uuid);
CREATE INDEX dpto_idx ON vacunas_covid(departamento);
CREATE INDEX prov_idx ON vacunas_covid(provincia);
CREATE INDEX dist_idx ON vacunas_covid(distrito);
CREATE INDEX dose_idx ON vacunas_covid(dosis);
CREATE INDEX fabr_idx ON vacunas_covid(fabricante);
CREATE INDEX grpr_idx ON vacunas_covid(grupo_riesgo);
CREATE INDEX sexo_idx ON vacunas_covid(sexo);
CREATE INDEX drsa_idx ON vacunas_covid(diresa);
CREATE INDEX rng1_idx ON vacunas_covid(rango_edad);
CREATE INDEX rng2_idx ON vacunas_covid(rango_edad2);
ANALYZE vacunas_covid;
