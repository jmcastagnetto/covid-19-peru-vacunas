df <- vaccine_arrivals %>%
  group_by(covax) %>%
  summarise(tot = sum(cantidad)) %>%
  ungroup() %>%
  mutate(
    pct = 100*tot/sum(tot),
    cov_lbl = if_else(covax, "COVAX", "COMPRA DIRECTA"),
    lbl = glue::glue("{cov_lbl}\n{sprintf('%.1f%%', pct)}")
  )

ggplot(
  df,
  aes(x = "", y = tot, fill = covax)
) +
  geom_col(show.legend = FALSE, color = "black") +
  geom_text(
    aes(label = lbl),
    position = position_stack(vjust = .5),
    color = "white",
    fontface = "bold",
    size = 8
  ) +
  coord_polar(theta = "y", start = 0) +
  theme_void(base_size = 18) +
  theme(
    plot.title = element_text(hjust = .5),
    plot.subtitle = element_text(hjust = .5),
    plot.caption = element_text(family = "Inconsolata"),
    plot.margin = unit(rep(.5, 4), "cm")
  ) +
  scale_fill_brewer(type = "qual", palette = "Dark2") +
  labs(
    title = "Vacunación COVID-19 (Perú)\nOrigen de las vacunas",
    subtitle = glue::glue("Dosis disponibles {format(sum(df$tot), big.mark = ',')}"),
    caption = glue::glue("Fuente: CENARES\n@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  )
