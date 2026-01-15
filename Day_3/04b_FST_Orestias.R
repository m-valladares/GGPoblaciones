# ==============================================================================
# ANALISIS DE ESTRUCTURA GENETICA EN ORESTIAS
# FST
# ==============================================================================

# ==============================================================================
# PREPARACIÓN DEL ENTORNO
# ==============================================================================

# Cargar librerías necesarias
library(ggplot2)
library(dplyr)

# Establecer el directorio donde están los resultados del clúster


# ==============================================================================
# ANÁLISIS DE DIFERENCIACIÓN (FST GLOBAL)
# ==============================================================================

# Cargar los archivos de FST calculados en el clúster
fst_antigua  <- read.table("FST_Antigua_Ascotan_Carcote.weir.fst", header=TRUE)
fst_reciente <- read.table("FST_Reciente_Lauca_Chungara.weir.fst", header=TRUE)

# Agregar una etiqueta para identificarlos al unirlos
fst_antigua$Comparacion  <- "Antigua (Salares: Asc-Car)"
fst_reciente$Comparacion <- "Reciente (Altiplano: Lau-Chu)"

# Unir ambas tablas
fst_total <- rbind(fst_antigua, fst_reciente)

# Limpieza: VCFtools puede generar valores negativos (ruido estadístico), los llevamos a 0
fst_total$WEIR_AND_COCKERHAM_FST[fst_total$WEIR_AND_COCKERHAM_FST < 0] <- 0


# EXTRACCIÓN AUTOMÁTICA DE VALORES DE FST GLOBALES DESDE LOS ARCHIVOS .LOG

# Definimos los nombres de los archivos log (deben estar en tu carpeta setwd)
archivos_log <- c("FST_Antigua_Ascotan_Carcote.log", "FST_Reciente_Lauca_Chungara.log")

# Función para extraer el Weighted Fst
extraer_fst_weighted <- function(archivo) {
  lineas <- readLines(archivo)
  # Buscamos la línea exacta que contiene el weighted Fst
  linea_especifica <- lineas[grep("Weir and Cockerham weighted Fst estimate:", lineas)]
  
  # Extraemos solo el número (el valor después de los dos puntos)
  valor <- as.numeric(gsub(".*: ", "", linea_especifica))
  return(valor)
}

# Creamos el objeto resumen_log que usará el Manhattan Plot
resumen_log <- data.frame(
  Comparacion = c("Antigua (Salares: Asc-Car)", "Reciente (Altiplano: Lau-Chu)"),
  Fst_Weighted = c(extraer_fst_weighted(archivos_log[1]), 
                   extraer_fst_weighted(archivos_log[2]))
)

# Verificación en consola
print("Valores de FST extraídos con éxito:")
print(resumen_log)


# GRÁFICO DE DENSIDAD COMPARATIVO

ggplot(fst_total, aes(x=WEIR_AND_COCKERHAM_FST, fill=Comparacion)) +
  geom_density(alpha=0.5) +
  
  # Añadimos líneas verticales sacando los datos de resumen_log
  # [1] es Antigua, [2] es Reciente
  geom_vline(xintercept = resumen_log$Fst_Weighted[1], color = "#E41A1C", linetype = "dashed", size = 1) +
  geom_vline(xintercept = resumen_log$Fst_Weighted[2], color = "#377EB8", linetype = "dashed", size = 1) +
  
  # Anotamos los valores extrayendo directamente del objeto resumen_log
  annotate("text", x = resumen_log$Fst_Weighted[1] + 0.1, y = 1.5, 
           label = paste("FST Global =", round(resumen_log$Fst_Weighted[1], 3)), color = "#E41A1C") +
  annotate("text", x = resumen_log$Fst_Weighted[2] + 0.1, y = 3, 
           label = paste("FST Global =", round(resumen_log$Fst_Weighted[2], 3)), color = "#377EB8") +
  
  scale_fill_manual(values=c("Antigua (Salares: Asc-Car)"="#E41A1C", 
                             "Reciente (Altiplano: Lau-Chu)"="#377EB8")) +
  labs(title="Diferenciación Genómica en Orestias: Antigua vs Reciente",
       subtitle="Las líneas punteadas indican el FST ponderado (Weighted) extraído de los logs",
       x=expression(italic(F)[ST]~"por sitio"), y="Densidad") +
  theme_minimal()


