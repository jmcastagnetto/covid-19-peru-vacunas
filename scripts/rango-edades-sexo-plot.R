library(tidyverse)
library(patchwork)

pob2020_df <- readRDS("datos/inei-estimado-pob2020-edad-sexo.rds") %>%
  mutate(
    n = if_else(sexo == "Masculino", -1*n, n),
    hjust = if_else(sexo == "Masculino", 1.1, -0.1)
  )
p0 <- ggplot(
  pob2020_df,
  aes(x = n, y = rango_edad2,
      group = sexo)
) +
  geom_col(aes(fill = sexo)) +
  geom_label(
    aes(label = str_trim(format(abs(n), big.mark = ",")),
        hjust = hjust,
        color = sexo),
    size = 6,
    show.legend = FALSE,
    fontface = "bold", label.size = 0
  ) +
  scale_x_continuous(
    expand = expansion(add = 1e6)
  ) +
  scale_fill_brewer(palette = "Set1",
                    type = "qual",
                    guide = guide_legend(reverse = TRUE)) +
  scale_color_manual(
    values = c("Masculino" = "#377eb8", "Femenino" = "#e41a1c")
  ) +
  labs(
    fill = "Sexo:",
    x = "",
    y = "",
    title = "Perú: Población al 2020 por grupo etáreo y sexo",
    subtitle = "Fuente: Estimaciones poblacionales del INEI"
  ) +
  ggthemes::theme_hc(
    base_family = "Roboto",
    base_size = 24
  ) +
  theme(
    plot.title.position = "plot",
    legend.position = "top",
    plot.subtitle = element_text(size = 20, color = "grey50"),
    strip.text = element_text(face = "bold"),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.spacing.x = unit(2, "lines"),
    plot.margin = unit(rep(.5, 4), "cm")
  )

vacunas <- readRDS("datos/vacunas_covid_aumentada.rds") %>%
  mutate(
    sexo = str_to_title(sexo)
  )

min_date <- min(vacunas$fecha_vacunacion, na.rm = TRUE)
max_date <- max(vacunas$fecha_vacunacion, na.rm = TRUE)
fabs <- paste(unique(vacunas$fabricante), collapse = ", ")

por_sexo_edad <- vacunas %>%
  group_by(dosis, sexo, rango_edad2) %>%
  tally() %>%
  ungroup() %>%
  mutate(
    n = if_else(sexo == "Masculino", as.integer(-1*n), n),
    hjust = if_else(sexo == "Masculino", 1.1, -0.1),
    dosis_lbl = if_else(dosis == 1, "Primera dosis", "Segunda dosis")
  )

max_val <- 1.5*max(abs(por_sexo_edad$n))

p1 <- ggplot(
  por_sexo_edad,
  aes(x = n, y = rango_edad2,
      group = sexo)
) +
  geom_col(aes(fill = sexo)) +
  geom_label(
    aes(label = str_trim(format(abs(n), big.mark = ",")),
        hjust = hjust,
        color = sexo),
    size = 6,
    show.legend = FALSE,
    fontface = "bold", label.size = 0
  ) +
  scale_x_continuous(
     limits = c(-max_val, max_val),
     expand = expansion(add = 1e5)
  ) +
  scale_fill_brewer(palette = "Set1",
                    type = "qual",
                    guide = guide_legend(reverse = TRUE)) +
  scale_color_manual(
    values = c("Masculino" = "#377eb8", "Femenino" = "#e41a1c")
  ) +
  facet_wrap(~dosis_lbl) +
  labs(
    fill = "Sexo:",
    x = "Número de personas vacunadas",
    y = "",
    title = glue::glue("Vacunados por COVID-19 en Perú (del {min_date} al {max_date})"),
    subtitle = glue::glue("Agrupados por número de dosis, grupo etáreo y sexo. Fabricantes de vacunas: {fabs} // Fuente: MINSA")
  ) +
  ggthemes::theme_hc(
    base_family = "Roboto",
    base_size = 24
  ) +
  theme(
    plot.title.position = "plot",
    legend.position = "top",
    plot.subtitle = element_text(size = 20, color = "grey50"),
    strip.text = element_text(face = "bold"),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.spacing.x = unit(2, "lines"),
    plot.margin = unit(rep(.5, 4), "cm")
  )

p01 <- (p0 / p1) +
  plot_annotation(
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  ) &
  theme(
    plot.caption = element_text(family = "Inconsolata", size = 24),
  )

ggsave(
  plot = p01,
  filename = "plots/vacunados-sexo-rango-edad.png",
  width = 25,
  height = 22
)


# Gráfico anterior --------------------------------------------------------

# hrbrthemes::import_roboto_condensed()
#
# p1 <- ggplot(
#   por_sexo_edad,
#   aes(x = n, y = rango_edad,
#       group = sexo,
#       color = rango_edad,
#       fill = rango_edad)
# ) +
#   geom_col(show.legend = FALSE) +
#   hrbrthemes::scale_fill_ipsum() +
#   scale_x_continuous(labels = scales::comma) +
#   facet_wrap(~sexo, scales = "free_x") +
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
#   group_by(sexo) %>%
#   tally() %>%
#   mutate(
#     Porcentaje = sprintf("%.1f%%", 100 * n / sum(n)),
#     Personas = format(n, big.mark = ",")
#   ) %>%
#   select(sexo, Personas, Porcentaje) %>%
#   rename(
#     Sexo = sexo
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
