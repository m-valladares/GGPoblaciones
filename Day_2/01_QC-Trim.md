# Calidad de los datos y trimeo

El objetivo de esta sesión es verificar la calidad de las secuencias y aprender algunos índices tradicionales para describir esta calidad. Para esto usaremos los programas `FastQC` y `MultiQC`. También realizaremos el trimeo de adaptadores y reads de mala calidad usando `fastp`. Con estos pasos dejaremos el set de datos preparado para realizar el mapeo de los reads y proceder con el llamado de variantes.

Antes de comenzar necesitamos copiar los datos que usaremos y el árbol de directorios desde la cuenta `student21`:

```bash
# No olviden cambiar studentXX por el nombre real de su cuenta.
cp -r /home/courses/student21/Day02 /home/courses/studentXX
```


 ---

## 1. FastQC y MultiQC

### 1.1 Solicitar recursos usando `srun`

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
# srun -N 1 -c 8 -t 00:30:00 --mem=8G --pty bash
```

Al ejecutar `srun` hemos solicitado recursos a través de SLURM al clúster y ahora podremos disponer de esos recursos para ejecutar los análisis. Podemos ver la información de los trabajos que están corriendo (incluyendo el nuestro) mediante el comando `squeue`. 

```bash
squeue
```

El comando `squeue` nos permite ver la información y el estado de los trabajos hayan sido enviados a SLURM. Usando este comando podemos ver si el trabajo está corriendo (*running*, **R**), está pendiente a la espera de recursos (*pending*, **PD**), alcanzó su límite de tiempo (*timeout*, **TO**), u otro estado.


### 1.2 Rutas y carpetas

Para simplificar y ayudarnos a no cometer errores en las rutas de las carpetas o archivos, las asignaremos a variables de entorno. Esto lo haremos definiendo una variable (e.g. `BASE`) a la cual se asignaremos un "valor" específico, en este caso el valor será la ruta `"/mnt/beegfs/home/mvalladares/Curso"`. Luego, podremos usar esa variable durante la sesión interactiva `srun` sin la necesidad de indicar la ruta cada vez. Esta asignación de variables de entorno se puede hacer con rutas (como nuestro caso), elementos, objetos, etc.

```bash
# No olviden cambiar studentXX por el nombre real de su cuenta.
BASE="/home/courses/studentXX/Day02"
RAW="${BASE}/RAW"
OUT_QC="${BASE}/QC_pre/fastqc"
OUT_MQC="${BASE}/QC_pre/multiqc"
```

Hemos definido 4 variables: `BASE` es la ruta *base* del Día 2 del curso; `RAW` es la ruta hacia los datos brutos (`*.fq.gz`), nótese que podemos usar la variable `BASE` para no tener que escribir toda la ruta hacia `RAW`; `OUT_QC` es la ruta de salida donde guardaremos los resultados de FastQC; y `OUT_MQC` es donde guardaremos los resultados de MultiQC. Las carpetas `BASE` y `RAW` ya existen, pero tenemos que crear las carpetas de salida para los resultados:

```bash
mkdir -p "${OUT_QC}" "${OUT_MQC}"
```

---

## 2. FastQC

Antes de comenzar, debemos cargar los módulos que necesitamos para FastQC. En este caso, además de FastQC, necesitamos Perl así que lo cargaremos primero.

```bash
module load perl/5.40.0-zen4-p
module load FastQC/0.11.9-Java-11
```

Luego, debemos cambiarnos de directorio a la carpeta donde están los datos brutos. Para esto podemos usar la variable que creamos en el paso anterior.

```bash
cd "${RAW}"
```

Para correr FastQC usaremos el comando `fastqc` usando las *flags*: (i) que se procesen 8 archivos en paralelo (*threads*, `-t`), y (ii) que los archivos de salida con los resultados se guarden en la carpeta `OUT_QC` (*output directory*, `-o`). Por último, este comando considerando las *flags* indicadas, se correrá sobre todo elemento en la carpeta `RAW` que tenga la extensión `*.fq.gz`.

```bash
fastqc -t 8 -o "${OUT_QC}" *.fq.gz
```

Una vez que termine, los resultados quedarán en `/home/courses/studentXX/Day02/QC_pre/fastqc`. Para ver los resultados debemos descargar la carpeta `fastqc` desde Visual Studio Code a nuestro computador. Luego, podemos abrir los archivos `html` usando nuestro explorador preferido.

FastQC ([Andrews, 2010](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)) es una herramienta de control de calidad que evalúa distintos aspectos de las lecturas de secuenciación (FASTQ) antes de los análisis posteriores. Sus resultados se presentan como una serie de gráficos y estadísticas, cada uno acompañado de un estado (pass, warning o fail).

Los principales módulos que entrega FastQC son:
- **Basic Statistics:** resumen general del archivo, incluyendo número de lecturas, longitud de las secuencias y contenido global de GC. Sirve como chequeo inicial para verificar que los datos coincidan con lo esperado.
- **Per Base Sequence Quality:** muestra la distribución de la calidad (Phred) en cada posición de la lectura. Es uno de los gráficos más importantes, ya que permite detectar caídas de calidad hacia los extremos de las reads.
- **Per Sequence Quality Scores:** evalúa la calidad promedio por lectura completa, útil para identificar si existe un subconjunto de lecturas de muy baja calidad.
- **Per Base Sequence Content:** indica la proporción de cada nucleótido (A, T, C, G) en cada posición. Desbalances fuertes pueden sugerir sesgos técnicos, especialmente al inicio de las lecturas.
- **Per Sequence GC Content:** compara la distribución de GC observada con una esperada. Desviaciones importantes pueden indicar contaminación o mezcla de orígenes genómicos.
- **Sequence Length Distribution:** muestra la longitud de las lecturas. Es especialmente relevante si se han aplicado pasos de trimming o filtrado.
- **Sequence Duplication Levels:** estima el nivel de duplicación de lecturas, lo que puede reflejar baja complejidad de librería o sobre-amplificación por PCR.
- **Overrepresented Sequences:** identifica secuencias que aparecen con frecuencia inusualmente alta, comúnmente asociadas a adaptadores, primers o contaminantes.
- **Adapter Content:** detecta la presencia de adaptadores a lo largo de las lecturas, indicando si es necesario realizar trimming antes del mapeo.

En conjunto, FastQC permite evaluar rápidamente la calidad global de los datos, detectar problemas técnicos comunes y decidir si es necesario aplicar pasos adicionales de limpieza antes de continuar con los análisis genómicos.

---

## 3. MultiQC

Nuevamente, debemos cargar los módulos necesarios. En este caso, además de MultiQC, necesitamos dos dependencias que cargaremos primero:

```bash
module load intel-compilers/2022.0.1 impi/2021.5.0
module load MultiQC/1.14
```

Antes de correr MultiQC, volveremos a la carpeta base, así podremos indicar correctamente las rutas de entrada y salida. Luego, para correr MultiQC usaremos el comando `multiqc` usando una *flag* que indica que el reporte de salida con los resultados se guarde en la carpeta `OUT_MQC` (*output directory*, `-o`). Este comando, se correrá usando todos los reportes de FastQC que se encuentran en la carpeta `OUT_QC`.

```bash
cd "${BASE}"
multiqc -o "${OUT_MQC}" "${OUT_QC}"
```

Recuerden que para ver los resultados debemos descargar la carpeta `multiqc` desde Visual Studio Code a nuestro computador. Luego, podemos abrir los archivos `html` usando nuestro explorador preferido.

MultiQC ([Ewels et al., 2016](https://doi.org/10.1093/bioinformatics/btw354)) es una herramienta que integra y resume los resultados de control de calidad generados por múltiples programas (como FastQC y fastp) y por múltiples muestras, en un único reporte HTML. Su objetivo principal es facilitar la comparación entre muestras y obtener una visión global del dataset.

En el contexto del curso, MultiQC se utiliza principalmente para agrupar y sintetizar los resultados de FastQC, evitando revisar archivos individuales uno por uno.

Los principales elementos que entrega MultiQC son:
- **General Statistics:** una tabla resumen donde cada fila corresponde a una muestra y cada columna a una métrica clave (por ejemplo, número de lecturas, calidad media, porcentaje de GC, niveles de duplicación). Esta tabla permite comparar rápidamente la calidad entre muestras e identificar outliers.
- **Resumen de estados (pass/warning/fail):** MultiQC consolida los estados de FastQC para cada módulo, lo que ayuda a detectar patrones sistemáticos de advertencias o fallas en varias muestras.
- **Gráficos agregados de calidad:** combina los gráficos de FastQC (por ejemplo, calidad por base o contenido GC) mostrando distribuciones globales o superpuestas, lo que permite evaluar la consistencia de la calidad a lo largo de todo el conjunto de datos.
- **Distribución de longitudes de lectura:** muestra de forma comparativa si todas las muestras tienen longitudes similares o si algunas fueron más afectadas por trimming o filtrado.
- **Duplicación y complejidad:** resume los niveles de duplicación entre muestras, útil para detectar librerías con baja complejidad o problemas de amplificación.
- **Contenido de adaptadores y secuencias sobre-representadas:** permite evaluar si el trimming fue necesario o efectivo, y si aún persisten señales de adaptadores o contaminantes.

En conjunto, MultiQC transforma múltiples reportes individuales en una visión integrada del control de calidad, facilitando la toma de decisiones sobre limpieza de datos y asegurando consistencia antes de avanzar a etapas como mapeo o llamado de variantes.


---

## 2. Trimming

El trimming (o trimeo) es el proceso mediante el cual se recortan o eliminan partes no deseadas de las lecturas de secuenciación antes de realizar análisis posteriores, como el mapeo o el llamado de variantes. Su objetivo principal es mejorar la calidad de los datos, reduciendo el impacto de errores técnicos propios del proceso de secuenciación.

Durante la secuenciación, es común que:
	•	la calidad de las bases disminuya hacia los extremos de las lecturas
	•	queden restos de adaptadores o primers
	•	existan bases de muy baja calidad que introducen ruido en los análisis

Si estas regiones no se eliminan, pueden provocar:
	•	mapeos incorrectos o ambiguos
	•	disminución de la eficiencia de alineamiento
	•	falsos positivos en análisis posteriores

Por estas razones, el trimming es un paso estándar en la mayoría de los pipelines genómicos.

Existen varios programas para realizar trimming de lecturas, entre ellos Trimmomatic, Cutadapt, Trim Galore y fastp, cada uno con enfoques y características particulares. En este curso utilizaremos fastp, una herramienta moderna y eficiente que integra en un solo paso el trimming por calidad, la detección y eliminación de adaptadores, y la generación de reportes de control de calidad, lo que la hace especialmente adecuada para flujos de trabajo en HPC y para fines docentes.


### 1.1 Solicitar recursos usando `srun`

En primer lugar, para poder correr un análisis en el servidor (o nodo), tenemos que solicitar recursos (CPUs y RAM) al clúster usando **SLURM** (Simple Linux Utility for Resource Management). SLURM es un software que funciona como un gestor de cargas de trabajo (*workload manager*) y planificador de trabajos (*__job__ scheduler*).