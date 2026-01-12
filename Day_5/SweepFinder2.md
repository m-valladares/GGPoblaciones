# Parte 2: Método SweepFinder2 (SFS local)

**¿En qué se diferencia de RAiSD?**

Mientras que RAiSD usaba múltiples estadísticas (LD, diversidad, etc.), SweepFinder2 (SF2) se basa puramente en el Espectro de Frecuencias Alélicas (SFS).

 - La pregunta que hace SF2: "¿Se parece la distribución de frecuencias de alelos en esta pequeña región a la distribución de todo el genoma?"

 - La señal: Un "barrido selectivo" distorsiona el SFS local, creando un exceso de alelos raros y de alta frecuencia, eliminando la variabilidad intermedia.

## 2.1: Generación del Input (Formato de Conteos)

SF2 no sabe leer archivos VCF. Necesita un formato simplificado que solo le diga: "En la posición X, hay 20 alelos ancestrales y 5 derivados".

Vamos a convertir el VCF (santiago.vcf) al formato de conteo de frecuencias. Este es un proceso computacionalmente costoso, así que haremos una simulación.

```bash

# 1. Transformar VCF a formato SF2
# Usamos un script auxiliar 'vcf2sf2.sh'
# Sintaxis: vcf2sf2.sh <INPUT_VCF> <OUTPUT_NAME>
# Asegúrate de estar en tu carpeta: ~/Day05/Resultados_Estudiante

vcf2sf2.sh santiago.vcf mi_input_lento.sf2

```
🛑 ¡STOP! (Simulación) Verás un contador de progreso en la pantalla (Leyendo variante n°...).En un cromosoma entero con millones de SNPs, esto tardaría 15-20 minutos.

 1. Observa cómo funciona el script por unos segundos.

 2. Presiona Ctrl + C para cancelar el proceso y no perder tiempo.

 3. Copia el archivo listo desde la carpeta de respaldo:

```bash

# Copiar input listo desde la carpeta Data
cp ../Data/input_santiago.sf2 .

# Verificar que lo tienes (Debe pesar unos MB)
ls -lh input_santiago.sf2

```
Cuando copiamos un archivo desde un directorio podemos indicarle un directorio de destino o con un "." le indicamos que la copia se haga en el directorio que estoy posicionado (~/Day05/Resultados_Estudiante)

## 2.2 Calcular el Espectro de Frecuencias (Spectrum)

Antes de buscar selección, necesitamos calcular el "modelo nulo": ¿Cómo se comportan las frecuencias alélicas en promedio en todo este cromosoma?

```bash

# 2. Calcular el Espectro de Frecuencias (SFS) empírico
# -f: Calcular frequency spectrum
# Sintaxis: SweepFinder2 -f <Input> <Output_Spectrum>
SweepFinder2 -f input_santiago.sf2 Spectrum_Santiago.txt

```
*(Este paso es rápido. Debería terminar en unos segundos).*

## 2.3 Ejecución del Barrido (Scan CLR)

**La Grilla (The Grid)**

Aquí hay una diferencia fundamental con RAiSD.

RAiSD evalúa cada SNP individualmente.

SweepFinder2 evalúa una Grilla de Puntos teóricos a lo largo del cromosoma. Nosotros definiremos una grilla de 1000 puntos. Esto significa que pondremos una "sonda" cada ~270kb (ventana) para ver si hay señales de selección cerca.


```bash

# 3. Correr el Scan de Likelihood Ratio (CLR)
# -l: Calcular LR (Likelihood Ratio)
# 1000: Tamaño de la grilla (evaluará 1000 puntos a lo largo del cromosoma)
SweepFinder2 -l 1000 input_santiago.sf2 Spectrum_Santiago.txt Output_SF2_Santiago.txt

```
⏳ Atención: Si este paso tarda más de 2-3 minutos en tu terminal, cancélalo con Ctrl + C y copia el resultado final:

```bash

cp ../Data/Output_SF2_Santiago.txt .

```

## 2.4 Procesamiento y Definición de Ventanas

El archivo de salida contiene: Position | CLR | Alpha. Nos interesan los sitios con el CLR (Likelihood Ratio) más alto.

Pero aquí surge un problema biológico: SF2 nos dice "Hay una señal fuerte en la posición 50,000". Pero como estamos evaluando puntos en una grilla, el gen causal podría no estar exactamente en el punto 50,000, sino cerca, arrastrado por el Desequilibrio de Ligamiento (LD).

Probaremos dos estrategias para capturar los genes.

### A. Preparación de datos (Top 5%)

Seleccionaremos el 5% de los puntos con mayor señal (CLR).

```bash
# 1. Ordenar por CLR (Columna 2) de mayor a menor
sort -k2,2gr Output_SF2_Santiago.txt > sf2_ordenado.txt

# 2. Calcular dinámicamente el Top 5%
# Dividimos el total de líneas por 20 para obtener el 5%
TOTAL_PUNTOS=$(wc -l < sf2_ordenado.txt)
UMBRAL=$(( TOTAL_PUNTOS / 20 ))

echo "Puntos evaluados: $TOTAL_PUNTOS. Seleccionando Top 5% ($UMBRAL puntos)..."

```
# B. Escenario 1: Búsqueda Estricta (±2 kb)

Asumimos que la señal está muy cerca del gen.

```bash

# Crear BED con ventana pequeña (punto +/- 2000 pb)
# Nota: "NC_046154.1" es el código del Cromosoma 1 de Rattus rattus
head -n $UMBRAL sf2_ordenado.txt | \
awk -v OFS='\t' '{print "NC_046154.1", int($1)-2000, int($1)+2000, $2}' > top_sf2_strict.bed

# Cruzar con genes
bedtools intersect -a top_sf2_strict.bed -b CDS_genes_Rra.bed -wb > hits_strict.txt
echo "Genes encontrados (Criterio Estricto):"
cut -f 8 hits_strict.txt | sort | uniq | wc -l

```

* (Probablemente obtengas pocos genes, ~8).*

# C. Escenario 2: Búsqueda Amplia (±10 kb) - DEFINITIVO

En genética de poblaciones real, la señal de selección deace a medida que nos alejamos del sitio causal debido a la recombinación. Dado que nuestra grilla no es tan densa, debemos ampliar la búsqueda para no perder el gen candidato.

```bash

# Crear BED con ventana amplia (±10000 pb)
head -n $UMBRAL sf2_ordenado.txt | \
awk -v OFS='\t' '{print "NC_046154.1", int($1)-10000, int($1)+10000, $2}' > top_sf2_wide.bed

# Cruzar con genes
bedtools intersect -a top_sf2_wide.bed -b CDS_genes_Rra.bed -wb > sf2_hits.txt

# Generar lista limpia FINAL
cut -f 8 sf2_hits.txt | sort | uniq > genes_candidatos_SANTIAGO_sf2.txt

# Ver resultados
echo "------------------------------------------------------"
echo "Genes encontrados (Criterio Amplio):"
wc -l genes_candidatos_SANTIAGO_sf2.txt
echo "------------------------------------------------------"

echo "Primeros candidatos de SweepFinder2:"
head genes_candidatos_SANTIAGO_sf2.txt

```
*(Deberías obtener ~16 genes. Usaremos esta lista para la comparación final).*

Nota para investigación.

En el comando SweepFinder2 -l 1000 usamos 1000 puntos por rapidez.

 - En una investigación real, querrán una resolución mucho mayor (ej. un punto cada 1kb o 2kb).
 - Esto aumentará el tiempo de cómputo, pero les permitirá usar ventanas de búsqueda más estrechas (Escenario 1) y tener mayor precisión sobre qué gen es el responsable.