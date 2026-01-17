# FILOGENOMICA: Reconstrucción de Árboles de Especies

## *Multispecies coalescent model* (MSC) usando ASTRAL

### 1. El Modelo de Coalescencia Multiespecies (MSC)
La reconstrucción del árbol de especies se basa en aproximaciones estadísticamente consistentes con el modelo MSC (Multispecies Coalescent).

En este flujo de trabajo, utilizaremos el método de resumen (*summary method*) implementado en ASTRAL-III. ASTRAL utiliza árboles de genes individuales previamente estimados (en este caso, mediante RAxML) para inferir, mediante un método heurístico, el árbol de especies más probable.

### 2. Reconstrucción utilizando ASTRAL-III
ASTRAL-III (*Accurate Species TRee ALgorithm*) es una herramienta diseñada para estimar árboles de especies a partir de un conjunto de árboles de genes no enraizados, por tanto el árbol de especies generado por ASTRAL tampoco es enraizado. Sus principales características son:

- Consistencia Estadística: Es una de las herramientas más robustas para manejar la discordancia entre genes causada por el ordenamiento incompleto de linajes (ILS).

- Optimización de Cuartetos: Resuelve el problema de optimización buscando el árbol de especies que maximiza el número de árboles cuarteto (quartet trees) inducidos por los árboles de genes.

- Naturaleza del Árbol: Dado que utiliza árboles de genes no enraizados como entrada, el árbol de especies resultante también es no enraizado.

- Portabilidad: Al ser una aplicación basada en Java, no cuenta con una interfaz gráfica (GUI) y se ejecuta mediante línea de comandos en cualquier entorno (Linux, Windows, MacOS), lo que facilita su integración en clústeres de alto rendimiento (HPC).

## Selección de Datos y Marcadores Genómicos
Para este análisis, se utilizó una fracción de los datos genómicos generados en el estudio de Morales et al. (2024), el cual exploró la historia evolutiva de los peces del género *Orestias* en el Altiplano andino. En dicho trabajo, tras un proceso de filtrado de ortólogos, se identificó un set de 902 genes compartidos (ortólogos) entre los genomas analizados.

Para este práctico, se seleccionó un subconjunto de 100 genes del set original, con el que ejecutaremos el flujo de trabajo, desde la inferencia de árboles de genes individuales en RAxML hasta la estimación del árbol de especies en ASTRAL.



### Crear ambiente para RAxML y Astral III

```bash
conda create -n raxml_astral -c bioconda raxml astral-tree=5.7.8 -y
```

#### Cargar ambiente

```bash
conda activate raxml_astral
```

#### Revisar que corre

```bash
raxmlHPC-PTHREADS-SSE3 -v
```

### RAxML para 100 genes


```bash
cp -r \
  /home/courses/student22/Day06/ \
  /home/courses/${USER}/
```

```bash
cd Day06
```

Ahora se puede lanzar el job con el script `raxml.sh`. 

Este script entrará al directorio `RAXML/` donde se encuentran los alineamientos de los 100 genes en formato `.fasta` (a pesar de que el sufijo de estos archivos es `*.out-gb`).


```bash
sbatch raxml.sh
```

El script `raxml.sh` es de la siguiente forma:

```bash

#!/bin/bash
#SBATCH -J=raxml
#SBATCH -p labs
#SBATCH -c 2
#SBATCH --mem=2G
#SBATCH -t 12:00:00
#SBATCH -o raxml_%j.out
#SBATCH -e raxml_%j.err

set -euo pipefail

# 1. Cargar el ambiente
module load miniconda3/24.7.1-zen4-5
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate raxml_astral

# 2. Entrar al directorio de trabajo, cambiar si es necesario
cd /home/courses/$USER/Day06/RAXML

# 3. Loop para procesar cada archivo .out-gb (.fasta)
for f in *.out-gb
do
    # Definir un nombre base para los resultados (ej. si el archivo es gen1.out-gb, el ID será gen1)
    ID=${f%.out-gb}

    echo "Procesando: $ID"

    # Ejecutar RAxML
    # -p: semilla aleatoria
    # -m: modelo (GTRGAMMA es el estándar)
    # -s: archivo de entrada (todos los fasta en el loop)
    # -n: sufijo para los archivos de salida
    # -T: número de hilos (coincide con -c indicado en el #SBATCH)
    raxmlHPC-PTHREADS-SSE3 -T $SLURM_CPUS_PER_TASK -m GTRGAMMA -p 12345 -s "$f" -n "$ID"

    # 4. Ir acumulando los "bestTrees" en el archivo único ASTRAL
    if [ -f "RAxML_bestTree.$ID" ]; then
        cat "RAxML_bestTree.$ID" >> ASTRAL_trees.tre
    fi
done

echo "Todos los árboles están en ASTRAL_trees.tre"

```

Este script correrá RAxML para cada uno de los 100 genes del depositorio `RAXML/`. Para ir verificando el avance se puede ir contando el número de archivos de ese directorio:

```bash
ls RAXML | wc -l
```

También se puede ir revisando el final del archivo `.out`

```bash
# Remplazar %j por el job ID 

tail raxml_%j.out

```

Una vez terminado este proceso, se tendrán 677 archivo en el directorio `RAXML/`. Entre ellos, se encontrará el archivo `ASTRAL_trees.tre` que contiene los árboles de los 100 genes concatenados. Éste es el archivo que utilizará ASTRAL para reconstruir el árbol de especies.

---

### ASTRAL-III

Entren al directorio `RAXML/Resultados` donde encontrarán los resultados del paso anterior:

```bash
cd RAXML/Resultados
```

#### Pedir recursos

```bash
srun -p labs -n 1 -c 8 --mem-per-cpu=1000 --pty bash
```

#### Activar ambiente

```bash
conda activate raxml_astral
```

#### Si no pueden activar ambiente

```bash
conda init
source ~/.bashrc
```

#### Luego, podemos correr ASTRAL

```bash
astral -i ASTRAL_trees.tre -o ASTRAL_Orestias.tre
```

Esto implica correr ASTRAL: indicamos que el archivo de entrada corresponde a los árboles de genes generados en RAxML (`-i ASTRAL_trees.tre`), y definimos el nombre del archivo de resultados o árbol de especies (`-o ASTRAL_Orestias.tre`).

Ahora puedes descargar este último archivo a tu computador y verlo gráficamente con algún programa como FigTree.

---

