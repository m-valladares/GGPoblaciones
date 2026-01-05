Script1.md

Taller Práctico: Detección de Señales de Selección en Especies Invasoras


Modelo de Estudio: Rattus rattus (Población Santiago) Objetivo: Identificar loci outliers y genes candidatos bajo selección utilizando múltiples aproximaciones (RAiSD y SweepFinder2).

📂 Estructura de Trabajo

Para optimizar el tiempo, trabajaremos simulando un flujo real pero con "redes de seguridad".

    ~/Day05/Data: Aquí se encuentran los archivos crudos y copias de seguridad (backups) de todos los resultados. Si un análisis tarda mucho o falla, podrás copiar el archivo desde aquí.

    ~/Day05/Resultados_Estudiante: Esta será tu carpeta de trabajo. Aquí ejecutarás los códigos y guardarás tus salidas.

0. Configuración Inicial del Espacio de Trabajo

Lo primero es crear tu directorio personal y cargar las herramientas necesarias.
Bash

# 1. Cargar módulos necesarios

module load gsl
module load bcftools
module load bedtools

# 2. Crear tu carpeta de resultados
mkdir -p ~/Day05/Resultados_Estudiante

# 3. Ir a la carpeta Data para inspeccionar los archivos

cd ~/Day05/Data
ls -lh

# 4. Copiar el archivo input inicial a tu carpeta de trabajo
cp santiago.vcf.gz ~/Day05/Resultados_Estudiante/
cp CDS_genes_Rra.bed ~/Day05/Resultados_Estudiante/

# 5. Moverse a tu carpeta de trabajo

cd ~/Day05/Resultados_Estudiante

Paso 1: Preparación de los Datos

(Contexto: Los datos provienen de un VCF genómico completo. Para este taller, el instructor ya ha filtrado la población de "Santiago" y el cromosoma NC_046157.1 para agilizar el cómputo).

El formato .vcf.gz está comprimido. Para que herramientas como RAiSD lo lean eficientemente (dependiendo de la versión), lo descomprimiremos.
Bash

# Descomprimir el archivo VCF manteniendo el original
gunzip -c santiago.vcf.gz > santiago.vcf

# Verificar que el archivo existe
ls -lh santiago.vcf

Paso 2: Ejecución de RAiSD (Raised Accuracy in Sweep Detection)

RAiSD es una herramienta que calcula un índice compuesto (μ) basado en tres señales: reducción de diversidad, desequilibrio de ligamiento y cambios en el espectro de frecuencias.
2.1. Ejecutar el software

Ejecutaremos el análisis sobre nuestro cromosoma.

    -n: Nombre del prefijo para los archivos de salida (ej. RUN_SANTIAGO).

    -I: Archivo de entrada (Input).

    -f: Forzar sobreescritura si los archivos ya existen.

Bash

# Ejecutar RAiSD (Asegúrate de apuntar correctamente al ejecutable)
../../bin_taller/RAiSD -n RUN_SANTIAGO -I santiago.vcf -f

⏳ ¿Está tardando mucho? (PUNTO DE CONTROL) El análisis debería ser rápido (menos de 2-3 minutos). Si por alguna razón falla o demora demasiado, no te preocupes. Copia los resultados listos desde la carpeta Data:
Bash

# SOLO EJECUTAR SI EL PASO ANTERIOR FALLÓ
cp ~/Day05/Data/RAiSD_Report.RUN_SANTIAGO ~/Day05/Resultados_Estudiante/
cp ~/Day05/Data/RAiSD_Info.RUN_SANTIAGO ~/Day05/Resultados_Estudiante/

Paso 3: Procesamiento y Filtrado de Resultados

RAiSD genera un reporte (RAiSD_Report.RUN_SANTIAGO) con puntuaciones para miles de posiciones. Nuestro objetivo es quedarnos solo con el Top 1% de los valores más altos (los outliers más extremos).
3.1. Inspeccionar el archivo

Mira las primeras líneas para entender el formato:
Bash

head RAiSD_Report.RUN_SANTIAGO

3.2. Filtrar el Top 1% (Generar archivo BED)

Para no complicarnos con cálculos manuales de líneas, utilizaremos un archivo BED que ya contiene las coordenadas del Top 1% de outliers de esta población.

Nota: En un análisis real, usarías scripts de R o Python para determinar este umbral estadístico.
Bash

# Copiamos el archivo de outliers (Top 1%) pre-calculado
cp ~/Day05/Data/raisd_top1_percent.bed .

# Veamos cómo luce (Formato: Cromosoma | Inicio | Fin | Score_Mu)
head raisd_top1_percent.bed

Paso 4: Anotación Biológica (Cruce con Genes)

Ahora tenemos coordenadas estadísticas ("Aquí pasa algo raro"), pero necesitamos saber biología ("¿Qué gen está ahí?"). Para esto, cruzaremos nuestros outliers con el archivo de anotación CDS_genes_Rra.bed.

Usaremos bedtools intersect:

    -a: Nuestro archivo de outliers (RAiSD).

    -b: El archivo de genes.

    -wb: Escribe también la información del archivo B (para ver el nombre del gen).

Bash

# 1. Intersectar
bedtools intersect -a raisd_top1_percent.bed -b CDS_genes_Rra.bed -wb > raisd_genes_hit.txt

# 2. Limpiar la lista para obtener solo los nombres de los genes únicos
# (Cortamos la columna 8 que tiene el nombre del gen, ordenamos y quitamos duplicados)
cut -f 8 raisd_genes_hit.txt | sort | uniq > lista_genes_raisd.txt

# 3. ¡Veamos nuestros candidatos!
echo "Genes candidatos detectados por RAiSD:"
cat lista_genes_raisd_santiago.txt