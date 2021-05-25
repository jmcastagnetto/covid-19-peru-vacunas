library(tidyverse)

por_dpto <- data_df %>%
  group_by(dpto, dosis) %>%
  arrange(periodo) %>%
  mutate(
    n_total = sum(cantidad),
    n_acum = cumsum(cantidad)
  ) %>%
  ungroup() %>%
  mutate(
    dpto = str_replace_all(dpto, "_", " ")
  )

dosis1 <- por_dpto %>%
  filter(dosis == "DOSIS 1")

dosis2 <- por_dpto %>%
  filter(dosis == "DOSIS 2")

Sys.setlocale("LC_TIME", "es_PE.utf8")
p1 <- ggplot(dosis1, aes(x = periodo, y = n_acum)) +
  geom_step(direction = "hv") +
  geom_col(aes(y = cantidad, fill = nombre), position = "stack") +
  scale_y_continuous(labels = scales::comma) +
  scale_fill_brewer(type = "qual", palette = "Dark2") +
  facet_wrap(~dpto, scales = "free_y") +
  labs(
    fill = "",
    x = "",
    y = "Número de vacunas",
    title = "Distribución de vacunas COVID-19 a las regiones (Dosis 1)",
    subtitle = glue::glue("Fuente: CENARES (https://mvc.cenares.gob.pe/sic/Vacuna/MapaVacuna3) - del {min(dosis1$periodo)} al {max(dosis1$periodo)}"),
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto, {Sys.Date()}")
  ) +
  guides(
    fill = guide_legend(direction = "horizontal")
  ) +
  theme_bw(base_size = 14) +
  theme(
    legend.position = c(.7, .1),
    plot.title.position = "plot",
    plot.title = element_text(size = 32),
    plot.subtitle = element_text(size = 24, color = "grey40"),
    plot.caption = element_text(family = "Inconsolata", size = 20)
  )

p2 <- ggplot(dosis2, aes(x = periodo, y = n_acum)) +
  geom_step(direction = "hv") +
  geom_col(aes(y = cantidad, fill = nombre), position = "stack") +
  scale_y_continuous(labels = scales::comma) +
  scale_fill_brewer(type = "qual", palette = "Dark2") +
  facet_wrap(~dpto, scales = "free_y") +
  labs(
    fill = "",
    x = "",
    y = "Número de vacunas",
    title = "Distribución de vacunas COVID-19 a las regiones (Dosis 2)",
    subtitle = glue::glue("Fuente: CENARES (https://mvc.cenares.gob.pe/sic/Vacuna/MapaVacuna3) - del {min(dosis2$periodo)} al {max(dosis2$periodo)}"),
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto, {Sys.Date()}")
  ) +
  guides(
    fill = guide_legend(direction = "horizontal")
  ) +
  theme_bw(base_size = 14) +
  theme(
    legend.position = c(.7, .1),
    plot.title.position = "plot",
    plot.title = element_text(size = 32),
    plot.subtitle = element_text(size = 24, color = "grey40"),
    plot.caption = element_text(family = "Inconsolata", size = 20)
  )


ggsave(
  plot = p1,
  filename = "plots/dosis1_distribucion_a_regiones.png",
  width = 16,
  height = 10
)

ggsave(
  plot = p2,
  filename = "plots/dosis2_distribucion_a_regiones.png",
  width = 16,
  height = 10
)
