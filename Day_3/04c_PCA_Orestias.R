# ==============================================================================
# ANALISIS DE ESTRUCTURA GENETICA EN ORESTIAS
# ANALISIS DE COMPONENTES PRINCIPALES
# ==============================================================================

# ==============================================================================
# 1. PREPARACIÓN Y RUTAS
# ==============================================================================
library(ggplot2)
library(dplyr)

# Establecer el directorio donde están los resultados del clúster
setwd("C:/Users/pamel/Dropbox/CursoEnero2026/DataOrestias/CursoEnero2026_Orestias/estructura_gen_orestias/")

# ==============================================================================
# 2. CARGA Y LIMPIEZA DE DATOS
# ==============================================================================

# Cargar las coordenadas generadas por PLINK (Eigenvectors)
pca_data <- read.table("orestias_pca_results.eigenvec", header=FALSE)

# Renombrar columnas: PLINK entrega Familia (FID), Individuo (INDV) y los PCs
colnames(pca_data) <- c("FID", "INDV", paste0("PC", 1:10))

# --- NOTA PEDAGÓGICA: Limpieza de IDs ---
# PLINK suele duplicar el ID (ej. "ASC01_ASC01"). 
# Usamos sub() para eliminar todo lo que viene después del guion bajo
# para que coincida con nuestros metadatos.
pca_data$INDV <- sub("_.*", "", pca_data$INDV)

# Cargar el archivo de metadatos (poblaciones)
meta <- read.csv("metadatos_orestias.csv")

# Unir coordenadas con metadatos usando la columna 'INDV'
pca_final <- merge(pca_data, meta, by="INDV")

# Verificación de éxito del cruce de datos
print(paste("Éxito: Se han vinculado", nrow(pca_final), "individuos con sus metadatos."))

# ==============================================================================
# 3. CÁLCULO DE VARIANZA EXPLICADA
# ==============================================================================

# Cargar los Eigenvalues para saber cuánto peso tiene cada eje (PC)
evals <- read.table("orestias_pca_results.eigenval", header=FALSE)$V1

# Calcular el porcentaje de varianza para los dos primeros ejes
pc1_var <- round(evals[1]/sum(evals)*100, 1)
pc2_var <- round(evals[2]/sum(evals)*100, 1)

# ==============================================================================
# 4. VISUALIZACIÓN (EL GRÁFICO DEL MOMENTO)
# ==============================================================================

ggplot(pca_final, aes(x=PC1, y=PC2, color=Poblacion)) +
  geom_point(size=4, alpha=0.8) +
  # Definimos colores específicos para cada población
  scale_color_manual(values=c("Ascotan"="#E41A1C",   # Rojo
                              "Carcote"="#377EB8",   # Azul
                              "Chungara"="#4DAF4A",  # Verde
                              "Lauca"="#984EA3")) +  # Morado
  labs(title="PCA: Estructura Genética de Orestias",
       x=paste0("PC1 (", pc1_var, "%)"), 
       y=paste0("PC2 (", pc2_var, "%)")) +
  theme_bw() + # Fondo blanco y limpio
  theme(panel.grid.minor = element_blank(),
        legend.position = "right",
        plot.title = element_text(face="bold", size=14))

# ==============================================================================
# 5. EXPORTACIÓN
# ==============================================================================

# Guardar el gráfico en alta resolución para el informe final
ggsave("PCA_Orestias_Final.png", width = 8, height = 6, dpi = 300)

cat("Gráfico guardado exitosamente en la carpeta de trabajo.")


# ==============================================================================
# 6. EXPLORACIÓN DE ESTRUCTURA FINA (PC2 vs PC3)
# ==============================================================================

# Calculamos la varianza explicada por el tercer componente (PC3)
pc3_var <- round(evals[3]/sum(evals)*100, 1)

# NOTA PEDAGÓGICA: 
# A veces, el PC1 es tan fuerte (separa cuencas) que oculta diferencias menores.
# Al graficar PC2 vs PC3, "hacemos zoom" en la relación entre poblaciones que 
# se veían muy juntas en el primer gráfico, como Lauca y Chungará.

ggplot(pca_final, aes(x=PC2, y=PC3, color=Poblacion)) +
  geom_point(size=4, alpha=0.8) +
  scale_color_manual(values=c("Ascotan"="#E41A1C", 
                              "Carcote"="#377EB8", 
                              "Chungara"="#4DAF4A", 
                              "Lauca"="#984EA3")) +
  labs(title="PCA: Estructura Fina de Orestias",
       subtitle="Exploración de Componentes 2 y 3",
       x=paste0("PC2 (", pc2_var, "%)"), 
       y=paste0("PC3 (", pc3_var, "%)")) +
  theme_bw() +
  theme(panel.grid.minor = element_blank(),
        legend.position = "right",
        plot.title = element_text(face="bold", size=14))

# ==============================================================================
# 7. GUARDAR RESULTADOS DE ESTRUCTURA
# ==============================================================================

# Guardamos el gráfico de estructura fina
ggsave("PCA_Orestias_Estructura_Fina_PC2_PC3.png", width = 8, height = 6, dpi = 300)

cat("Análisis de PCA completado. Revisa la separación de Lauca y Chungará en el PC3.")


