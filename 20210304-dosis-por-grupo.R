library(tidyverse)
library(magick)
library(cowplot)

vacunas <- readRDS("datos/vacunas_covid.rds")

segunda_dosis <- vacunas %>%
  filter(DOSIS == 2) %>%
  distinct() %>%
  pull(UUID)

persona_grupo <- vacunas %>%
  select(UUID, GRUPO_RIESGO) %>%
  mutate(
    n_dosis = if_else(UUID %in% segunda_dosis,
                      "Dos dosis", "Una dosis") %>%
      factor(levels = c("Una dosis", "Dos dosis"), ordered = TRUE)
  ) %>%
  group_by(GRUPO_RIESGO, n_dosis) %>%
  tally() %>%
  ungroup() %>%
  group_by(GRUPO_RIESGO) %>%
  mutate(n_grp = sum(n)) %>%
  ungroup() %>%
  mutate(pct = n_grp / sum(n)) %>%
  mutate(
    GRUPO_RIESGO = fct_reorder(GRUPO_RIESGO, pct)
  ) %>%
  arrange(n_dosis, GRUPO_RIESGO)

vacuna_bg <- image_read("misc/1024px-Pfizer-BioNTech_COVID-19_vaccine_(2020)_F.jpg") %>%
  image_colorize(70, "white")

p1 <- ggplot(
  persona_grupo,
  aes(y = GRUPO_RIESGO, x = n, group = GRUPO_RIESGO)
) +
  geom_col(aes(fill = n_dosis)) +
  geom_text(
    data = persona_grupo %>% select(GRUPO_RIESGO, n_grp, pct) %>% distinct(),
    aes(x = n_grp, label = sprintf("%.2f%%\n(N = %s)",
                                   pct * 100,
                                   str_trim(format(n_grp, big.mark = ",")))
        ),
    nudge_x = 23000,
    size = 5
  ) +
  scale_fill_brewer(palette = "Paired", direction = -1) +
  scale_x_continuous(labels = scales::comma, expand = expansion(add = c(0, .1))) +
  annotate(
    geom = "label",
    label = "Perú (COVID-19):\nVacunados  por grupo y cantidad de dosis\nDel 2021-02-09 al 2021-03-03",
    x = 2e5,
    y = 6,
    size = 8.5,
    label.size = 0,
    family = "Arial",
    fontface = "bold",
    fill = NA
  ) +
  labs(
    fill = "",
    y = "",
    x = "",
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  ) +
  ggthemes::theme_tufte(20, base_family = "Cantarell") +
  theme(
    legend.position = c(.8, .2),
    legend.text = element_text(size = 18),
    axis.text.x = element_blank(),
    axis.text.y = element_text(face = "bold"),
    axis.ticks.x = element_blank(),
    plot.caption = element_text(family = "Inconsolata"),
    plot.margin = unit(rep(.5, 4), "cm")
  )

p2 <- ggdraw() +
  draw_image(
    vacuna_bg,
    scale = 1.2,
    clip = TRUE
  ) +
  draw_plot(p1)
#p2

ggsave(
  plot = p2,
  filename = "plots/20210304-vacunados-grupo-dosis.png",
  width = 16,
  height = 9
)