# Guardar el gráfico de Densidad
ggsave("FST_Densidad_Orestias.png", width = 8, height = 6, dpi = 300)


# ==============================================================================
# PAISAJE DE DIVERGENCIA (TOP 50 SCAFFOLDS)
# MANHATTAN PLOT DE FST (DIFERENCIACIÓN POR POSICIÓN)
# ==============================================================================

# NOTA: Como no tenemos un genoma de referencia ensamblado en cromosomas, 
# usaremos los 'scaffolds' o 'chrom' en el eje X.

# Identificar los 50 scaffolds con más SNPs (los más informativos)
# Vamos a identificar los 50 scaffolds que tienen más SNPs (que suelen ser los más largos) 
# y graficar solo esos.
top_info <- fst_antigua %>%
  group_by(CHROM) %>%
  tally(sort = TRUE) %>%
  slice_head(n = 50)

# Lista de scaffolds ordenados de mayor a menor
lista_ordenada <- as.character(top_info$CHROM)

# Preparar los datos con el ordenamiento de mayor a menor
fst_total_plot <- rbind(
  fst_antigua %>% filter(CHROM %in% lista_ordenada) %>% mutate(Comparacion = "Antigua (Salares: Asc-Car)"),
  fst_reciente %>% filter(CHROM %in% lista_ordenada) %>% mutate(Comparacion = "Reciente (Altiplano: Lau-Chu)")
) %>%
  mutate(
    WEIR_AND_COCKERHAM_FST = ifelse(WEIR_AND_COCKERHAM_FST < 0, 0, WEIR_AND_COCKERHAM_FST),
    # Reordenar los niveles del factor CHROM según nuestra lista
    CHROM = factor(CHROM, levels = lista_ordenada),
    # Asegurar orden de los paneles
    Comparacion = factor(Comparacion, levels = c("Antigua (Salares: Asc-Car)", "Reciente (Altiplano: Lau-Chu)"))
  )


# GRÁFICO DIFERENCIACION POR SITIO

ggplot(fst_total_plot, aes(x = POS, y = WEIR_AND_COCKERHAM_FST)) +
  # Alternamos colores: Rojo/Gris para el panel superior y Azul/Gris para el inferior
  geom_point(aes(color = interaction(CHROM, Comparacion)), alpha = 0.5, size = 0.8) +
  scale_color_manual(values = c(rep(c("#E41A1C", "grey60"), 25), # Colores para Antigua
                                rep(c("#377EB8", "grey60"), 25))) + # Colores para Reciente
  
  geom_hline(data = resumen_log, aes(yintercept = Fst_Weighted), 
             linetype = "dashed", color = "black", size = 0.7) +
  
  # Usamos facet_grid para controlar espacio de filas y columnas por separado
  facet_grid(Comparacion ~ CHROM, scales = "free_x", space = "free_x") +
  
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.5)) +
  labs(title = "Paisaje de Divergencia Genómica: Orestias",
       subtitle = "Top 50 Scaffolds ordenados por tamaño. Comparación de sistemas antiguo vs reciente.",
       x = "Posición Genómica (Scaffolds ordenados de mayor a menor)", 
       y = expression(italic(F)[ST])) +
  theme_bw() +
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        # --- AJUSTE DE ESPACIADOS ---
        panel.spacing.x = unit(0.0, "lines"), # Pega los scaffolds entre sí
        panel.spacing.y = unit(1.5, "lines"), # Separa el panel superior del inferior
        # ----------------------------
        strip.background = element_blank(),
        strip.text.x = element_blank(),
        legend.position = "none",
        panel.grid = element_blank())

# Guardar
ggsave("FST_por_sitio.png", width = 14, height = 8, dpi = 300)



# ==============================================================================
# MENSAJE FINAL DE LA SECCIÓN
# ==============================================================================
cat("--- Análisis de FST Finalizado ---\n")
cat("Diferencia detectada:\n")
cat("- Sistema Antiguo (Salares): FST =", resumen_log$Fst_Weighted[1], "\n")
cat("- Sistema Reciente (Altiplano): FST =", resumen_log$Fst_Weighted[2], "\n")

