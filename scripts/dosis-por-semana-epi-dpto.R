library(tidyverse)
library(patchwork)

vacunas <- readRDS("datos/vacunas_covid_aumentada.rds") %>%
  group_by(
    epi_week, departamento, fabricante, dosis
  ) %>%
  summarise(
    n_reg = n(),
    min_date = min(fecha_vacunacion),
    max_date = max(fecha_vacunacion)
  ) %>%
  ungroup() %>%
  mutate(
    dosis = glue::glue("Dosis: {dosis}")
  )

d1 <- vacunas %>% filter(dosis == "Dosis: 1")

p1 <- ggplot(
  d1,
  aes(x = min_date, y = n_reg, fill = fabricante)
) +
  geom_col(width = 7) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  scale_y_continuous(labels = scales::comma, n.breaks = 7) +
  scale_fill_brewer(palette = "Dark2", type = "qual") +
  facet_wrap(~departamento, scales = "free_y") +
  labs(
    x = "",
    y = "Primeras dosis aplicadas",
    fill = "Fabricante: "
  )

d2 <- vacunas %>% filter(dosis == "Dosis: 2")

p2 <- ggplot(
  d2,
  aes(x = min_date, y = n_reg, fill = fabricante)
) +
  geom_col(width = 7) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  scale_y_continuous(labels = scales::comma, n.breaks = 7) +
  scale_fill_brewer(palette = "Dark2", type = "qual") +
  facet_wrap(~departamento, scales = "free_y") +
  labs(
    x = "",
    y = "Segundas dosis aplicadas",
    fill = "Fabricante: "
  )

max_date_dataset <- max(vacunas$max_date)

p12 <- (p1 / p2) +
  plot_layout(
    guides = "collect"
  ) +
  plot_annotation(
    title = "Vacunación COVID-19 en Perú: Dosis aplicadas por semana",
    subtitle = glue::glue("Fuente: Datos abiertos del MINSA (datos al {max_date_dataset})"),
    caption = "@jmcastagnetto, Jesus M. Castagnetto"
  ) &
  theme_minimal(20) &
    theme(
      plot.background = element_rect(fill = "white", color = "white"),
      plot.title = element_text(size = 40),
      plot.subtitle = element_text(color = "grey50", size = 28),
      plot.caption = element_text(family = "Inconsolata", size = 26),
      axis.title.y = element_text(size = 26, face = "bold", hjust = 1),
      legend.position = "top"
    )
p12

ggsave(
  p12,
  filename = "plots/dosis-por-semana-epi-dpto.png",
  height = 28,
  width = 24
)

lima_callao <- vacunas %>%
  filter(departamento %in% c("LIMA", "CALLAO"))

plc <- ggplot(
  lima_callao,
  aes(x = min_date, y = n_reg, fill = fabricante)
) +
  geom_col(width = 7) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  scale_y_continuous(labels = scales::comma, n.breaks = 7) +
  scale_fill_brewer(palette = "Dark2", type = "qual") +
  facet_grid(departamento~dosis, scales = "free_y") +
  labs(
    x = "",
    y = "Dosis aplicadas",
    fill = "Fabricante: ",
    title = "Vacunación COVID-19 en Perú: Dosis aplicadas por semana en Lima y Callao",
    subtitle = glue::glue("Fuente: Datos abiertos del MINSA (datos al {max_date_dataset})"),
    caption = "@jmcastagnetto, Jesus M. Castagnetto"
  ) +
  theme_minimal(18) +
  theme(
    plot.background = element_rect(fill = "white", color = "white"),
    plot.title = element_text(size = 26),
    plot.subtitle = element_text(color = "grey50", size = 20),
    plot.caption = element_text(family = "Inconsolata", size = 20),
    axis.title.y = element_text(size = 20, face = "bold", hjust = 1),
    legend.position = "top"
  )
plc

ggsave(
  plc,
  filename = "plots/dosis-por-semana-epi-lima-callao.png",
  height = 14,
  width = 16
)
