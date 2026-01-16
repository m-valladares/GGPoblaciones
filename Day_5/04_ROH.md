# Runs of Homozygosity (ROH)

Objetivo: Inferir la historia demográfica reciente (cuellos de botella vs. estabilidad) calculando segmentos de homocigosis continuos en el genoma de Rattus rattus.

**¿Qué es un ROH?**

Un ROH (Run of Homozygosity) es un tramo largo de ADN donde las dos copias de tus cromosomas son idénticas.

¿Por qué ocurre? Porque heredaste el mismo segmento cromosómico de tu padre y de tu madre, quienes a su vez lo heredaron de un ancestro común reciente.

- ROHs Cortos y Fragmentados: Indican ancestros comunes muy antiguos (la recombinación ha tenido tiempo de romper los bloques). Típico de poblaciones grandes y diversas.

- ROHs Largos y Gigantes: Indican endogamia reciente o cuellos de botella severos (efecto fundador). Típico de invasiones recientes o aislamiento.

## 1. Configuración del Entorno

Primero, solicitamos un nodo de cómputo (si no estamos ya en uno) y cargamos las herramientas.

```bash

# 1. Solicitar recursos (Si ya tienen una sesión activa, salten este paso)
srun -p labs --pty --mem=2G -n 1 -c 1 --time=01:00:00 /bin/bash

# 2. Cargar Módulos y Rutas
module load intel-compilers/2022.0.1 impi/2021.5.0 R/4.3.0

# 3. Definir rutas a binarios y librerías del Instructor
export PATH=/home/courses/student23/Day05/bin_taller/bin:$PATH
export R_LIBS=/home/courses/student23/Day05/bin_taller/R_libs_4.3

```

## 2. Preparación de Datos

Crearemos una carpeta exclusiva para este análisis y traeremos los datos del Cromosoma 1.

```bash

# 1. Crear directorio de trabajo
mkdir -p ~/Day05/Resultados_Estudiante/04_ROH
cd ~/Day05/Resultados_Estudiante/04_ROH

# 2. Enlazar datos (VCF chr1 y Mapa de Poblaciones)
ln -s /home/courses/student23/Day05/Data/dataset_taller_chr1.vcf.gz .
ln -s /home/courses/student23/Day05/Data/popmap.txt .

# 3. Verificar
ls -l

```

## 3. Ejecución de BCFtools ROH

Calcularemos los bloques de homocigosis usando un Modelo Oculto de Markov (HMM).

⚠️ Nota Técnica: Usaremos la ruta absoluta al binario del instructor para asegurar que usamos la versión 1.21, capaz de manejar datos de baja cobertura (--ignore-homref).

```bash

# 1. Definir la herramienta
BCFTOOLS="/home/courses/student23/Day05/bin_taller/bin/bcftools"

# 2. Ejecutar Análisis ROH
# -G30: Filtrar genotipos de baja calidad (<30)
# -e -: Estimar frecuencias alélicas al vuelo
# --ignore-homref: Ignorar homocigotos de referencia (Vital para cobertura 1x-5x)
$BCFTOOLS roh -G30 -e - --ignore-homref -o output_roh_raw.txt dataset_taller_chr1.vcf.gz

# 3. Limpiar la salida
# Filtramos solo las líneas "RG" (Regiones) para el análisis
grep "^RG" output_roh_raw.txt > output_roh_clean.txt

# Revisar las primeras líneas
head -n 5 output_roh_clean.txt

```

## 4. Visualización: Barras Apiladas y disperción

Generaremos un gráfico de barras apiladas que clasifica la endogamia en tres categorías de tamaño:

- Corto (<150 kb)
- Medio (150-300 kb)
- Largo (>300 kb)

### 4.1 Crear el Script de R

Copia y pega el siguiente bloque completo en tu terminal para generar el archivo plot_roh_stacked.R.

