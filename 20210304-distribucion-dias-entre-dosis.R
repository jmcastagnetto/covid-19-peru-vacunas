library(tidyverse)
library(ggridges)
library(lubridate)

vacunas <- readRDS("datos/vacunas_covid.rds")
min_fecha <- min(vacunas$FECHA_VACUNACION, na.rm = TRUE)
max_fecha <- max(vacunas$FECHA_VACUNACION, na.rm = TRUE)

segunda_dosis <- vacunas %>%
  filter(DOSIS == 2) %>%
  distinct() %>%
  pull(UUID)

vacunas_2dosis <- vacunas %>%
  filter(UUID %in% segunda_dosis) %>%
  arrange(UUID, DOSIS) %>%
  select(UUID, SEXO, rango_edad, DOSIS, FECHA_VACUNACION) %>%
  pivot_wider(
    names_from = "DOSIS",
    names_prefix = "dosis_",
    values_from = "FECHA_VACUNACION"
  ) %>%
  group_by(UUID, SEXO) %>%
  summarise( # para los casos que cumplieron años entre la primera y segunda dosis
    rango_edad = max(rango_edad, na.rm = TRUE),
    dosis_1 = max(dosis_1, na.rm = TRUE),
    dosis_2 = max(dosis_2, na.rm = TRUE)
  ) %>%
  mutate(
    time_diff = time_length(dosis_2 - dosis_1, unit = "day"),
    SEXO = factor(SEXO)
  ) %>%
  arrange(SEXO, rango_edad)

n_por_sexo = vacunas_2dosis %>%
  filter(SEXO != "No registrado") %>%
  group_by(SEXO) %>%
  tally()

n_por_sexo_rango <- vacunas_2dosis %>%
  filter(SEXO != "No registrado") %>%
  group_by(SEXO, rango_edad) %>%
  tally()

mediana_por_sexo_rango <- vacunas_2dosis %>%
  filter(SEXO != "No registrado") %>%
  group_by(SEXO, rango_edad) %>%
  summarise(
    mediana = median(time_diff, na.rm = TRUE)
  )

my_labeller <- as_labeller(
  c(
    "MASCULINO" = paste0(
      "Masculino\nN = ",
      n_por_sexo %>%
        filter(SEXO == "MASCULINO") %>%
        pull(n) %>%
        format(big.mark = ",")
    ),
    "FEMENINO" = paste0(
      "Femenino\nN = ",
      n_por_sexo %>%
        filter(SEXO == "FEMENINO") %>%
        pull(n) %>%
        format(big.mark = ",")
    )
  )
)

# usar la parte inferior de una de las facetas para anotar el gráfico

facet_text <- tibble(
  SEXO = c("MASCULINO", "FEMENINO"),
  rango_edad = c("0-19", "0-19"),
  texto = c("", str_wrap("Para el total de datos, un 4% de los tiempos es menor a 21 días\n(rango: [2, 23] días entre dosis)", 35))
)

p1 <- ggplot(
  vacunas_2dosis %>% filter(SEXO != "No registrado"),
  aes(x = time_diff, y = rango_edad,
      group = rango_edad,
      fill = rango_edad)
) +
  stat_density_ridges(
    quantile_lines = TRUE,
    quantiles = 2,
    show.legend = FALSE,
    jittered_points = TRUE,
    position = position_points_jitter(width = 0.05, height = 0),
    point_shape = '|', point_size = 5,
    point_alpha = 1, alpha = 0.7,
    scale = .9) +
  geom_text(
    data = n_por_sexo_rango,
    aes(x = 5,
        y = rango_edad,
        label = paste0(
          "N = ",
          format(n, big.mark = ",") %>%
            str_trim()
        )
    ),
    nudge_y = .5,
    hjust = 0,
    size = 5,
    family = "Cousine"
  ) +
  # geom_text(
  #   data = mediana_por_sexo_rango,
  #   aes(x = 5,
  #       y = rango_edad,
  #       label = paste0(
  #         "Mediana = ", mediana
  #       )
  #   ),
  #   nudge_y = .3,
  #   hjust = 0,
  #   size = 5,
  #   family = "Cousine"
  # ) +
  geom_label(
    data = facet_text,
    aes(x = 1, y = rango_edad, label = texto),
    size = 10,
    fontface = "italic",
    hjust = 0,
    label.size = 0,
    fill = "black"
  ) +
  facet_wrap(~SEXO, labeller = my_labeller, scales = "free_x") +
  coord_cartesian(xlim = c(0, NA)) +
  labs(
    x = "Número de días entre dosis",
    y = "",
    title = "Vacunación por COVID-19 (Perú): Intervalo entre primera y segunda dosis",
    subtitle = glue::glue("Fabricante: SINOPHARM, Rango de fechas: del {min_fecha} al {max_fecha}"),
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  )  +
  ggdark::dark_theme_minimal(base_size = 24, base_family = "Cousine") +
  theme(
    axis.ticks.x = element_line(color = "black"),
    axis.ticks.length.x = unit(.5, "cm"),
    axis.title.x = element_text(hjust = 1),
    strip.background = element_blank(),
    plot.caption = element_text(family = "Inconsolata"),
    plot.title.position = "plot",
    strip.text = element_text(face = "bold", hjust = 0),
    plot.margin = unit(rep(.5, 4), "cm")
  )

ggsave(
  plot = p1,
  filename = "plots/20210304-distribucion-tiempos-entre-vacunas-covid19-peru.png",
  width = 16,
  height = 9.5
)
