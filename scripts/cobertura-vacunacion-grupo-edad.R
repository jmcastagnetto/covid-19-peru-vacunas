library(tidyverse)
library(ggrepel)

por_rango <- readRDS("datos/vacunas_covid_rangoedad_deciles.rds") %>%
  filter(rango_edad != "Desconocido") %>%
  mutate(
    dosis_lbl = if_else(
      dosis == 1,
      "Con una dosis",
      "Con dos dosis"
    ) %>%
      factor(
        levels = c("Con una dosis", "Con dos dosis"),
        ordered = TRUE
      )
  )

line_lbls <- por_rango %>%
  select(date, pct_acum, rango_edad, dosis_lbl) %>%
  filter(date == max(date))
fecha_corte <- unique(por_rango$fecha_corte)

p1 <- ggplot(
  por_rango,
  aes(x = date, y = pct_acum,
      group = rango_edad, color = rango_edad)
) +
  geom_line(size = 1) +
  geom_text_repel(
    data = line_lbls,
    aes(x = date, y = pct_acum, label = rango_edad,
        group = rango_edad, color = rango_edad),
    hjust = 0,
    nudge_x = 5,
    size = 6,
    direction = "both"
  ) +
  scale_y_continuous(labels = scales::percent) +
  scale_x_date(date_breaks = "1 month",
               date_labels = "%b",
               expand = expansion(add = c(0, 30))) +
  scale_color_brewer(palette = "Dark2", type = "qual") +
  facet_wrap(~dosis_lbl) +
  theme_linedraw(18) +
  theme(
    legend.position = "none",
    strip.text = element_text(size = 20, face = "bold"),
    plot.title = element_text(size = 30),
    plot.subtitle = element_text(color = "gray50"),
    plot.caption = element_text(family = "Inconsolata")
  ) +
  labs(
    x = "",
    y = "Porcentaje de población cubierta",
    title = "COVID-19: Cobertura de vacunación en Perú por grupos de edad",
    subtitle = glue::glue("Fuentes: MINSA e INEI - Datos al {fecha_corte}"),
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  )

ggsave(
  p1,
  filename = "plots/cobertura-vacunacion-grupo-edad.png",
  width = 16,
  height = 9
)
