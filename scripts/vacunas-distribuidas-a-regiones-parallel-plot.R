library(tidyverse)
library(ggforce)

vacunas_dist <- readRDS("datos/vacunas_covid_distribucion.rds") %>%
  group_by(
    dpto, nombre, dosis
  ) %>%
  summarise(
    n_vacunas = sum(cantidad)
  ) %>%
  ungroup() %>%
  mutate(
    nombre = str_replace_all(
      nombre,
      c(
        "SINOPHARM" = "SP",
        "PFIZER" = "PB",
        "ASTRAZENECA" = "AZ"
      )
    ),
    dosis = str_replace_all(
      dosis,
      c(
        "DOSIS 1" = "D1",
        "DOSIS 2" = "D2"
      )
    )
  )

por_dtpo <- vacunas_dist %>%
  group_by(dpto) %>%
  summarise(
    total = sum(n_vacunas)
  ) %>%
  mutate(
    lbl = glue::glue("{dpto} ({str_trim(format(total, big.mark = ','))})")
  )

repl_str <- structure(
  as.character(por_dtpo$lbl),
  names = as.character(glue::glue("^{por_dtpo$dpto}$"))
)

plot_df <- vacunas_dist %>%
  mutate(
    dpto = str_replace_all(dpto, repl_str) %>%
      str_replace_all("_", " ")
  ) %>%
  gather_set_data(1:3)

p1 <- ggplot(
  plot_df,
  aes(x, id = id, split = y, value = n_vacunas)
) +
  geom_parallel_sets(aes(fill = nombre),
                     alpha = 0.5,
                     axis.width = 0.1) +
  geom_parallel_sets_axes(axis.width = .35) +
  geom_parallel_sets_labels(angle = 0, size = 3.5, color = "white") +
  scale_y_continuous(labels = scales::comma, n.breaks = 3) +
  scale_fill_brewer(
    name = "Fabricante",
    palette = "Set1",
    type = "qual",
    labels = c("AZ" = "AZ: Astra/Zeneca", "SP" = "SP: Sinopharm", "PB" = "PB: Pfizer/BioNtech")
  ) +
  guides(
    fill = guide_legend(direction = "horizontal")
  ) +
  coord_flip() +
  facet_wrap(~dpto, scales = "free") +
  theme_void() +
  theme(
    legend.position = c(.75, .1),
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 16, face = "italic"),
    strip.text = element_blank(),
    strip.background = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    plot.title.position = "plot",
    plot.title = element_text(size = 28),
    plot.subtitle = element_text(size = 20, color = "grey40"),
    plot.caption = element_text(family = "Inconsolata", size = 20),
    plot.margin = unit(rep(.5, 4), "cm"),
    panel.spacing = unit(.5, "cm")
  ) +
  labs(
    title = "COVID19 (Perú): Vacunas distribuidas por regiones, fabricante y dosis de vacunación",
    subtitle = "D1: primera dosis, D2: segunda dosis - Fuente: CENARES (https://mvc.cenares.gob.pe/sic/Vacuna/MapaVacuna3)",
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto, {Sys.Date()}")
  )

ggsave(
  plot = p1,
  filename = "plots/covid19_vacunas_distribucion_a_regiones-parallel_plot.png",
  width = 18,
  height = 12
)
