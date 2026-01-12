
## Taller Práctico: Detección de Señales de Selección en Especies Invasoras


Modelo de Estudio: *Rattus rattus* (Población Santiago) Objetivo: Identificar loci outliers y genes candidatos bajo selección utilizando múltiples aproximaciones (RAiSD y SweepFinder2).

 ---

## 📂 Estructura de Trabajo

Para optimizar el tiempo, trabajaremos simulando un flujo real pero con "redes de seguridad".


    ~/Day05/Data: Aquí se encuentran los archivos crudos y copias de seguridad (backups) de todos los resultados. Si un análisis tarda mucho o falla, podrás copiar el archivo desde aquí.

    ~/Day05/Resultados_Estudiante: Esta será tu carpeta de trabajo. Aquí ejecutarás los códigos y guardarás tus salidas.


## 0. Inicio de Sesión

Antes de cargar cualquier herramienta, debemos pedir recursos al clúster para no trabajar en el nodo de acceso.

1. Solicitar nodo de cómputo: Ejecuta esto y espera a que el prompt cambie (ej. de [usuario@leftraru] a [usuario@cn045]).

```bash

srun -p labs --pty --mem=2G -n 1 -c 1 --time=03:00:00 /bin/bash

```

1. Configuración del Entorno

Una vez dentro del nodo de cómputo, cargamos las herramientas.


# 1. Cargar módulos necesarios

```bash

# A. Cargar dependencias
module load gsl
module load Anaconda3/2020.02
module load bcftools
# (Bedtools y RAiSD se cargan automáticamente en el paso siguiente)

# B. Conectar las herramientas del curso
export PATH=$PATH:/home/courses/student23/Day05/bin_taller

```

# 2. Crear tu espacio de trabajo y traer los datos

```bash

# A. Crear tu carpeta de trabajo
mkdir -p ~/Day05/Resultados_Estudiante

# B. Crear el enlace directo a los datos del taller
# Esto crea un atajo llamado 'Data' que apunta a los archivos originales
ln -s /home/courses/student23/Day05/Data ~/Day05/Data

# C. Entrar a tu carpeta y copiar los inputs
cd ~/Day05/Resultados_Estudiante
cp ../Data/santiago.vcf.gz .
cp ../Data/CDS_genes_Rra.bed .

```

## Parte 1: Método RAiSD 


RAiSD busca una combinación de reducción de diversidad, desequilibrio de ligamiento (LD) y SFS.

# 1. Preparación y Ejecución

```bash

# 1. Descomprimir VCF (RAiSD requiere texto plano)
gunzip -c santiago.vcf.gz > santiago.vcf

# 2. Ejecutar RAiSD
# -n: Nombre de la salida (RUN_SANTIAGO)
# -I: Input
# -f: Forzar sobreescritura
RAiSD -n RUN_SANTIAGO -I santiago.vcf -f


```
⏳ Atención: Si el análisis tarda más de 5 minutos, presiona Ctrl + C para detenerlo y copia el resultado listo

```bash

#cp ../Data/RAiSD_Report.RUN_SANTIAGO .

```

# 2. Procesamiento de Resultados (Filtrado Top 1%)

El reporte crudo tiene miles de líneas. Vamos a calcular dinámicamente el Top 1% de los sitios con mayor señal de selección y cruzarlos con genes.


```bash
# A. Formatear la salida de RAiSD (Arreglar columnas)
awk '/^\/\// {CHR=$2; next} {print CHR, $1, $1, $2}' RAiSD_Report.RUN_SANTIAGO > raisd_formateado.txt

# B. Ordenar por Score (Mayor a menor)
sort -k4,4gr raisd_formateado.txt > raisd_ordenado.txt

# C. Calcular dinámicamente el Top 1%
# Contamos el total de líneas y calculamos el 1% matemático
TOTAL_SNPS=$(wc -l < raisd_ordenado.txt)
UMBRAL=$(( TOTAL_SNPS / 100 ))

echo "Analizando $TOTAL_SNPS SNPs. Seleccionando el Top 1% ($UMBRAL variantes)..."

# D. Crear el archivo BED con los candidatos
# Usamos el $UMBRAL calculado. Restamos 1 a la posición para formato BED.
head -n $UMBRAL raisd_ordenado.txt | awk -v OFS='\t' '{print $1, int($2)-1, int($2), $4}' > top_raisd.bed

# E. Cruzar con genes (Anotación)
# bedtools busca qué variante cae dentro de un gen
bedtools intersect -a top_raisd.bed -b CDS_genes_Rra.bed -wb > raisd_hits.txt

# F. Generar lista final de nombres de genes únicos
cut -f 8 raisd_hits.txt | sort | uniq > genes_candidatos_SANTIAGO_raisd.txt

# G. ¡Ver resultados!
echo "Número de genes candidatos encontrados:"
wc -l genes_candidatos_SANTIAGO_raisd.txt

echo "Primeros 10 genes candidatos:"
head genes_candidatos_SANTIAGO_raisd.txt

```
