rm(list=ls())

## install.packages(c("ggplot2", "readr", "dplyr", "scales", "segmented"))

## Grafico StairwayPlot
## Los tildes fueron omitidos intencionalmente

## Cargar librerias
library(ggplot2)
library(readr)
library(dplyr)
library(scales)
library(segmented)

## Cambiar de directorio de trabajo a la carpeta con los resultados

## Cargar y combinar los tres escenarios
data_raw <- read_tsv("hirritans-global_fold.final.summary")

data <- data_raw %>%
  slice(-1) %>%
  rename(
    year = year,
    Ne_median = Ne_median,
    Ne_lower = `Ne_2.5%`,
    Ne_upper = `Ne_97.5%`
  ) %>%
  mutate(across(c(year, Ne_median, Ne_lower, Ne_upper), as.numeric))

## Crear grafico
ggplot(data, aes(x = year)) +
  geom_ribbon(aes(ymin = Ne_lower, ymax = Ne_upper), fill = "skyblue", alpha = 0.4) +
  geom_line(aes(y = Ne_median), color = "black", size = 1) +
  scale_x_log10(
    labels = label_number(scale_cut = cut_short_scale())
  ) +
  scale_y_log10(
    labels = label_number(scale_cut = cut_short_scale())
  ) +
  labs(
    x = "Time (years ago)",
    y = "Effective population size (Ne)",
    title = "Demographic history (Stairway Plot)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )
