---
output:
  pdf_document: default
  html_document: default
---
# Día 2 - Taller

# Calidad de los datos

## FastQC y MultiQC

### Solicitar recursos

En primer lugar, para poder correr un análisis en el servidor, tenemos que usar SLURM (Simple Linux Utility for Resource Management). Esto lo podemos hacer mediante un script o, como lo haremos ahora, de forma "interactiva". Para esto, tenemos usar el comando `srun` y distintas *flags* con detalles de lo que solicitaremos a SLURM.

```
srun --nodes=1 --cpus-per-task=8 --time=00:30:00 --mem=8G --pty bash
```

En la línea anterior, `srun` es el comando SLURM que se usa para ejecutar tareas en un trabajo (*job*) asignado (*allocated*). Además, mediante `--nodes` indicamos en cuántos nodos correremos nuestro trabajo; `--cpus-per-task` indica el número de CPUs requeridas para cada tarea; `--time` es el límite de tiempo para el trabajo (*walltime*); `--mem` es la memoria real solicitada por nodo; `--pty` corre la tarea cero en pseudo-terminal, es decir, asigna una pseudo-terminal al trabajo con la que podremos interactuar. Por último, el comando `bash` (o `/bin/bash`) le indica a SLURM qué programa correr usando los recursos asignados, en este caso le indicamos a SLURM ejecutar el programa Bash (*Bourne Again SHell*).

Al ejecutar el comando anterior hemos solicitado recursos (CPUs y memoria) a través de SLURM y ahora podremos disponer de esos recursos para ejecutar los análisis. Podemos ver la información de los trabajos que están corriendo (incluyendo el nuestro) mediante el comando `squeue`. 

```
squeue
```

El comando `squeue` nos permite ver la información y el estado de los trabajos hayan sido enviados a SLURM. Usando este comando podemos ver si el trabajo está corriendo (*running*, **R**), está pendiente a la espera de recursos (*pending*, **PD**), alcanzó su límite de tiempo (*timeout*, **TO**), u otro estado.

### Activar el entorno

Ya que estamos "dentro" del trabajo, necesitamos activar el entorno en el cual instalamos las herramientas o softwares para realizar nuestro análisis. En este caso, correremos FastQC y MultiQC, ambas herramientas fuerons instaladas en el entorno `day1.qc`. Podemos activar el entorno `conda` mediante:

```
conda activate day1.qc
```

### Rutas y carpetas

Para simplificar y ayudarnos a no cometer errores en las rutas de las carpetas o archivos, las asignaremos a variables de entorno. Esto lo haremos definiendo una variable (e.g. `BASE`) a la cual se asignaremos un "valor" específico, en este caso el valor será la ruta `"/mnt/beegfs/home/mvalladares/Curso"`. Luego, podremos usar esa variable durante la sesión interactiva `srun` sin la necesidad de indicar la ruta cada vez. Esta asignación de variables de entorno se puede hacer con rutas (como nuestro caso), elementos, objetos, etc.

```
BASE="/mnt/beegfs/home/mvalladares/Curso"
RAW="${BASE}/RAW"
OUT_QC="${BASE}/QC_pre/fastqc"
OUT_MQC="${BASE}/QC_pre/multiqc"
```

Hemos definido 4 variables: `BASE` es la ruta *base* del Día 1 del curso; `RAW` es la ruta hacia los datos brutos (*.fq.gz), nótese que podemos usar la variable `BASE` para no tener que escribir toda la ruta hacia `RAW`; `OUT_QC` es la ruta de salida donde guardaremos los resultados de FastQC; y `OUT_MQC` es donde guardaremos los resultados de MultiQC. Las carpetas `BASE` y `RAW` ya existen, pero tenemos que crear las carpetas de salida:

```
mkdir -p "${OUT_QC}" "${OUT_MQC}"
````

### Análisis

En primer lugar debemos cambiarnos de directorio a la carpeta donde están los datos brutos. Para esto podemos usar la variable que creamos en el paso anterior.

```
cd "${RAW}"
````

Para correr FastQC usaremos el comando `fastqc` usando las siguientes opciones o argumentos (comúnmente llamados *flags*): (i) que se procesen 8 archivos en paralelo (*threads*, `-t`), y (ii) que los archivos de salida con los resultados se guarden en la carpeta `OUT_QC` (*output directory*, `-o`). Por último, este comando considerando las *flags* indicadas, se correrá sobre todo elemento en la carpeta `RAW` que tenga la extensión `*.fq.gz`.

```
fastqc -t 8 -o "${OUT_QC}" *.fq.gz
```

Antes de correr MultiQC, volveremos a la carpeta base, así podremos indicar correctamente las rutas de entrada y salida. Luego, para correr MultiQC usaremos el comando `multiqc` usando una *flag* que indica que el reporte de salida con los resultados se guarde en la carpeta `OUT_MQC` (*output directory*, `-o`). Este comando, se correrá usando todos los reportes de FastQC que se encuentran en la carpeta `OUT_QC`.

```
cd "${BASE}"
multiqc -o "${OUT_MQC}" "${OUT_QC}"
````

Cerrar srun