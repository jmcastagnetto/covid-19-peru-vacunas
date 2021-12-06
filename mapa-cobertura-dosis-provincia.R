library(tidyverse)
library(sf)
library(geodata)

peru_prov <- geodata::gadm("PE", level = 2, path = "datos/")
peru_prov_map <- st_as_sf(peru_prov) %>%
  mutate(
    NAME_1 = str_to_upper(NAME_1) %>% iconv(to='ASCII//TRANSLIT') %>%
      str_replace("LIMA PROVINCE", "LIMA"),
    NAME_2 = str_to_upper(NAME_2) %>% iconv(to='ASCII//TRANSLIT') %>%
      str_replace("HUENUCO", "HUANUCO")
  ) %>%
  rename(
    departamento = NAME_1,
    provincia = NAME_2
  ) %>%
  group_by(departamento, provincia) %>%
  summarise()

pob2021 <- readRDS("datos/peru-pob2021-provincias.rds") %>%
  select(
    ubigeo_prov = ubigeo,
    poblacion = total
  )

vacunas_prov_dosis <- readRDS("datos/vacunas_covid_totales_fabricante_ubigeo.rds") %>%
  mutate(
    ubigeo_prov = substr(ubigeo_persona, 1, 4)
  ) %>%
  group_by(ubigeo_prov, departamento, provincia, dosis) %>%
  summarise(
    total = sum(n_reg, na.rm = TRUE)
  ) %>%
  left_join(
    pob2021,
    by = "ubigeo_prov"
  ) %>%
  mutate(
    pct = total / poblacion
  ) %>%
  ungroup() %>%
  select(
    departamento,
    provincia,
    dosis,
    pct
  ) %>%
  distinct() %>%
  mutate(
    departamento = iconv(departamento, to='ASCII//TRANSLIT'),
    provincia = iconv(provincia, to='ASCII//TRANSLIT')
  )

peru_prov_map_df <- peru_prov_map %>%
  full_join(
    vacunas_prov_dosis,
    by = c("departamento", "provincia")
  ) %>%
  filter(!is.na(pct)) %>%
  filter(dosis <= 3) %>% # en datos abiertos hay dosis = 4 ???
  mutate(
    dosis_lbl = case_when(
      dosis == 1 ~ "Al menos una dosis",
      dosis == 2 ~ "Ambas dosis",
      dosis == 3 ~ "Dosis de refuerzo"
    ) %>%
      factor(
        levels = c("Al menos una dosis",
                   "Ambas dosis",
                   "Dosis de refuerzo"),
        ordered = TRUE
      )
  )

ggplot(peru_prov_map_df) +
  geom_sf(aes(fill = pct * 100)) +
  scale_fill_viridis_b(direction = -1, n.breaks = 8, option = "plasma") +
  theme_void(16) +
  facet_wrap(~dosis_lbl, nrow = 1) +
  theme(
    axis.text = element_blank(),
    strip.text = element_text(face = "italic", size = 20),
    plot.title.position = "plot",
    plot.title = element_text(size = 32),
    plot.subtitle = element_text(size = 24, colour = "gray40"),
    plot.caption = element_text(size = 16, family = "Inconsolata"),
    plot.margin = unit(rep(1, 4), "cm"),
    plot.background = element_rect(fill = "white", colour = "white"),
    legend.key.height = unit(2, "cm")
  ) +
  labs(
    fill = "% de la\npoblación\nvacunada",
    title = "Perú: Cobertura de vacunación COVID-19 por dosis a nivel de provincia",
    subtitle = "Fuente: Datos abiertos del MINSA (al 2021-12-04)",
    caption = "@jmcastagnetto, Jesus M. Castagnetto"
  )

ggsave(
  filename = "peru-cobertura-vacunas-provincia-dosis.png",
  width = 18,
  height = 10
)
