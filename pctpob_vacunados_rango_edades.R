library(tidyverse)
library(lubridate)
Sys.setlocale("LC_TIME", "es_PE.utf8")
pe_rangoedad <- readRDS("datos/peru-pob2021-rango-etareo-deciles.rds") %>%
  select(rango, población) %>%
  mutate(
    rango = as.character(rango) %>%
      str_replace("80-mas", "80+")
  )

vacunas <- readRDS("datos/vacunas_covid_aumentada.rds")
min_date1 <- min(vacunas %>%
                   filter(dosis == 1) %>%
                   pull(fecha_vacunacion),
                 na.rm = TRUE)
max_date1 <- max(vacunas %>%
                   filter(dosis == 1) %>%
                   pull(fecha_vacunacion),
                 na.rm = TRUE)
min_date2 <- min(vacunas %>%
                   filter(dosis == 2) %>%
                   pull(fecha_vacunacion),
                 na.rm = TRUE)
max_date2 <- max(vacunas %>%
                   filter(dosis == 2) %>%
                   pull(fecha_vacunacion),
                 na.rm = TRUE)

vacunas_semana_rangoedad <- vacunas %>%
  mutate(
    semana = epiweek(fecha_vacunacion)
  ) %>%
  group_by(
    semana,
    rango_edad2,
    dosis
  ) %>%
  summarise(
    max_fecha = max(fecha_vacunacion),
    n = n()
  ) %>%
  ungroup() %>%
  group_by(
    rango_edad2,
    dosis
  ) %>%
  mutate(
    n_acum = cumsum(n),
    rango_edad2 = as.character(rango_edad2)
  ) %>%
  ungroup() %>%
  left_join(
    pe_rangoedad,
    by = c("rango_edad2" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / población
  )

p1 <- ggplot(
  vacunas_semana_rangoedad %>% filter(!is.na(pct_acum) & dosis == 1),
  aes(x = max_fecha, y = pct_acum, color = rango_edad2)
) +
  geom_line(size = 2, show.legend = FALSE) +
  geom_point(size = 3, show.legend = FALSE) +
  scale_y_continuous(
    labels = scales::percent,
    limits = c(0, NA),
    n.breaks = 5
  ) +
  scale_x_date(
    date_labels = "%b %d\nS: %V"
  ) +
  facet_wrap(~rango_edad2, scales = "free_y") +
  ggthemes::theme_few(20) +
  theme(
    panel.spacing = unit(2, "lines"),
    plot.caption = element_text(family = "Inconsolata"),
    plot.title.position = "plot"
  ) +
  labs(
    x = "",
    y = "",
    title = "Porcentaje de la población (por rango etáreo) vacunado contra COVID-19 en Perú (Primera dosis)",
    subtitle = glue::glue("Total semanal para todos los fabricantes, del {min_date1} al {max_date1}"),
    caption = "Fuente: Datos abiertos de vacunas COVID-19 y de población al 2021 del MINSA\n@jmcastagnetto, Jesus M. Castagnetto"
  )

p1a <- ggplot(
  vacunas_semana_rangoedad %>% filter(!is.na(pct_acum) & dosis == 1),
  aes(x = max_fecha, y = pct_acum, color = rango_edad2)
) +
  geom_line(size = 2, show.legend = FALSE) +
  geom_point(size = 3, show.legend = FALSE) +
  ggrepel::geom_label_repel(
    data = vacunas_semana_rangoedad %>%
      filter(!is.na(pct_acum) & dosis == 1) %>%
      group_by(rango_edad2) %>%
      summarise(
        xval = max(max_fecha),
        yval = max(pct_acum),
        lbl = glue::glue("{rango_edad2} ({sprintf('%.2f%%', 100 * yval)})")
      ) %>%
      distinct(),
    aes(x = xval, y = yval,
        label = lbl),
    label.size = 0,
    nudge_x = -30,
    seed = 10203,
    hjust = 1,
    size = 6,
    show.legend = FALSE
  ) +
  scale_y_continuous(
    labels = scales::percent,
    limits = c(0, NA),
    n.breaks = 5
  ) +
  scale_x_date(
    date_labels = "%b %d\nS: %V"#,
    #limits = c(as.Date("2021-02-08"), as.Date("2021-04-01"))
  ) +
  scale_color_brewer(type = "qual", palette = "Dark2") +
  ggthemes::theme_few(20) +
  theme(
    panel.spacing = unit(2, "lines"),
    plot.caption = element_text(family = "Inconsolata"),
    plot.title.position = "plot"
  ) +
  labs(
    x = "",
    y = "",
    title = "Porcentaje de la población (por rango etáreo) vacunado contra COVID-19 en Perú (Primera dosis)",
    subtitle = glue::glue("Total semanal para todos los fabricantes, del {min_date1} al {max_date1}"),
    caption = "Fuente: Datos abiertos de vacunas COVID-19 y de población al 2021 del MINSA\n@jmcastagnetto, Jesus M. Castagnetto"
  )

p1
ggsave(
  plot = p1,
  filename = "plots/pctpob_rangoedad_dosis1.png",
  width = 16,
  height = 11
)

ggsave(
  plot = p1a,
  filename = "plots/pctpob_rangoedad_dosis1_v2.png",
  width = 16,
  height = 11
)


p2 <- ggplot(
  vacunas_semana_rangoedad %>% filter(!is.na(pct_acum) & dosis == 2),
  aes(x = max_fecha, y = pct_acum, color = rango_edad2)
) +
  geom_line(size = 2, show.legend = FALSE) +
  geom_point(size = 3, show.legend = FALSE) +
  scale_y_continuous(
    labels = scales::percent,
    limits = c(0, NA),
    n.breaks = 5
  ) +
  scale_x_date(
    date_labels = "%b %d\nS: %V"
  ) +
  facet_wrap(~rango_edad2, scales = "free_y") +
  ggthemes::theme_few(20) +
  theme(
    panel.spacing = unit(2, "lines"),
    plot.caption = element_text(family = "Inconsolata"),
    plot.title.position = "plot"
  ) +
  labs(
    x = "",
    y = "",
    title = "Porcentaje de la población (por rango etáreo) vacunado contra COVID-19 en Perú (Segunda dosis)",
    subtitle = glue::glue("Total semanal para todos los fabricantes, del {min_date2} al {max_date2}"),
    caption = "Fuente: Datos abiertos de vacunas COVID-19 y de población al 2021 del MINSA\n@jmcastagnetto, Jesus M. Castagnetto"
  )

ggsave(
  plot = p2,
  filename = "plots/pctpob_rangoedad_dosis2.png",
  width = 16,
  height = 11
)

p2a <- ggplot(
  vacunas_semana_rangoedad %>% filter(!is.na(pct_acum) & dosis == 2),
  aes(x = max_fecha, y = pct_acum, color = rango_edad2)
) +
  geom_line(size = 2, show.legend = FALSE) +
  geom_point(size = 3, show.legend = FALSE) +
  ggrepel::geom_label_repel(
    data = vacunas_semana_rangoedad %>%
      filter(!is.na(pct_acum) & dosis == 2) %>%
      group_by(rango_edad2) %>%
      summarise(
        xval = max(max_fecha),
        yval = max(pct_acum),
        lbl = glue::glue("{rango_edad2} ({sprintf('%.2f%%', 100 * yval)})")
      ) %>%
      distinct(),
    aes(x = xval, y = yval,
        label = lbl),
    label.size = 0,
    nudge_x = 3,
    seed = 10203,
    hjust = 0,
    size = 6,
    show.legend = FALSE
  ) +
  scale_y_continuous(
    labels = scales::percent,
    limits = c(0, NA),
    n.breaks = 5
  ) +
  scale_x_date(
    date_labels = "%b %d\nS: %V",
    limits = c(as.Date("2021-03-01"), as.Date("2021-04-01"))
  ) +
  scale_color_brewer(type = "qual", palette = "Dark2") +
  ggthemes::theme_few(20) +
  theme(
    panel.spacing = unit(2, "lines"),
    plot.caption = element_text(family = "Inconsolata"),
    plot.title.position = "plot"
  ) +
  labs(
    x = "",
    y = "",
    title = "Porcentaje de la población (por rango etáreo) vacunado contra COVID-19 en Perú (Segunda dosis)",
    subtitle = glue::glue("Total semanal para todos los fabricantes, del {min_date2} al {max_date2}"),
    caption = "Fuente: Datos abiertos de vacunas COVID-19 y de población al 2021 del MINSA\n@jmcastagnetto, Jesus M. Castagnetto"
  )

ggsave(
  plot = p2a,
  filename = "plots/pctpob_rangoedad_dosis2_v2.png",
  width = 16,
  height = 11
)
