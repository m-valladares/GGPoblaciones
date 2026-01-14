# ==============================================================================
# ANALISIS DE ESTRUCTURA GENETICA EN ORESTIAS
# ADMIXTURE
# ==============================================================================

# ====================================+==========================================
# 1. Barplot de Orestias con K=4
# ==============================================================================

# Establecer el directorio donde están los resultados del clúster
setwd("C:/Users/pamel/Dropbox/CursoEnero2026/DataOrestias/CursoEnero2026_Orestias/estructura_gen_orestias/")

# Cargar librerías necesarias
# Si no las tienes, descomenta la siguiente línea:
# install.packages("tidyverse")
library(tidyverse)

# Leer los archivos de resultados
# Asegúrate de estar en el directorio donde están estos archivos
q_data <- read.table("orestias_admix.4.Q")
fam_data <- read.table("orestias_admix.fam")

# Preparar el set de datos
# Unimos las proporciones (.Q) con los nombres de los individuos (.fam)
df <- q_data %>%
  mutate(Individuo = fam_data$V2) %>%
  # Creamos la columna de Población basada en los prefijos de tus muestras
  mutate(Poblacion = case_when(
    str_detect(Individuo, "^ASC") ~ "Ascotán",
    str_detect(Individuo, "^CAR") ~ "Carcote",
    str_detect(Individuo, "^CHUN") ~ "Chungará",
    str_detect(Individuo, "^LAU") ~ "Lauca",
    TRUE ~ "Otro"
  )) %>%
  # Pasamos a formato 'long' para que ggplot pueda graficar
  pivot_longer(cols = starts_with("V"), 
               names_to = "Cluster", 
               values_to = "Proporcion")

# Ordenar las poblaciones para que el gráfico sea legible
df$Poblacion <- factor(df$Poblacion, 
                       levels = c("Ascotán", "Carcote", "Chungará", "Lauca"))

# Crear el gráfico de barras (Barplot)
ggplot(df, aes(x = Individuo, y = Proporcion, fill = Cluster)) +
  geom_bar(stat = "identity", width = 1) +
  # Dividir el gráfico por población
  facet_grid(~Poblacion, scales = "free_x", space = "free_x") +
  # Paleta de colores distintiva
  scale_fill_brewer(palette = "Set1") +
  labs(title = "Análisis de Ancestría ADMIXTURE (K=4)",
       subtitle = "Poblaciones de Orestias",
       x = "Individuos",
       y = "Proporción de Ancestría") +
  theme_minimal() +
  theme(
    axis.text.x = element_blank(), # Quitamos nombres individuales si son muchos
    axis.ticks.x = element_blank(),
    panel.spacing = unit(0.2, "lines"),
    strip.background = element_rect(fill = "gray95"),
    strip.text = element_text(face = "bold"),
    legend.position = "none"
  )

# Guardar el gráfico en alta resolución
ggsave("Orestias_Admixture_K4.png", width = 10, height = 5, dpi = 300)


# ==============================================================================
# 2. Plot Error de Validación
# ==============================================================================

# Listar todos los archivos log de Admixture
archivos_log <- list.files(pattern = "log.*\\.out")

# Función para leer el log y extraer el K y el Error
extraer_cv <- function(archivo) {
  lineas <- readLines(archivo)
  # Buscamos la línea que contiene "CV error"
  cv_linea <- lineas[grep("CV error", lineas)]
  
  # Extraemos los números usando expresiones regulares
  # Esperamos un formato como: CV error (K=2): 0.43135
  k_val <- as.numeric(str_extract(cv_linea, "(?<=K=)\\d+"))
  err_val <- as.numeric(str_extract(cv_linea, "(?<=: )\\d+\\.\\d+"))
  
  return(data.frame(K = k_val, Error = err_val))
}

# Crear la tabla de errores automáticamente
cv_data <- map_df(archivos_log, extraer_cv) %>% arrange(K)

# Gráfico del CV Error
plot_cv <- ggplot(cv_data, aes(x = K, y = Error)) +
  geom_line(color = "darkblue", size = 1) +
  geom_point(color = "red", size = 3) +
  scale_x_continuous(breaks = cv_data$K) +
  labs(title = "Validación Cruzada (CV Error)",
       subtitle = "El valor óptimo es el que minimiza el error",
       x = "Número de Poblaciones (K)", y = "CV Error") +
  theme_bw()

print(plot_cv)

# Guardar el gráfico del CV Error en formato PNG
ggsave("CV_Error_Admixture.png", plot = plot_cv, width = 8, height = 5, dpi = 300)
