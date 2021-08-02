library(tidyverse)
library(patchwork)
library(ggalt)

vacunas <- readRDS("datos/vacunas_covid_resumen.rds")
pe <- Sys.setlocale("LC_TIME", "es_PE.utf8")


# Primera dosis -----------------------------------------------------------

dosis1 <- vacunas %>%
  filter(dosis == 1) %>%
  group_by(fecha_vacunacion) %>%
  summarise(
    n = sum(n_reg, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  arrange(fecha_vacunacion) %>%
  mutate(
    n_ac = cumsum(n),
    tramo = trunc(n_ac / 1e6),
    n_days = as.integer(fecha_vacunacion - min(fecha_vacunacion))
  )

max_fechavac1 <- max(dosis1$fecha_vacunacion)

markers_1 <- dosis1 %>%
  group_by(tramo) %>%
  summarise(
    fecha = min(fecha_vacunacion),
    n_ac = min(n_ac),
    dias = min(n_days)
  ) %>%
  ungroup() %>%
  mutate(
    tramo_lbl = glue::glue(
      "{format({as.integer(tramo) * 1000000L}, big.mark = ',', format = 'd', trim = TRUE)} - {format({as.integer(tramo + 1) * 1000000L}, big.mark = ',', format = 'd', trim = TRUE)}"
    ),
    fecha_next = lead(fecha),
    fecha_next = replace_na(fecha_next, max_fechavac1),
    dias_diff = as.numeric(fecha_next - fecha),
    fecha_middle = fecha + (dias_diff / 2)
  )

p1 <- ggplot(
  markers_1
) +
  geom_dumbbell(
    aes(y = tramo_lbl, x = fecha, xend = fecha_next),
    colour_x = "green",
    colour_xend = "black",
    size_x = 4,
    size_xend = 4,
    size = 2,
    dot_guide = TRUE,
    dot_guide_colour = "gray70",
    dot_guide_size = 1
  ) +
  geom_text(
    aes(
      y = tramo_lbl,
        x = fecha_middle,
        label = glue::glue("{dias_diff} días")
    ),
    nudge_y = 0.15,
    size = 6
  ) +
  annotate(
    geom = "text",
    label = "Primera dosis",
    size = 12,
    x = as.Date("2021-07-01"),
    y = 2.5
  ) +
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b"
  ) +
  theme_classic() +
  labs(
    x = "",
    y = ""
  ) +
  theme(
    axis.text = element_text(size = 14)
  )


# Segundas dosis -----------------------------------------------------------

dosis2 <- vacunas %>%
  filter(dosis == 2) %>%
  group_by(fecha_vacunacion) %>%
  summarise(
    n = sum(n_reg, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  arrange(fecha_vacunacion) %>%
  mutate(
    n_ac = cumsum(n),
    tramo = trunc(n_ac / 1e6),
    n_days = as.integer(fecha_vacunacion - min(fecha_vacunacion))
  )

max_fechavac2 <- max(dosis2$fecha_vacunacion)

markers_2 <- dosis2 %>%
  group_by(tramo) %>%
  summarise(
    fecha = min(fecha_vacunacion),
    n_ac = min(n_ac),
    dias = min(n_days)
  ) %>%
  ungroup() %>%
  mutate(
    tramo_lbl = glue::glue(
      "{format({as.integer(tramo) * 1000000L}, big.mark = ',', format = 'd', trim = TRUE)} - {format({as.integer(tramo + 1) * 1000000L}, big.mark = ',', format = 'd', trim = TRUE)}"
    ),
    fecha_next = lead(fecha),
    fecha_next = replace_na(fecha_next, max_fechavac2),
    dias_diff = as.numeric(fecha_next - fecha),
    fecha_middle = fecha + (dias_diff / 2)
  )

p2 <- ggplot(
  markers_2 %>% slice(-nrow(markers_2))
) +
  geom_dumbbell(
    aes(y = tramo_lbl, x = fecha, xend = fecha_next),
    colour_x = "green",
    colour_xend = "black",
    size_x = 4,
    size_xend = 4,
    size = 2,
    dot_guide = TRUE,
    dot_guide_colour = "gray70",
    dot_guide_size = 1
  ) +
  geom_text(
    aes(
      y = tramo_lbl,
      x = fecha_middle,
      label = glue::glue("{dias_diff} días")
    ),
    nudge_y = 0.15,
    size = 6
  ) +
  annotate(
    geom = "text",
    label = "Segunda dosis",
    size = 12,
    x = as.Date("2021-07-01"),
    y = 2.5
  ) +
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b"
  ) +
  theme_classic() +
  labs(
    x = "",
    y = ""
  ) +
  theme(
    axis.text = element_text(size = 14)
  )




# Combinados --------------------------------------------------------------

p12 <- (p1 + p2) +
  plot_annotation(
    title = "COVID-19, Perú: Cuánto tiempo ha tomado el vacunar cada millón de personas",
    subtitle = "Fuente de datos: MINSA",
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  ) &
  theme(
    plot.title.position = "plot",
    plot.title = element_text(size = 32),
    plot.subtitle = element_text(size = 24, color = "grey40"),
    plot.caption = element_text(family = "Inconsolata", size = 16)
  )

ggsave(
  p12,
  filename = "plots/hitos-vacunados-por-dosis.png",
  width = 22,
  height = 10
)
