# ==============================================================================
# ANALISIS DE ESTRUCTURA GENETICA EN ORESTIAS
# FST
# ==============================================================================

# ==============================================================================
# 1. PREPARACIÓN Y RUTAS
# ==============================================================================

# Establecer el directorio donde están los resultados del clúster
setwd("C:/Users/pamel/Dropbox/CursoEnero2026/DataOrestias/CursoEnero2026_Orestias/estructura_gen_orestias/")

# ==============================================================================
# 1. ANÁLISIS DE DIFERENCIACIÓN (FST POR SITIO)
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

# Definimos los valores exactos recuperados de los archivos .log
fst_weighted_antigua  <- 0.67344
fst_weighted_reciente <- 0.23267

# Creamos el gráfico de densidad comparativo
ggplot(fst_total, aes(x=WEIR_AND_COCKERHAM_FST, fill=Comparacion)) +
  geom_density(alpha=0.5) +
  # Añadimos líneas verticales que representen el valor REAL del log
  geom_vline(xintercept = fst_weighted_antigua, color = "red", linetype = "dashed", size = 1) +
  geom_vline(xintercept = fst_weighted_reciente, color = "blue", linetype = "dashed", size = 1) +
  
  # Anotamos los valores en el gráfico para que sea auto-explicativo
  annotate("text", x = fst_weighted_antigua + 0.1, y = 1.5, 
           label = paste("FST Global =", round(fst_weighted_antigua, 3)), color = "red") +
  annotate("text", x = fst_weighted_reciente + 0.1, y = 3, 
           label = paste("FST Global =", round(fst_weighted_reciente, 3)), color = "blue") +
  
  scale_fill_manual(values=c("Antigua (Salares: Asc-Car)"="#E41A1C", 
                             "Reciente (Altiplano: Lau-Chu)"="#377EB8")) +
  labs(title="Diferenciación Genómica: Antigua vs Reciente",
       subtitle="Las líneas punteadas indican el FST ponderado (Weighted) del archivo LOG",
       x="FST por sitio", y="Densidad") +
  theme_minimal()

ggsave("FST_Densidad.png", width = 8, height = 6, dpi = 300)



# ==============================================================================
# 2. PAISAJE DE DIVERGENCIA (TOP 50 SCAFFOLDS)
# MANHATTAN PLOT DE FST (DIFERENCIACIÓN POR POSICIÓN)
# ==============================================================================

# NOTA: Como no tenemos un genoma de referencia ensamblado en cromosomas, 
# usaremos los 'scaffolds' o 'chrom' en el eje X.

# 1. Identificar los 50 scaffolds con más SNPs (los más informativos)
# Vamos a identificar los 50 scaffolds que tienen más SNPs (que suelen ser los más largos) 
# y graficar solo esos.
top_info <- fst_antigua %>%
  group_by(CHROM) %>%
  tally(sort = TRUE) %>%
  slice_head(n = 50)

# Lista de scaffolds ordenados de mayor a menor
lista_ordenada <- as.character(top_info$CHROM)

# 2. Preparar los datos con el ordenamiento de mayor a menor
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

# 3. Gráfico Final
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

# 4. Guardar
ggsave("FST_por_sitio.png", width = 14, height = 8, dpi = 300)



# ==============================================================================
# MENSAJE FINAL DE LA SECCIÓN
# ==============================================================================
cat("--- Análisis de FST Finalizado ---\n")
cat("Diferencia detectada:\n")
cat("- Sistema Antiguo (Salares): FST =", resumen_log$Fst_Weighted[1], "\n")
cat("- Sistema Reciente (Altiplano): FST =", resumen_log$Fst_Weighted[2], "\n")


