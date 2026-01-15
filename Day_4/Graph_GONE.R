rm(list=ls())

## install.packages(c("ggplot2", "ggtext"))

## Grafico GONE
## Los tildes fueron omitidos intencionalmente

## Cargar librerias
library(ggplot2)
library(ggtext)

## Cambiar de directorio de trabajo a la carpeta con los resultados

## Leer los datos
df <- read.table("Output_Ne_popA", header = TRUE)

# Graficamos la columna 1 (Generation) vs la columna 2 (Ne_geometric)
ggplot(df, aes(x = Generation, y = Geometric_mean)) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(color = "steelblue", size = 1.5, alpha = 0.5) +
  scale_y_log10() +
  theme_minimal() +
  labs(
    title = "Inferencia de Tamaño Efectivo Poblacional (Ne)",
    subtitle = "Estimado con GONE (<i>Haematobia irritans</i>)",
    x = "Generaciones atrás",
    y = "Tamaño Efectivo (Escala Log10)",
    caption = "Nota: Las generaciones más recientes (0-5) pueden presentar ruido."
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_markdown(size = 12),
    axis.title = element_text(size = 12)
  )
