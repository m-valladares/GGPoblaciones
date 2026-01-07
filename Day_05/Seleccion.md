
## Taller Práctico: Detección de Señales de Selección en Especies Invasoras


Modelo de Estudio: Rattus rattus (Población Santiago) Objetivo: Identificar loci outliers y genes candidatos bajo selección utilizando múltiples aproximaciones (RAiSD y SweepFinder2).

 ---

## 📂 Estructura de Trabajo

Para optimizar el tiempo, trabajaremos simulando un flujo real pero con "redes de seguridad".

```bash

    ~/Day05/Data: Aquí se encuentran los archivos crudos y copias de seguridad (backups) de todos los resultados. Si un análisis tarda mucho o falla, podrás copiar el archivo desde aquí.

    ~/Day05/Resultados_Estudiante: Esta será tu carpeta de trabajo. Aquí ejecutarás los códigos y guardarás tus salidas.

```

## 0. Configuración Inicial del Espacio de Trabajo

Lo primero es crear tu directorio personal y cargar las herramientas necesarias.


# 1. Cargar módulos necesarios

```bash

module load gsl
module load bcftools
module load bedtools

```

# 2. Crear tu carpeta de resultados

```bash

mkdir -p ~/Day05/Resultados_Estudiante

```

# 3. Ir a la carpeta Data para inspeccionar los archivos

```bash

cd ~/Day05/Data
ls -lh

```

# 4. Copiar el archivo input inicial a tu carpeta de trabajo

```bash
cp santiago.vcf.gz ~/Day05/Resultados_Estudiante/
cp CDS_genes_Rra.bed ~/Day05/Resultados_Estudiante/

```

# 5. Moverse a tu carpeta de trabajo

```bash

cd ~/Day05/Resultados_Estudiante

```

## Parte 1: Método RAiSD 


RAiSD busca una combinación de reducción de diversidad, LD y SFS.

1. Preparación y Ejecución

```bash

# 1. Descomprimir VCF (RAiSD requiere texto plano)

gunzip -c santiago.vcf.gz > santiago.vcf

# 2. Ejecutar RAiSD
# -n: Nombre de la salida
# -I: Input
# -f: Forzar sobreescritura


../../bin_taller/RAiSD -n RUN_SANTIAGO -I santiago.vcf -f

```
(Si el análisis tarda más de 5 minutos, copia RAiSD_Report.RUN_SANTIAGO desde la carpeta ../Data)

2. Procesamiento de Resultados (Filtrado Manual)

El reporte crudo tiene miles de líneas. Vamos a extraer manualmente el Top 1% de los sitios con mayor señal de selección (Columna 7: Estadístico Mu).


```bash

# 1. Ordenar el reporte por score (Col 7) de mayor a menor y quitar encabezados
# grep -v "VAR": Quita la línea de título
# sort -k7,7nr: Orden numérico reverso por columna 7
grep -v "VAR" RAiSD_Report.RUN_SANTIAGO | sort -k7,7nr > raisd_ordenado.txt

# 2. Extraer el Top 200 sitios (aprox top 1% para este set de datos) y crear un BED
# El formato BED requiere: Cromosoma (col1), Inicio (col2), Fin (col3)
head -n 200 raisd_ordenado.txt | awk '{print $1, $2, $3}' > top_raisd.bed

# 3. Cruzar con genes (Anotación)
bedtools intersect -a top_raisd.bed -b CDS_genes_Rra.bed -wb > raisd_hits.txt

# 4. Limpiar lista de genes (Nombres únicos)
cut -f 8 raisd_hits.txt | sort | uniq > genes_candidatos_SANTIAGO_raisd.txt

# Ver resultados
head genes_candidatos_SANTIAGO_raisd.txt

```
## PARTE 2: Método SweepFinder2 (SFS local)

SweepFinder2 detecta barridos selectivos comparando el espectro de frecuencias alélicas (SFS) local contra el genómico.

A diferencia de RAiSD, SweepFinder2 no lee archivos VCF directamente. Requiere un formato específico que contenga la posición genómica y las frecuencias alélicas.

Preparación de Inputs

Para correr SF2, necesitamos dos cosas:

    Un archivo de frecuencias (Input file).

    El espectro de frecuencias genómico (Spectrum).

1. Generación del Archivo de Input

Vamos a transformar nuestro VCF (santiago.vcf) al formato requerido por SweepFinder2. Este paso suele ser computacionalmente costoso porque debe leer línea por línea cada variante.

Instrucciones:

    Ejecuta el comando de conversión.

    Espera unos 30 segundos.

    Si notas que la terminal "se queda pegada" o tarda mucho, cancelaremos el proceso para no perder tiempo del taller.

```bash

# Ejecutar script de conversión (Python)
# Este script toma el VCF y cuenta alelos para crear el input de SF2
python3 ../../bin_taller/vcf2sf.py -i santiago.vcf -o mi_input_lento.sf2

```
⏳ ¡STOP! ¿Notas que tarda? En un genoma completo esto podría tomar horas. Para efectos del taller, vamos a interrumpir este proceso.

    Presiona Ctrl + C en tu teclado para "matar" el proceso.

    Copia el archivo de input ya listo desde la carpeta de Backups.

```bash

# Copiar el archivo pre-calculado
cp ../Data/input_santiago.sf2 .
```
Verificar que lo tenemos (debe pesar algunos MB)
```bash
ls -lh input_santiago.sf2
```
3. Ejecución del Barrido (Scan)

Ahora calculamos el Composite Likelihood Ratio (CLR) a lo largo del cromosoma usando el espectro que acabamos de crear.
```bash
# -l: Calcular LR (Likelihood Ratio)
# 1000: Tamaño de la grilla (puntos a evaluar a lo largo del cromosoma)
../../bin_taller/SweepFinder2 -l 1000 input_santiago.sf2 Spectrum_Santiago.txt Output_SF2_Santiago.txt
```
⏳ (Nuevamente, si este paso tarda más de 2-3 minutos, usa Ctrl+C y copia Output_SF2_Santiago.txt desde ../Data)


4. Procesamiento de Resultados SF2

El archivo de salida tiene coordenadas y valores de CLR, pero necesitamos filtrar los picos más altos.

El formato de salida es: Position | CLR | Alpha.
```bash
# 1. Ver las primeras líneas (observa que puede haber encabezados)
head Output_SF2_Santiago.txt

# 2. Ordenar por CLR (Columna 2) de mayor a menor
# sort -k2,2nr: Ordena numéricamente reverso por la columna 2
# head -n 20: Nos quedamos con los Top 20 sitios
sort -k2,2nr Output_SF2_Santiago.txt | head -n 20 > top_sf2_raw.txt


# 3. Crear un archivo BED para poder cruzarlo con genes
# SF2 nos da un punto exacto (ej. pb 5000).
# Crearemos una ventana de 100pb alrededor de ese punto (4950-5050) para ver qué gen cae cerca.
# Usamos 'awk' para hacer la matemática.
awk '{print "NC_046157.1", int($1)-50, int($1)+50}' top_sf2_raw.txt > top_sf2.bed

# 4. Cruzar con la anotación de genes (Igual que con RAiSD)
bedtools intersect -a top_sf2.bed -b CDS_genes_Rra.bed -wb > sf2_hits.txt

# 5. Obtener lista final de genes candidatos por SF2
cut -f 7 sf2_hits.txt | sort | uniq > genes_candidatos_SANTIAGO_sf2.txt

# Revisar resultado
cat genes_candidatos_SANTIAGO_sf2.txt

```
