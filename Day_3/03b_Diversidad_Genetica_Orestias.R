# ==============================================================================
# ANALISIS DE DIVERSIDAD GENETICA EN ORESTIAS
# ==============================================================================

# ==============================================================================
# 1. PREPARACIÓN DEL ENTORNO
# ==============================================================================

# Cargar librerías necesarias
library(ggplot2)
library(dplyr)

# Definir ruta de trabajo (Cambiar a la carpeta donde están tus archivos)
#setwd("C:/Users/pamel/Dropbox/CursoEnero2026/DataOrestias/CursoEnero2026_Orestias/div_gen_orestias")

# Cargar metadatos
# Estos vinculan cada ID del pez con su localidad de origen
meta <- read.csv("metadatos_orestias.csv") 

# ==============================================================================
# 2. ANÁLISIS DE HETEROCIGOSIDAD Y ENDOGAMIA (FIS)
# ==============================================================================

# Cargar resultados de VCFtools (.het)
het <- read.table("orestias_total.het", header=TRUE)

# Unir datos genéticos con metadatos
het_final <- merge(het, meta, by="INDV")

# Calcular Heterocigosidad Observada (Ho)
# La fórmula es: (Sitios Totales - Homocigotos Observados) / Sitios Totales
het_final$Ho <- (het_final$N_SITES - het_final$O.HOM.) / het_final$N_SITES

# --- Gráfico 1: Heterocigosidad Observada ---
# ¿Qué poblaciones tienen mayor variabilidad genética individual?
ggplot(het_final, aes(x=Poblacion, y=Ho, fill=Poblacion)) +
  geom_boxplot(alpha=0.7) +
  labs(title="Heterocigosidad Observada (Ho) por Población", 
       subtitle="Refleja la variabilidad genética actual de los individuos",
       y="Ho", x="Localidad") +
  theme_minimal()

# --- Gráfico 2: Coeficiente de Endogamia (FIS) ---
# Valores > 0 indican un déficit de heterocigotos (posible endogamia)
ggplot(het_final, aes(x=Poblacion, y=F, fill=Poblacion)) +
  geom_boxplot(alpha=0.7) +
  geom_hline(yintercept=0, linetype="dashed", color="red", size=1) +
  labs(title="Coeficiente de Endogamia (FIS)", 
       subtitle="Valores positivos sugieren apareamiento entre parientes o aislamiento",
       y="F (Inbreeding)", x="Localidad") +
  theme_minimal()

# ==============================================================================
# 3. ANÁLISIS DE DIVERSIDAD NUCLEOTÍDICA (Pi)
# ==============================================================================

# Leer archivos .pi
pi_asc <- read.table("pi_Ascotan.sites.pi", header=TRUE) %>% mutate(Pob="Ascotan")
pi_car <- read.table("pi_Carcote.sites.pi", header=TRUE) %>% mutate(Pob="Carcote")
pi_chu <- read.table("pi_Chungara.sites.pi", header=TRUE) %>% mutate(Pob="Chungara")
pi_lau <- read.table("pi_Lauca.sites.pi", header=TRUE) %>% mutate(Pob="Lauca")

pi_total <- rbind(pi_asc, pi_car, pi_chu, pi_lau)

# --- Gráfico 3: Distribución de Pi ---
ggplot(pi_total, aes(x=PI, fill=Pob)) +
  geom_density(alpha=0.5) +
  # Ajustar xlim fijo a 0.05 o 0.5
  coord_cartesian(xlim = c(0, 0.05)) + 
  labs(title="Distribución de la Diversidad Nucleotídica (Pi)", 
       subtitle="Curvas desplazadas a la derecha indican mayor diversidad",
       x="Pi (por sitio)", y="Densidad") +
  theme_minimal()

# Nota: El valor de pi depende de cuánta variación real hay.
# Si el gráfico se ve 'cortado' con 0.05, es porque nuestras Orestias tienen sitios con mucha más divergencia de la que esperábamos inicialmente.

# ==============================================================================
# 4. RESUMEN ESTADÍSTICO PARA DISCUSIÓN
# ==============================================================================

# Calcular promedios usando na.rm = TRUE para evitar los NaN
resumen_pi <- pi_total %>% 
  group_by(Pob) %>% 
  summarize(Pi_Promedio = mean(PI, na.rm = TRUE))

print("Promedios de Diversidad Nucleotídica (Pi):")
print(resumen_pi)

resumen_het <- het_final %>% 
  group_by(Poblacion) %>% 
  summarize(FIS_Promedio = mean(F, na.rm = TRUE),
            Ho_Promedio = mean(Ho, na.rm = TRUE))

print("Promedios de FIS y Heterocigosidad:")
print(resumen_het)


# ==============================================================================
# 5. GUARDAR RESULTADOS (Exportar Gráficos)
# ==============================================================================

# Creamos una carpeta para los resultados si no existe
if(!dir.exists("Graficos_Resultados")) dir.create("Graficos_Resultados")

# 1. Guardar gráfico de Heterocigosidad
# Volvemos a llamar al gráfico para asegurarnos que es el último en pantalla
ggplot(het_final, aes(x=Poblacion, y=Ho, fill=Poblacion)) +
  geom_boxplot(alpha=0.7) +
  labs(title="Heterocigosidad Observada (Ho) por Población", y="Ho", x="Localidad") +
  theme_minimal()

ggsave("Graficos_Resultados/01_Heterocigosidad_Ho.png", width = 8, height = 6, dpi = 300)

# 2. Guardar gráfico de FIS
ggplot(het_final, aes(x=Poblacion, y=F, fill=Poblacion)) +
  geom_boxplot(alpha=0.7) +
  geom_hline(yintercept=0, linetype="dashed", color="red", size=1) +
  labs(title="Coeficiente de Endogamia (FIS)", y="F (Inbreeding)", x="Localidad") +
  theme_minimal()

ggsave("Graficos_Resultados/02_Endogamia_FIS.png", width = 8, height = 6, dpi = 300)

# 3. Guardar gráfico de Pi
ggplot(pi_total, aes(x=PI, fill=Pob)) +
  geom_density(alpha=0.5) +
  coord_cartesian(xlim = c(0, 0.05)) + 
  labs(title="Distribución de la Diversidad Nucleotídica (Pi)", x="Pi (por sitio)", y="Densidad") +
  theme_minimal()

ggsave("Graficos_Resultados/03_Distribucion_Pi.png", width = 8, height = 6, dpi = 300)

# 4. Guardar las tablas de promedios en un archivo CSV
write.csv(resumen_pi, "Graficos_Resultados/Tabla_Promedios_Pi.csv", row.names = FALSE)
write.csv(resumen_het, "Graficos_Resultados/Tabla_Promedios_Heterocigosidad.csv", row.names = FALSE)

cat("¡Proceso completado! Los gráficos y tablas están en la carpeta 'Graficos_Resultados'.")

