 # Variant Calling

Una vez que contamos con archivos BAM limpios, ordenados e indexados, el siguiente paso del pipeline es el llamado de variantes (*Variant Calling*).
Este proceso consiste en identificar posiciones del genoma donde las secuencias de una o más muestras difieren respecto al genoma de referencia, típicamente en forma de SNPs (Single Nucleotide Polymorphisms) o indels.

Las variantes constituyen la base de prácticamente todos los análisis en genómica poblacional: estructura genética, diversidad, selección natural, demografía y flujo génico, entre otros.

En este curso abordaremos dos enfoques complementarios, que responden a distintos tipos de datos:
- **FreeBayes** ([Garrison & Marth, 2012](https://doi.org/10.48550/arXiv.1207.3907)) → datos de alta cobertura (WGS > 30–50X), con llamado explícito de genotipos (*hard genotypes*)
- **ANGSD** ([Korneliussen et al., 2014](https://doi.org/10.1186/s12859-014-0356-4)) → datos de baja cobertura (lcWGS), usando genotype likelihoods en lugar de genotipos fijos

---
## 4. Enfoques de llamado de variantes

### 4.1 Genotipos “duros” vs. Genotype Likelihoods

Antes de entrar en los comandos, es clave entender la diferencia conceptual entre ambos enfoques.

FreeBayes asume que:
- cada posición del genoma puede asignarse a un genotipo concreto (0/0, 0/1, 1/1)
- la cobertura es suficientemente alta como para distinguir señal biológica de ruido técnico

ANGSD, en cambio:
- no asigna genotipos directamente
- calcula la probabilidad de cada genotipo dado el conjunto de reads observados (estima *genotype likelihoods*)
- es ideal cuando la cobertura es baja (ej. < 10X), donde el llamado “duro” sería poco confiable

Esta distinción es fundamental y explica por qué no todos los datasets deben analizarse con el mismo pipeline, aun cuando el objetivo biológico sea similar.

---
### 4.2 Parte A — Variant Calling con FreeBayes (alta cobertura)

#### Organización de carpetas

Seguiremos la misma lógica de orden que en las secciones anteriores. Dentro de Day02 trabajaremos con la siguiente estructura:

```bash
Day02/
├── BAM/          # BAMs finales (nodup + indexados)
├── REF/          # Genoma de referencia
├── VARIANT/
│   ├── raw_vcf/  # VCFs sin filtrar
│   └── filt_vcf/ # VCFs filtrados
├── scripts/
└── LOGS/
```

Para este ejercicio, usaremos nuevamente *Drosophila suzukii* con alta cobertura, y solo el primer autosoma del genoma.

### 4.3 Ambiente conda para Variant Calling (FreeBayes)

Usaremos un ambiente dedicado para evitar conflictos con el ambiente de mapeo.

```bash
conda deactivate
module purge
module load miniconda3/24.7.1-zen4-5

conda create -n droso_vc \
  -c bioconda \
  -c conda-forge \
  freebayes \
  bcftools \
  samtools
```

Activamos el ambiente:

```bash
conda activate droso_vc
```

<details>
<summary><strong>Si no pudieron activar el ambiente</strong></summary>


**Solo en caso que solicite iniciar conda**, indicaremos `conda init`. Y luego, para poder activar ambientes conda en la sesión actual, recargamos la configuración del shell:

```bash
# Primero corremos
conda init

# Luego, usamos el comando
source ~/.bashrc
```

Tras estas instrucciones se pueden activar los ambientes nuevamente.

</details>

### 4.4 ¿Qué hace FreeBayes?

FreeBayes es un variant caller haplotípico, lo que significa que:
- evalúa múltiples posiciones simultáneamente
- considera la información de reads pareados
- infiere variantes a nivel de haplotipos locales

A diferencia de enfoques más antiguos basados solo en pileup, FreeBayes modela explícitamente la variación genética esperada en poblaciones.

### 4.5 Preparación de archivos y rutas

Para realizar el llamado de variantes, utilizaremos un script de SLURM que procesará nuestras muestras de "alta cobertura". A diferencia del mapeo, donde procesamos muestra por muestra, en el llamado de variantes es común (y recomendado) realizar un llamado conjunto (joint calling), donde FreeBayes observa todas las muestras simultáneamente para aumentar la potencia estadística en sitios con baja cobertura en alguna muestra particular.

Cuando trabajamos con proyectos de genómica de poblaciones, el volumen de datos puede ser enorme. Si intentamos procesar todo el genoma en un solo hilo, el análisis podría tardar días y, si el sistema falla, perderíamos todo el progreso.

Para optimizar este proceso, utilizaremos una **estrategia por ventanas**:
1. División en ventanas: Dividiremos nuestro cromosoma en fragmentos o "ventanas" de un tamaño definido (ej. 150 kb).
2. Paralelización: Ejecutaremos FreeBayes sobre múltiples ventanas de forma simultánea. Por ejemplo, podemos procesar 10 ventanas a la vez, reduciendo drásticamente el tiempo total.
3. Concatenación: Una vez que todas las ventanas han terminado, uniremos los archivos resultantes para obtener un único VCF genómico.
4. Reanudable: Si el análisis se interrumpe, solo perdemos las ventanas que estaban en ejecución en ese momento, permitiéndonos retomar el trabajo sin empezar de cero.

Antes de lanzar el llamado de variantes, necesitamos preparar dos archivos de control que le indicarán a las herramientas qué muestras procesar y en qué regiones enfocarse.
1. Listado de muestras (BAM list): en lugar de escribir las rutas de cada muestra manualmente en el script, generaremos un archivo de texto que contenga las rutas absolutas de todos nuestros archivos BAM finales.

```bash
# Navegamos a nuestra carpeta de trabajo del Día 02
cd /home/courses/${USER}/Day02

# Listamos todos los archivos .bam y guardamos sus rutas
ls /home/courses/${USER}/Day02/MAP/bam/*.nodup.bam > bamlist.txt
```

2. Definición de regiones genómicas: utilizaremos el índice del genoma de referencia (.fai) que creamos para el mapeo para segmentar el cromosoma en ventanas de 150,000 pares de bases (150 kb). Para esto, empleamos un comando de `awk` que calcula las coordenadas de inicio y fin para cada segmento.

```bash
# Generamos el archivo de regiones
awk -v size=150000 '{ 
    for(i=0; i<$2; i+=size) { 
        j=i+size; 
        if(j>$2) j=$2; 
        printf "%s:%d-%d\n", $1, i+1, j 
    } 
}' /home/courses/${USER}/Day02/REF/Dsuzukii.chrNC_092080.1.fa.fai > regions.txt
```

¿Qué contiene regions.txt? Si revisamos este archivo con `head regions.txt`, veremos líneas con el formato Cromosoma:Inicio-Fin (por ejemplo, NC_092080.1:1-150000). Cada una de estas líneas es una de las ventanas definidas y será una tarea independiente para nuestro pipeline.


<details>
<summary><strong>Entendiendo el comando <code>awk</code></strong></summary>

El comando `awk` lee el archivo de índice del genoma (.fai), el cual tiene una estructura simple de columnas: la columna 1 es el nombre del cromosoma y la columna 2 es su longitud total en pares de bases.

```bash
chrNC_092080.1	26650000	16	80	81
```

Aquí el desglose paso a paso de `awk`:
- `-v size=150000`: Creamos una variable dentro de `awk` llamada `size`. Esto define el largo de nuestra ventana (150 kb). Si quisiéramos ventanas más grandes, solo cambiamos este número.
- `for(i=0; i<$2; i+=size)`: Este es un bucle (*loop*). Le dice a `awk`: "empieza en la posición 0 (`i=0`), y mientras no hayas llegado al final del cromosoma (`$2`, que es la longitud en la columna 2), avanza saltando de 150 kb en 150 kb".
- `j=i+size`: Aquí calculamos dónde termina cada ventana.
- `if(j>$2) j=$2`: Esta es una medida de seguridad. Si al sumar los 150 kb nos pasamos del final real del cromosoma, le decimos que el final de esa última ventana sea exactamente el final del cromosoma (`$2`).
- `printf "%s:%d-%d\n", $1, i+1, j`: Finalmente, imprimimos el resultado con el formato que FreeBayes necesita:
  - `%s`: El nombre del cromosoma (columna `$1`).
  - `:`: El separador.
  - `%d-%d`: Las coordenadas de inicio (`i+1`) y fin (`j`).
  - `\n`: Un salto de línea para que cada región quede en una fila distinta.

</details>

