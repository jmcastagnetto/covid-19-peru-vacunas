library(tidyverse)
library(patchwork)

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
    tramo = trunc(n_ac / 5e5),
    n_days = as.integer(fecha_vacunacion - min(fecha_vacunacion))
  )

markers_1 <- dosis1 %>%
  group_by(tramo) %>%
  summarise(
    fecha = min(fecha_vacunacion),
    n_ac = min(n_ac),
    dias = min(n_days)
  )

inicio <- min(dosis1$fecha_vacunacion)

p1 <- ggplot() +
  geom_line(
    data = dosis1,
    aes(x = fecha_vacunacion, y = n_ac),
    size = 1
  ) +
  geom_point(
    data = markers_1 %>% filter(tramo > 0),
    aes(x = fecha, y = n_ac),
    color = "blue"
  ) +
  geom_segment(
    data = markers_1 %>% filter(tramo > 0),
    aes(x = fecha, y = 0,
        xend = fecha, yend = n_ac),
    linetype = "dashed",
    color = "gray70"
  ) +
  geom_segment(
    data = markers_1 %>% filter(tramo > 0),
    aes(x = inicio,
        y = n_ac,
        xend = fecha,
        yend = n_ac),
    linetype = "dashed",
    color = "gray70"
  ) +
  ggforce::geom_mark_circle(
    data = markers_1 %>% filter(tramo > 0),
    aes(x = fecha, y = n_ac, group = tramo,
        label = glue::glue("{str_trim(format(n_ac, big.mark = ','))}\npersonas\nen {dias} días")),
    color = "blue",
    con.cap = 0,
    con.colour = "blue",
    expand = unit(2, "mm")
  ) +
  geom_text(
    aes(x = as.Date("2021-03-15"), y = 2.5e6),
    label = "Primera dosis",
    size = 10,
    hjust = 0
  ) +
  scale_y_continuous(
    labels = scales::comma,
    n.breaks = 10,
    limits = c(0, 5e6)
  ) +
  ggthemes::theme_tufte(base_size = 16) +
  labs(
    x = "",
    y = ""
  )

# Segunda dosis -----------------------------------------------------------

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
    tramo = trunc(n_ac / 5e5),
    n_days = as.integer(fecha_vacunacion - min(fecha_vacunacion))
  )

markers_2 <- dosis2 %>%
  group_by(tramo) %>%
  summarise(
    fecha = min(fecha_vacunacion),
    n_ac = min(n_ac),
    dias = min(n_days)
  )

inicio2 <- min(dosis2$fecha_vacunacion)

p2 <- ggplot() +
  geom_line(
    data = dosis2,
    aes(x = fecha_vacunacion, y = n_ac),
    size = 1
  ) +
  geom_point(
    data = markers_2 %>% filter(tramo > 0),
    aes(x = fecha, y = n_ac),
    color = "blue"
  ) +
  geom_segment(
    data = markers_2 %>% filter(tramo > 0),
    aes(x = fecha, y = 0,
        xend = fecha, yend = n_ac),
    linetype = "dashed",
    color = "gray70"
  ) +
  geom_segment(
    data = markers_2 %>% filter(tramo > 0),
    aes(x = inicio2,
        y = n_ac,
        xend = fecha,
        yend = n_ac),
    linetype = "dashed",
    color = "gray70"
  ) +
  ggforce::geom_mark_circle(
    data = markers_2 %>% filter(tramo > 0),
    aes(x = fecha, y = n_ac, group = tramo,
        label = glue::glue("{str_trim(format(n_ac, big.mark = ','))}\npersonas\nen {dias} días")),
    color = "blue",
    con.cap = 0,
    con.colour = "blue",
    expand = unit(2, "mm")
  ) +
  scale_y_continuous(
    labels = scales::comma,
    n.breaks = 10,
    limits = c(0, 5e6)
  ) +
  geom_text(
    aes(x = as.Date("2021-03-15"), y = 2.5e6),
    label = "Segunda dosis",
    size = 10,
    hjust = 0
  ) +
  ggthemes::theme_tufte(base_size = 16) +
  labs(
    x = "",
    y = ""
  )


# Combinados --------------------------------------------------------------

p12 <- (p1 + p2) +
  plot_annotation(
    title = "COVID-19, Perú: Personas Vacunadas con Primera y Segunda Dosis",
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
  width = 24,
  height = 14
)
