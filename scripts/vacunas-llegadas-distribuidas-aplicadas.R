library(tidyverse)
library(ggtext)
library(directlabels)
library(ggforce)

vacunas <- readRDS("datos/vacunas_covid_resumen.rds") %>%
  group_by(fecha_vacunacion) %>%
  summarise(
    n_dosis = sum(n_reg)
  ) %>%
  arrange(fecha_vacunacion) %>%
  mutate(
    dosis_acum = cumsum(n_dosis)
  )

vacunas_por_fabricante <- readRDS("datos/vacunas_covid_resumen.rds") %>%
  group_by(fecha_vacunacion, fabricante) %>%
  summarise(
    n_dosis = sum(n_reg)
  ) %>%
  ungroup() %>%
  arrange(fabricante, fecha_vacunacion) %>%
  group_by(fabricante) %>%
  mutate(
    dosis_acum = cumsum(n_dosis)
  )

distribuidas <- readRDS("datos/vacunas_covid_distribucion.rds") %>%
  group_by(periodo) %>%
  summarise(
    n_vac = sum(cantidad)
  ) %>%
  ungroup() %>%
  mutate(
    n_acum = cumsum(n_vac)
  )


round_any = function(x, accuracy, f=round){f(x/ accuracy) * accuracy}

plot_df <- read_csv("datos/covid19_vaccine_arrivals_peru.csv") %>%
  mutate(
    cantidad_acumulada = cumsum(cantidad),
    col_lbl = if_else(
      covax,
      glue::glue("{farmaceutica} (COVAX)"),
      glue::glue("{farmaceutica}")
    )
  )

last_df <- tibble(
  label = c("Llegaron", "Distribuidas", "Aplicadas"),
  x = c(
    max(plot_df$fecha_de_llegada),
    max(distribuidas$periodo),
    max(vacunas$fecha_vacunacion)
  ),
  y = c(
    max(plot_df$cantidad_acumulada),
    max(distribuidas$n_acum),
    max(vacunas$dosis_acum)
  ),
  label_color = c("black", "darkmagenta", "darkgreen" )
) %>%
  mutate(
    description = glue::glue("{format(y, big.mark = ',')} dosis\nal {x}")
  )



max_y <- max(plot_df$cantidad_acumulada) * 1.2

max_date <- max(plot_df$fecha_de_llegada, vacunas$fecha_vacunacion)
min_date <- min(plot_df$fecha_de_llegada, vacunas$fecha_vacunacion)
vac_apl <- max(vacunas$dosis_acum)
vac_arr <- max(plot_df$cantidad_acumulada)
vac_dist <- max(distribuidas$n_acum)


Sys.setlocale("LC_TIME", "es_PE.utf8")
p1 <- ggplot() +
  geom_area(
    data = vacunas_por_fabricante,
    aes(x = fecha_vacunacion, y = dosis_acum, fill = fabricante)
  ) +
  geom_line(
    data = vacunas,
    aes(x = fecha_vacunacion, y = dosis_acum),
    size = 1,
    color = "darkgreen"
  ) +
  # geom_mark_circle(
  #   data = vacunas %>% tail(1),
  #   aes(
  #     x = fecha_vacunacion,
  #     y = dosis_acum,
  #     label = "Aplicadas",
  #     description = glue::glue(
  #       "{format(dosis_acum, big.mark = ',')} dosis"
  #     )
  #   ),
  #   label.colour = "darkgreen",
  #   color = "black",
  #   expand = unit(1, "mm")
  # ) +
  geom_step(
    data = distribuidas,
    aes(x = periodo, y = n_acum),
    direction = "vh",
    size = 1,
    color = "darkmagenta"
  ) +
  # geom_mark_circle(
  #   data = distribuidas %>% tail(1),
  #   aes(
  #     x = periodo,
  #     y = n_acum,
  #     label = "Distribuidas",
  #     description = glue::glue(
  #       "{format(n_acum, big.mark = ',')} dosis"
  #     )
  #   ),
  #   label.colour = "darkmagenta",
  #   color = "black",
  #   expand = unit(1, "mm")
  # ) +
  geom_step(
    data = plot_df,
    aes(x = fecha_de_llegada, y = cantidad_acumulada),
    direction = "vh",
    size = 1
  ) +
  # geom_mark_circle(
  #   data = plot_df %>% tail(1),
  #   aes(
  #     x = fecha_de_llegada,
  #     y = cantidad_acumulada,
  #     label = "Llegaron",
  #     description = glue::glue(
  #       "{format(cantidad_acumulada, big.mark = ',')} dosis"
  #     )
  #   ),
  #   label.colour = "black",
  #   color = "black",
  #   expand = unit(1, "mm")
  # ) +
  geom_mark_circle(
    data = last_df,
    aes(
      x = x,
      y = y,
      label = label,
      description = description,
    ),
    label.colour = c("blue", "black"),
    label.fill = rgb(.9, .9, .9, .7),
    color = "black",
    expand = unit(1, "mm")
  ) +
  scale_y_continuous(labels = scales::comma) + #, limits = c(0, max_y)) +
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b"#,
    #limits = c(min_date, max_date + 45)
  ) +
  scale_fill_manual(
    values = c("#bae4b3", "#74c476", "#238b45")
  ) +
  labs(
    x = "",
    y = "Número de dosis",
    title = "COVID-19: Vacunación en Perú - Dosis que llegaron, se distribuyeron y aplicaron",
    subtitle = glue::glue("Fuentes: MINSA, CENARES y Wikipedia. Datos al {max_date}."),
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto, {Sys.Date()}"),
    fill = "Fabricante de la\nvacuna aplicada"
  ) +
  theme_classic(base_size = 18) +
  theme(
    plot.title.position = "plot",
    plot.title = element_text(size = 28),
    plot.subtitle = element_text(size = 22, color = "grey40"),
    plot.caption = element_text(family = "Inconsolata", size = 18),
    legend.position = c(.4, .7),
    legend.key.height = unit(1, "cm")
  )


ggsave(
  plot = p1,
  filename = "plots/covid19-peru-vacunas-llegadas-distribuidas-aplicadas.png",
  width = 20,
  height = 12
)



