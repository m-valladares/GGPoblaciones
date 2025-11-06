# Día 2 - Taller

# Calidad de los datos

## FastQC y MultiQC

### Solicitar recursos usando `srun`

En primer lugar, para poder correr un análisis en el servidor (o nodo), tenemos que solicitar recursos (CPUs y RAM) al clúster usando **SLURM** (Simple Linux Utility for Resource Management). SLURM es un software que funciona como un gestor de cargas de trabajo (*workload manager*) y planificador de trabajos (*__job__ scheduler*).

Sus funciones principales son:
- Asignación de recursos: Otorga a los usuarios acceso exclusivo a recursos informáticos (nodos) durante un tiempo determinado.
- Gestión de trabajos: Provee un framework para iniciar, ejecutar, monitorizar y gestionar las tareas (trabajos) en los nodos asignados.
- Planificación: Administra una cola de trabajos pendientes y decide cuándo y dónde se ejecutarán en el clúster.

En resumen, SLURM es el "cerebro" del clúster HPC que organiza y optimiza cómo se utilizan todos los servidores interconectados. La solicitud de recursos lo podemos hacer mediante un script de shell (`sbatch`) o, como lo haremos ahora, de forma "interactiva". Para esto, tenemos usar el comando `srun` y distintas opciones o argumentos (comúnmente llamados *flags*) con detalles de lo que solicitaremos a SLURM.

```bash
srun --nodes=1 --cpus-per-task=8 --time=02:00:00 --mem=8G --pty bash
```

En la línea anterior, `srun` es el comando SLURM para ejecutar tareas en un trabajo (*job*) asignado (*allocated*). Además, mediante `--nodes` indicamos en cuántos nodos correremos nuestro trabajo; `--cpus-per-task` indica el número de CPUs requeridas para cada tarea; `--time` es el límite de tiempo para el trabajo (*walltime*); `--mem` es la memoria real solicitada por nodo; `--pty` corre la tarea cero en pseudo-terminal, es decir, asigna una pseudo-terminal al trabajo con la que podremos interactuar. Por último, el comando `bash` (o `/bin/bash`) le indica a SLURM qué programa correr usando los recursos asignados, en este caso le indicamos a SLURM ejecutar el programa Bash (*Bourne Again SHell*). En nuestro ejemplo, hemos solicitado 1 nodo, 8 CPUs por tarea y 8 GB de memoria. Una vez asignados estos recursos, dispondremos de ellos por 2 horas.

Cabe mencionar que en el comando anterior hemos indicado nuestras opciones usando *long flags*. Esta convención es más comprensible porque consiste en palabras completas, aunque no es tan flexible o eficiente como usar *short flags*. A continuación se muestra la misma línea de comandos usando *short flags*:

```bash
# No es necesario correr este comando
srun -N 1 -c 8 -t 00:30:00 --mem=8G --pty bash
```

Al ejecutar `srun` hemos solicitado recursos a través de SLURM al clúster y ahora podremos disponer de esos recursos para ejecutar los análisis. Podemos ver la información de los trabajos que están corriendo (incluyendo el nuestro) mediante el comando `squeue`. 

```bash
squeue
```

El comando `squeue` nos permite ver la información y el estado de los trabajos hayan sido enviados a SLURM. Usando este comando podemos ver si el trabajo está corriendo (*running*, **R**), está pendiente a la espera de recursos (*pending*, **PD**), alcanzó su límite de tiempo (*timeout*, **TO**), u otro estado.

### Activar el entorno

Ya que estamos "dentro" del trabajo con recursos asignados y en otro nodo (noten que cambió el `hostname`en el `prompt`), necesitamos activar el entorno en el cual instalamos las herramientas o softwares para realizar nuestro análisis. En este caso, correremos FastQC y MultiQC, ambas herramientas fueron instaladas en el entorno `day2.mv`. Podemos activar el entorno `conda` mediante:

```bash
conda activate day2.mv
```

### Rutas y carpetas

Para simplificar y ayudarnos a no cometer errores en las rutas de las carpetas o archivos, las asignaremos a variables de entorno. Esto lo haremos definiendo una variable (e.g. `BASE`) a la cual se asignaremos un "valor" específico, en este caso el valor será la ruta `"/mnt/beegfs/home/mvalladares/Curso"`. Luego, podremos usar esa variable durante la sesión interactiva `srun` sin la necesidad de indicar la ruta cada vez. Esta asignación de variables de entorno se puede hacer con rutas (como nuestro caso), elementos, objetos, etc.

```bash
BASE="/mnt/beegfs/home/mvalladares/Curso"
RAW="${BASE}/RAW"
OUT_QC="${BASE}/QC_pre/fastqc"
OUT_MQC="${BASE}/QC_pre/multiqc"
```

Hemos definido 4 variables: `BASE` es la ruta *base* del Día 2 del curso; `RAW` es la ruta hacia los datos brutos (`*.fq.gz`), nótese que podemos usar la variable `BASE` para no tener que escribir toda la ruta hacia `RAW`; `OUT_QC` es la ruta de salida donde guardaremos los resultados de FastQC; y `OUT_MQC` es donde guardaremos los resultados de MultiQC. Las carpetas `BASE` y `RAW` ya existen, pero tenemos que crear las carpetas de salida para los resultados:

```bash
mkdir -p "${OUT_QC}" "${OUT_MQC}"
```

## FastQC

En primer lugar debemos cambiarnos de directorio a la carpeta donde están los datos brutos. Para esto podemos usar la variable que creamos en el paso anterior.

```bash
cd "${RAW}"
```

Para correr FastQC usaremos el comando `fastqc` usando las *flags*: (i) que se procesen 8 archivos en paralelo (*threads*, `-t`), y (ii) que los archivos de salida con los resultados se guarden en la carpeta `OUT_QC` (*output directory*, `-o`). Por último, este comando considerando las *flags* indicadas, se correrá sobre todo elemento en la carpeta `RAW` que tenga la extensión `*.fq.gz`.

```bash
fastqc -t 8 -o "${OUT_QC}" *.fq.gz
```

## MultiQC

Antes de correr MultiQC, volveremos a la carpeta base, así podremos indicar correctamente las rutas de entrada y salida. Luego, para correr MultiQC usaremos el comando `multiqc` usando una *flag* que indica que el reporte de salida con los resultados se guarde en la carpeta `OUT_MQC` (*output directory*, `-o`). Este comando, se correrá usando todos los reportes de FastQC que se encuentran en la carpeta `OUT_QC`.

```bash
cd "${BASE}"
multiqc -o "${OUT_MQC}" "${OUT_QC}"
```

Para ver los resultados de ambos análisis debemos descargar las carpetas `fastqc` y `multiqc` desde Visual Studio Code a nuestro computador. Luego, podemos abrir los archivos `html` usando nuestro explorador preferido.