## Parte 2: Método SweepFinder2 (SFS local)

SweepFinder2 (SF2) detecta barridos selectivos comparando el espectro de frecuencias alélicas (SFS) local contra el SFS genómico global.

A diferencia de RAiSD, SF2 no lee archivos VCF directamente; requiere un formato propio que lista la posición genómica y el conteo de alelos.


1. Generación del Archivo de Input

Transformaremos el VCF (santiago.vcf) al formato de conteo de frecuencias.

    ⚠️ Nota: Aunque este método es eficiente, en un genoma completo puede tardar. Lo iniciaremos para ver cómo funciona y luego usaremos el archivo de respaldo para ahorrar tiempo.

```bash

# Sintaxis: vcf2sf2.sh <INPUT_VCF> <OUTPUT_NAME>
# Asegúrate de estar en tu carpeta: ~/Day05/Resultados_Estudiante

vcf2sf2.sh santiago.vcf mi_input_lento.sf2

```
🛑 ¡STOP! (Simulación) Verás un contador de progreso en la pantalla (Leyendo variante n°...).

    1. Observa cómo avanza el contador. ¡Son millones de sitios!

    2. Una vez que compruebes que avanza, presiona Ctrl + C para cancelar el proceso y ahorrar tiempo.

    3. Copia el archivo que ya tenemos pre-calculado para la clase:

```bash

# Copiar input listo desde la carpeta Data
cp ../Data/input_santiago.sf2 .

# Verificar que lo tienes (Debe pesar unos MB)
ls -lh input_santiago.sf2

```

2. Calcular el Espectro de Frecuencias (Spectrum)

Antes de buscar selección, necesitamos calcular el "modelo nulo": ¿Cómo se comportan las frecuencias alélicas en promedio en todo este cromosoma?

```bash

# -f: Calcular frequency spectrum
# Sintaxis: SweepFinder2 -f <Input> <Output_Spectrum>
SweepFinder2 -f input_santiago.sf2 Spectrum_Santiago.txt

```
*(Este paso es rápido. Debería terminar en unos segundos).*

3. Ejecución del Barrido (Scan CLR)

Ahora calculamos el Composite Likelihood Ratio (CLR) a lo largo del cromosoma. SF2 moverá una ventana teórica calculando la probabilidad de un barrido selectivo en cada punto de la grilla.

```bash

# -l: Calcular LR (Likelihood Ratio)
# 1000: Tamaño de la grilla (evaluará 1000 puntos a lo largo del cromosoma)
SweepFinder2 -l 1000 input_santiago.sf2 Spectrum_Santiago.txt Output_SF2_Santiago.txt

```
⏳ Atención: Si este paso tarda más de 3 minutos, presiona Ctrl + C y copia el resultado:

```bash

cp ../Data/Output_SF2_Santiago.txt .

```

4. Procesamiento de Resultados (Filtrado Top 1%)

El archivo de salida contiene: Position | CLR | Alpha. Nos interesan los sitios con el CLR (Likelihood Ratio) más alto.

A diferencia de RAiSD, aquí hemos evaluado puntos espaciados (cada ~270kb). Esto nos plantea una duda biológica: ¿Qué tan lejos de la señal detectada debemos buscar el gen causal?

Probaremos dos escenarios para filtrar nuestros candidatos.

# A. Preparación de datos (Top 5%)

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

# Crear BED con ventana pequeña (±2000 pb)
head -n $UMBRAL sf2_ordenado.txt | \
awk -v OFS='\t' '{print "NC_046154.1", int($1)-2000, int($1)+2000, $2}' > top_sf2_strict.bed

# Cruzar con genes y contar
bedtools intersect -a top_sf2_strict.bed -b CDS_genes_Rra.bed -wb > hits_strict.txt
echo "Genes encontrados (Criterio Estricto):"
cut -f 8 hits_strict.txt | sort | uniq | wc -l

```

* (Probablemente obtengas pocos genes, ~8).*

# C. Escenario 2: Búsqueda Amplia (±10 kb) - DEFINITIVO

Considerando el Desequilibrio de Ligamiento (LD) y la baja resolución de la grilla, es probable que la señal detectada provenga de un gen vecino más lejano.

```bash

# Crear BED con ventana amplia (±10000 pb)
head -n $UMBRAL sf2_ordenado.txt | \
awk -v OFS='\t' '{print "NC_046154.1", int($1)-10000, int($1)+10000, $2}' > top_sf2_wide.bed

# Cruzar con genes
bedtools intersect -a top_sf2_wide.bed -b CDS_genes_Rra.bed -wb > sf2_hits.txt

# Generar lista limpia FINAL
cut -f 8 sf2_hits.txt | sort | uniq > genes_candidatos_SANTIAGO_sf2.txt

# Ver resultados
echo "Genes encontrados (Criterio Amplio):"
wc -l genes_candidatos_SANTIAGO_sf2.txt

echo "Primeros candidatos:"
head genes_candidatos_SANTIAGO_sf2.txt

```
*(Deberías obtener ~16 genes. Usaremos esta lista para la comparación final).*