```bash

cat <<'EOL' > plot_roh_stacked.R
#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(tidyr)
})

# Fix para servidor sin pantalla
options(bitmapType='cairo')

# --- 1. Cargar Datos ---
roh <- read_tsv("output_roh_clean.txt", col_names = FALSE, show_col_types = FALSE) %>%
  select(X2, X3, X6) %>% 
  rename(Sample = X2, Chr = X3, Length = X6)

popmap <- read_tsv("popmap.txt", col_names = c("Sample", "Pop"), show_col_types = FALSE)

# --- 2. Clasificar los ROH (Escala Fina) ---
# Clasificamos según la longitud del segmento en pares de bases
roh_classified <- roh %>%
  mutate(Class = case_when(
    Length < 150000  ~ "1. Corto (<150 kb)",
    Length < 300000  ~ "2. Medio (150-300 kb)",
    TRUE             ~ "3. Largo (>300 kb)"
  )) %>%
  inner_join(popmap, by = "Sample")

# --- 3. Calcular Sumas por Individuo ---
roh_summary <- roh_classified %>%
  group_by(Sample, Pop, Class) %>%
  summarise(Total_Mb = sum(Length) / 1e6, .groups = 'drop')

# --- 4. Graficar ---
cat("Generando gráfico...\n")

p <- ggplot(roh_summary, aes(x = Sample, y = Total_Mb, fill = Class)) +
  geom_bar(stat = "identity", width = 0.9) +
  
  # Dividir por Población
  facet_grid(~Pop, scales = "free_x", space = "free_x") +
  
  # Colores: Azul (Antiguo) -> Amarillo -> Rojo (Reciente/Alarma)
  scale_fill_manual(values = c("1. Corto (<150 kb)" = "#3498db", 
                               "2. Medio (150-300 kb)" = "#f1c40f", 
                               "3. Largo (>300 kb)" = "#e74c3c")) +
  
  labs(title = "Estructura de la Endogamia (ROH)",
       subtitle = "Rojo (>300kb) indica endogamia reciente o cuello de botella",
       x = "Individuos",
       y = "Longitud Total de ROH (Mb)",
       fill = "Clase de ROH") +
  
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
    panel.grid.major.x = element_blank(),
    strip.background = element_rect(fill = "grey90", color = NA),
    legend.position = "top"
  )

# Guardar
ggsave("ROH_Stacked_Analysis.png", p, width = 12, height = 7, bg = "white")
cat("¡Listo! Archivo generado: ROH_Stacked_Analysis.png\n")
EOL

```

Tambien podemos graficar como dispersión de los datos.

```bash

cat <<'EOL' > plot_roh.R
#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
})

# Fix para cluster sin pantalla
options(bitmapType='cairo')

# 1. Leer Datos
roh <- read_tsv("output_roh_clean.txt", col_names = FALSE, show_col_types = FALSE) %>%
  select(X2, X3, X6) %>% rename(Sample = X2, Chr = X3, Length = X6)

popmap <- read_tsv("popmap.txt", col_names = c("Sample", "Pop"), show_col_types = FALSE)

# 2. Calcular Estadísticas (Suma total y Conteo)
roh_stats <- roh %>%
  group_by(Sample) %>%
  summarise(SROH_Mb = sum(Length) / 1e6, NROH = n()) %>%
  inner_join(popmap, by = "Sample")

cat("Generando gráficos...\n")

# 3. Scatter Plot (Estilo Perla)
p1 <- ggplot(roh_stats, aes(x = NROH, y = SROH_Mb, color = Pop)) +
  geom_point(size = 4, alpha = 0.8) +
  stat_ellipse(level = 0.9, type = "t", alpha=0.3) +
  labs(title = "Historia Demográfica (ROH)", 
       subtitle = "Izquierda-Abajo: Antiguo | Derecha-Arriba: Cuello de Botella",
       x = "Número de Segmentos (NROH)", y = "Longitud Total (Mb)") +
  theme_minimal(base_size = 14)

# 4. Guardar
ggsave("ROH_Scatter.png", p1, width = 8, height = 6, bg="white")
cat("¡Listo! Archivo generado: ROH_Scatter.png\n")
EOL

```

### 4.2 Ejecutar la Visualización

```bash

Rscript plot_roh_stacked.R
Rscript plot_roh.R

```

Descarguen o abran las imagenes en VS code.
