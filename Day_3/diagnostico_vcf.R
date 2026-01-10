# ==============================================================================
# DIAGNÓSTICO DE CALIDAD DEL VCF (Orestias)
# ==============================================================================

# 1. SETEAR WORKING DIRECTORY PRINCIPAL
setwd("C:/Users/pamel/Dropbox/CursoEnero2026/DataOrestias/CursoEnero2026_Orestias")

# 2. DEFINIR RUTA A LA SUB-CARPETA DE DATOS
data_path <- "resultados_vcf/"

# 3. CARGAR DATOS (Agregando la ruta de la subcarpeta)
library(tidyverse)

var_qual   <- read_delim(paste0(data_path, "Orestias_full.lqual"), delim = "\t", col_names = c("chr", "pos", "qual"), skip = 1)
var_depth  <- read_delim(paste0(data_path, "Orestias_full.ldepth.mean"), delim = "\t", col_names = c("chr", "pos", "mean_depth", "var_depth"), skip = 1)
var_miss   <- read_delim(paste0(data_path, "Orestias_full.lmiss"), delim = "\t", col_names = c("chr", "pos", "nchr", "nfiltered", "nmiss", "fmiss"), skip = 1)
ind_miss   <- read_delim(paste0(data_path, "Orestias_full.imiss"), delim = "\t", col_names = c("ind", "ndata", "nfiltered", "nmiss", "fmiss"), skip = 1)
ind_depth  <- read_delim(paste0(data_path, "Orestias_full.idepth"), delim = "\t", col_names = c("ind", "nsites", "depth"), skip = 1)

# 4. CREAR CARPETA DE FIGURAS (Para que no se mezclen con los datos)
if(!dir.exists("figuras_diagnostico")) dir.create("figuras_diagnostico")

# 5. CALIDAD DE LOS SITIOS (QUAL)
# Un umbral estándar es Q30 (precisión del 99.9%)
p1 <- ggplot(var_qual, aes(qual)) + 
  geom_density(fill = "dodgerblue", alpha = 0.5) +
  geom_vline(xintercept = 30, color = "red", linetype = "dashed") +
  theme_classic() +
  labs(title = "Calidad Phred por Sitio", x = "Calidad (QUAL)", y = "Densidad")

ggsave("figuras_diagnostico/1_calidad_sitios.png", p1, width = 7, height = 5)

# 6. PROFUNDIDAD MEDIA POR SITIO
# Buscamos el "pico" de cobertura. Sitios con excesiva profundidad suelen ser repetitivos.
p2 <- ggplot(var_depth, aes(mean_depth)) + 
  geom_density(fill = "springgreen4", alpha = 0.5) +
  xlim(0, 100) + # Ajustar según los datos
  theme_classic() +
  labs(title = "Profundidad Media por Sitio", x = "Mean Depth", y = "Densidad")

ggsave("figuras_diagnostico/2_profundidad_sitios.png", p2, width = 7, height = 5)

# 7. DATOS FALTANTES POR SITIO (Missingness)
# Aquí veremos cuántos sitios perdemos según el filtro --max-missing
p3 <- ggplot(var_miss, aes(fmiss)) + 
  geom_density(fill = "firebrick", alpha = 0.5) +
  geom_vline(xintercept = 0.5, color = "blue", linetype = "dotted") +
  theme_classic() +
  labs(title = "Datos Faltantes por Sitio", 
       subtitle = "La línea azul marca el 50% de missing data",
       x = "Proporción de datos faltantes", y = "Densidad")

ggsave("figuras_diagnostico/3_missing_sitios.png", p3, width = 7, height = 5)

# 8. DATOS FALTANTES POR INDIVIDUO (Peces)
# Útil para identificar si alguna muestra de Orestias falló completamente
p4 <- ggplot(ind_miss, aes(fmiss)) + 
  geom_histogram(fill = "orange", color = "black", bins = 20) +
  theme_classic() +
  labs(title = "Datos Faltantes por Individuo", x = "Proporción de datos faltantes", y = "Frecuencia (n de peces)")

ggsave("figuras_diagnostico/4_missing_individuos.png", p4, width = 7, height = 5)

# 9. PROFUNDIDAD POR INDIVIDUO
p5 <- ggplot(ind_depth, aes(depth)) + 
  geom_histogram(fill = "purple", color = "black", bins = 20) +
  theme_classic() +
  labs(title = "Profundidad Media por Individuo", x = "Depth", y = "Frecuencia")

ggsave("figuras_diagnostico/5_profundidad_individuos.png", p5, width = 7, height = 5)

print("Gráficos generados exitosamente en la carpeta 'figuras_diagnostico'")


# -----------------------------------------------------------------

# En tu caso, al ser 95 individuos, el mean_depth se calcula sumando la profundidad de todos y dividiéndola por 95. Si un sitio tiene un mean_depth de 500x, significa que o es una zona de ADN repetitivo (donde se pegan lecturas de muchas partes del genoma) o es un parálogo (un gen duplicado que se mapea erróneamente en el mismo lugar).

# Ejecuta esto en tu consola de R. Nos dirá si tu media es 20x como la de Joana o si es más baja (lo cual sospecho por ser RADseq):
summary(var_depth$mean_depth)

# Ver los cuantiles (5% y 95%)
# Esto te dará los umbrales basados puramente en tus datos, sin adivinar:
quantile(var_depth$mean_depth, probs = c(0.05, 0.95))

# 1. El diagnóstico: Una distribución con "inflación de ceros"
# Media vs. Mediana: Tu media es 4.11, pero tu mediana es casi cero (0.03). Esto sucede porque tienes una cantidad masiva de sitios que solo están presentes en 1 o 2 individuos (profundidades bajísimas), lo que arrastra la mediana al suelo.

# El 75% de tus datos (3rd Qu.): ¡Sigue siendo bajísimo (0.06)! Esto significa que la gran mayoría de los sitios en tu VCF crudo son "sitios huérfanos" que no nos sirven para genética de poblaciones.

# El 5% superior (95% quantile): Salta hasta 32.87. Aquí es donde están los SNPs que sí están presentes en muchos individuos.

# Para tu dataset de Orestias, lo más científico sería:

# Mínimo (--min-meanDP): No pongas un mínimo muy alto. Si pones 10x, perderás casi todo. Como ya vamos a usar --max-missing 0.5, ese filtro se encargará de eliminar los sitios de baja profundidad automáticamente.

# Máximo (--max-meanDP): El cuantil 95% es 32.87. Podríamos redondear a 40x o 50x. Todo lo que esté por encima de eso es sospechoso de ser un error de mapeo o una secuencia repetitiva (parálogos).



# Calculamos la media para usar la regla de "Media x 2"
media_dp <- mean(var_depth$mean_depth)
max_sugerido <- media_dp * 2

# Gráfico con zoom y líneas de corte
p_depth_zoom <- ggplot(var_depth, aes(mean_depth)) + 
  geom_density(fill = "dodgerblue1", colour = "black", alpha = 0.3) +
  theme_light() +
  xlim(0, 0.5) + # Hacemos zoom para ignorar los outliers de 500x
  labs(title = "Distribución de Profundidad Media (Zoom)",
       subtitle = paste("Media:", round(media_dp, 2)),
       x = "Mean Depth per Site", y = "Densidad")

print(p_depth_zoom)
ggsave("figuras_diagnostico/2b_profundidad_zoom.png", p_depth_zoom, width = 8, height = 6)
