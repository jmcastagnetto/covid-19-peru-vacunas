library(tidyverse)
library(ggtext)
library(tidytext)

pob <- readRDS("datos/peru-poblacion2021-departamentos.rds")

vac <- readRDS("datos/vacunas_covid_aumentada.rds") %>%
  group_by(departamento, dosis) %>%
  tally(name = "n_vacunas")

plot_df <- vac %>%
  left_join(
    pob,
    by = "departamento"
  ) %>%
  mutate(
    pct_pob = n_vacunas / pob2021,
    dosis = glue::glue("Dosis {dosis}")
  ) %>%
  group_by(dosis) %>%
  mutate(
    above_median = (pct_pob > median(pct_pob)),
    departamento = reorder_within(departamento, pct_pob, dosis)
  )

medians_df <- plot_df %>%
  group_by(dosis) %>%
  summarise(median = median(pct_pob)) %>%
  add_column(departamento = c("PASCO___Dosis 1", "PASCO___Dosis 2")) %>%
  add_column(x = c(.08, .05)) %>%
  mutate(
    lbl = glue::glue("**{dosis}**<br/><span style='color:grey40;'>Mediana: {sprintf('%.1f%%', median * 100)}</span>")
  )

p1 <- ggplot(
  plot_df,
  aes(x = pct_pob, y = departamento)
) +
  geom_col(aes(fill = above_median), show.legend = FALSE) +
  geom_vline(
    data = medians_df,
    aes(xintercept = median),
    linetype = "dashed",
    size = 1,
    color = "grey40"
  ) +
  geom_textbox(
    data = medians_df,
    aes(y = 10, x = x, label = lbl),
    size = 7,
    width = unit(3, "inches"),
    hjust = 0,
    nudge_y = .2,
    fill = NA,
    box.color = NA
  ) +
  scale_fill_manual(
    values = c("peru", "magenta")
  ) +
  scale_y_reordered() +
  scale_x_continuous(labels = scales::percent, limits = c(0, .15)) +
  facet_wrap(~dosis, scales = "free_y") +
  theme_bw(18) +
  theme(
    strip.text = element_blank(),
    plot.title.position = "plot",
    plot.title = element_text(size = 32),
    plot.subtitle = element_markdown(size = 24),
    plot.caption = element_text(family = "Inconsolata", size = 20),
    panel.spacing = unit(2, "cm"),
    plot.margin = unit(rep(.5, 4), "cm")
  ) +
  labs(
    x = "",
    y = "",
    title = "COVID-19 Perú: Porcentaje de la población vacunada por departamento",
    subtitle = "Departamentos **<span style='color:magenta;'>sobre</span>** la mediana y **<span style='color:peru;'>bajo</span>** la misma - *<span style='color:#999999;'>Fuentes: MINSA, INEI</span>*",
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto, {Sys.Date()}")
  )

ggsave(
  plot = p1,
  filename = "plots/pct_vacunados_dpto_dosis.png",
  width = 18,
  height = 14
)
