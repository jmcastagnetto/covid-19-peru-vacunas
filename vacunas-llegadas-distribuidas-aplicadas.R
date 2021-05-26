library(tidyverse)
library(ggtext)
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

round_any = function(x, accuracy, f=round){f(x/ accuracy) * accuracy}

plot_df <- read_csv("datos/covid19_vaccine_arrivals_peru.csv") %>%
  mutate(
    cantidad_acumulada = cumsum(cantidad)
  )

max_y <- round_any(max(plot_df$cantidad_acumulada), 2.5e6)

max_date <- max(plot_df$fecha_de_llegada, vacunas$fecha_vacunacion)
vac_apl <- max(vacunas$dosis_acum)
vac_arr <- max(plot_df$cantidad_acumulada)

txt_annotation <- glue::glue("Al {max_date}, **han llegado al pais un total de {format(vac_arr, big.mark = ',')} dosis** de vacunas, de las cuales ya <span style='color:green;'>se han aplicado {format(vac_apl, big.mark = ',')}</span> a nivel nacional")

Sys.setlocale("LC_TIME", "es_PE.utf8")
p1 <- ggplot() +
  geom_line(
    data = vacunas,
    aes(x = fecha_vacunacion, y = dosis_acum),
    size = 2,
    color = "green"
  ) +
  geom_step(
    data = plot_df,
    aes(x = fecha_de_llegada, y = cantidad_acumulada),
    direction = "vh",
    size = 1
  ) +
  geom_mark_circle(
    data = plot_df,
    aes(x = fecha_de_llegada,
        y = cantidad_acumulada,
        group = fecha_de_llegada,
        label = farmaceutica,
        color = farmaceutica,
        description = paste0(format(cantidad, big.mark = ","), " dosis")
    ),
    con.colour = "blue",
    label.fill = rgb(1, 1, 1, .6),
    show.legend = FALSE
  ) +
  geom_textbox(
    aes(x = as.Date("2021-02-15"),
        y = 4.5e6,
        label = txt_annotation),
    size = 9,
    width = unit(6, "in"),
    vjust = 1,
    hjust = 0,
    box.color = NA,
    inherit.aes = FALSE
  ) +
  scale_y_continuous(labels = scales::comma, limit = c(0, max_y)) +
  labs(
    x = "",
    y = "Número de dosis",
    title = "COVID-19: Vacunación en Perú - Dosis entregadas y aplicadas",
    subtitle = "Fuentes: MINSA y Wikipedia",
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto, {Sys.Date()}")
  ) +
  theme_classic(base_size = 18) +
  theme(
    plot.title.position = "plot",
    plot.title = element_text(size = 32),
    plot.subtitle = element_text(size = 24, color = "grey40"),
    plot.caption = element_text(family = "Inconsolata", size = 20)
  )

ggsave(
  plot = p1,
  filename = "plots/covid19-peru-vacunas-entregadas-aplicadas.png",
  width = 16,
  height = 12
)


