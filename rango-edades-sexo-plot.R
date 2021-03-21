library(tidyverse)
library(patchwork)
library(ggcharts)

vacunas <- readRDS("datos/vacunas_covid.rds") %>%
  mutate(
    SEXO = str_to_title(SEXO)
  )

min_date <- min(vacunas$FECHA_VACUNACION, na.rm = TRUE)
max_date <- max(vacunas$FECHA_VACUNACION, na.rm = TRUE)
fabs <- paste(unique(vacunas$FABRICANTE), collapse = ", ")


por_sexo_edad <- vacunas %>%
  group_by(DOSIS, SEXO, rango_edad2) %>%
  tally() %>%
  ungroup() %>%
  mutate(
    n = if_else(SEXO == "Masculino", as.integer(-1*n), n),
    hjust = if_else(SEXO == "Masculino", 1.1, -0.1),
    dosis_lbl = if_else(DOSIS == 1, "Primera dosis", "Segunda dosis")
  )

# xbreaks = seq(-1e5, 1e5, by = .5e5)
# xlabels = str_trim(format(abs(xbreaks), big.mark = ","))

p1 <- ggplot(
  por_sexo_edad,
  aes(x = n, y = rango_edad2,
      group = SEXO,
      fill = SEXO)
) +
  geom_col() +
  geom_label(
    aes(label = str_trim(format(abs(n), big.mark = ",")),
        hjust = hjust,
        color = SEXO),
    show.legend = FALSE,
    fontface = "bold", label.size = 0
  ) +
  scale_x_continuous(
     limits = c(-.9e5, .9e5),
  #   breaks = xbreaks,
  #   labels = xlabels
  ) +
  scale_fill_brewer(palette = "Paired",
                    type = "qual",
                    guide = guide_legend(reverse = TRUE)) +
  scale_color_manual(
    values = c("Masculino" = "white", "Femenino" = "black")
  ) +
  facet_wrap(~dosis_lbl) +
  labs(
    fill = "Sexo:",
    x = "Número de personas vacunadas",
    y = "",
    title = glue::glue("Vacunados por COVID-19 en Perú (del {min_date} al {max_date})"),
    subtitle = glue::glue("Agrupados por número de dosis, grupo etáreo y sexo. Fabricantes de vacunas: {fabs}"),
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  ) +
  ggthemes::theme_hc(
    base_family = "Roboto",
    base_size = 24
  ) +
  theme(
    plot.title.position = "plot",
    plot.caption = element_text(family = "Inconsolata"),
    legend.position = "top",
    plot.subtitle = element_text(size = 20, color = "grey50"),
    strip.text = element_text(face = "bold"),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.spacing.x = unit(2, "lines"),
    plot.margin = unit(rep(.5, 4), "cm")
  )

ggsave(
  plot = p1,
  filename = "plots/vacunados-sexo-rango-edad.png",
  width = 16,
  height = 10
)


# Gráfico anterior --------------------------------------------------------

# hrbrthemes::import_roboto_condensed()
#
# p1 <- ggplot(
#   por_sexo_edad,
#   aes(x = n, y = rango_edad,
#       group = SEXO,
#       color = rango_edad,
#       fill = rango_edad)
# ) +
#   geom_col(show.legend = FALSE) +
#   hrbrthemes::scale_fill_ipsum() +
#   scale_x_continuous(labels = scales::comma) +
#   facet_wrap(~SEXO, scales = "free_x") +
#   hrbrthemes::theme_ipsum_rc(
#     plot_title_size = 32
#   ) +
#   labs(
#     y = "Rango etáreo (años)",
#     x = "Número de personas",
#     title = glue::glue("Vacunados por rango etáreo en el Perú al {max_date}"),
#     subtitle = "Primera dosis, Sinopharm - agrupados por sexo y rango de edades",
#     caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
#   ) +
#   theme(
#     plot.title.position = "plot",
#     plot.caption = element_text(family = "Inconsolata", size = 14),
#     plot.subtitle = element_text(size = 20),
#     axis.title.x = element_text(size = 16),
#     axis.title.y = element_text(size = 16),
#     strip.text = element_text(size = 20),
#   )
#
# tab_df <- vacunas %>%
#   group_by(SEXO) %>%
#   tally() %>%
#   mutate(
#     Porcentaje = sprintf("%.1f%%", 100 * n / sum(n)),
#     Personas = format(n, big.mark = ",")
#   ) %>%
#   select(SEXO, Personas, Porcentaje) %>%
#   rename(
#     Sexo = SEXO
#   )
#
# df <- tibble(
#   x = .8, y = .2, tb = list(tab_df)
# )
#
# p2 <- ggplot() +
#   ggpmisc::geom_table(
#     data = df,
#     aes(x = x, y = y, label = tb),
#     size = 5
#   ) +
#   theme_void()
#
# p3 <- p1 +
#   inset_element(p2, left = .8, right = .9, bottom = 1.1, top = 1.25)
#
# ggsave(
#   plot = p3,
#   filename = "plots/vacunados-sexo-rango-edad.png",
#   width = 16,
#   height = 10
# )
