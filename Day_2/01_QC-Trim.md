# Calidad de los datos y trimeo

El objetivo de esta sesión es verificar la calidad de las secuencias y aprender algunos índices tradicionales para describir esta calidad. Para esto usaremos los programas `FastQC` y `MultiQC`. También realizaremos el trimeo de adaptadores y reads de mala calidad usando `fastp`. Con estos pasos dejaremos el set de datos preparado para realizar el mapeo de los reads y proceder con el llamado de variantes.

Antes de comenzar necesitamos copiar los datos que usaremos y el árbol de directorios desde la cuenta `student21`:

```bash
# No olviden cambiar studentXX por el nombre real de su cuenta.
cp -r /home/courses/student21/Day02 /home/courses/studentXX
```


 ---

## 1. FastQC y MultiQC

#### 1.1.1 Solicitar recursos usando `srun`

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


#### 1.1.2 Rutas y carpetas

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

### 1.2. FastQC

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

### 1.3. MultiQC

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
## 2. fastp

El trimming (o trimeo) es el proceso mediante el cual se recortan o eliminan partes no deseadas de las lecturas de secuenciación antes de realizar análisis posteriores, como el mapeo o el llamado de variantes. Su objetivo principal es mejorar la calidad de los datos, reduciendo el impacto de errores técnicos propios del proceso de secuenciación.

Durante la secuenciación, es común que:
- la calidad de las bases disminuya hacia los extremos de las lecturas
- queden restos de adaptadores o primers
- existan bases de muy baja calidad que introducen ruido en los análisis

Si estas regiones no se eliminan, pueden provocar:
- mapeos incorrectos o ambiguos
- disminución de la eficiencia de alineamiento
- falsos positivos en análisis posteriores

Por estas razones, el trimming es un paso estándar en la mayoría de los pipelines genómicos. Existen varios programas para realizar trimming de lecturas, entre ellos Trimmomatic, Cutadapt, Trim Galore y fastp, cada uno con enfoques y características particulares. En este curso utilizaremos **fastp** ([Chen et al., 2018](https://doi.org/10.1093/bioinformatics/bty560)), una herramienta moderna y eficiente que integra en un solo paso el trimming por calidad, la detección y eliminación de adaptadores, y la generación de reportes de control de calidad, lo que la hace especialmente adecuada para flujos de trabajo en HPC y para fines docentes.

---
### 2.1. Creación de ambientes

Antes de comenzar, debemos asegurarnos que contamos con el software fastp. En primer lugar podemos ver si existe un módulo que lo contenga usando:

```bash
module spider fastp
```

Dado que no existe el módulo, lo instalaremos en un ambiente (*environment*) usando **conda**. En el trabajo con HPC y análisis genómicos es fundamental manejar ambientes de software. Un ambiente es un espacio aislado donde se instalan programas y sus dependencias (librerías, versiones de Python, etc.) sin interferir con otros programas ni con el sistema base del clúster. Esto permite que distintos análisis utilicen herramientas y versiones diferentes de manera segura y reproducible. Para crear y gestionar estos ambientes utilizamos conda, que es un gestor de paquetes y de ambientes. Conda permite crear ambientes independientes, instalar software dentro de ellos y activarlos solo cuando se necesitan. De esta forma, cada etapa del pipeline (por ejemplo, control de calidad, trimeo o mapeo) puede usar su propio ambiente sin generar conflictos.

En este curso, conda se utiliza a través de Miniconda, que es una versión mínima de la plataforma Anaconda. Miniconda incluye únicamente lo esencial (conda y Python), lo que la hace más liviana y adecuada para entornos compartidos como un clúster. A partir de Miniconda, los ambientes se crean indicando un nombre y luego se activan cuando se quiere trabajar dentro de ellos. En la práctica, el flujo de trabajo consiste en: cargar Miniconda (mediante un módulo del clúster), crear un ambiente para una tarea específica, activar ese ambiente, instalar los programas necesarios y ejecutar el análisis. Al terminar, el ambiente puede desactivarse, dejando el sistema limpio para la siguiente etapa. El uso de ambientes es una buena práctica en genómica y en HPC, ya que facilita la reproducibilidad, reduce errores por incompatibilidades de software y permite que distintos usuarios trabajen de forma independiente dentro de un mismo clúster.

Para evitar conflictos de software y asegurar reproducibilidad, fastp se instalará dentro de un ambiente conda específico. En este caso, utilizaremos Miniconda provista como módulo por el cluster. Primero, cargamos el módulo de Miniconda:

```bash
module load miniconda3/24.7.1-zen4-5
```

Luego, creamos un nuevo ambiente llamado `fastp_trim`:

```bash
conda create -n fastp_trim
```

Aquí:
- `-n` le indica a conda el nombre del ambiente
- `fastp_trim` es un nombre descriptivo asociado al trimeo de lecturas

Para poder activar ambientes conda en la sesión actual, recargamos la configuración del shell:

```bash
source ~/.bashrc
```

A continuación, activamos el ambiente recién creado:

```bash
conda activate fastp_trim
```

Una vez dentro del ambiente, instalamos fastp desde los canales adecuados:

```bash
conda install -c conda-forge -c bioconda fastp
```

En este comando:
- `-c conda-forge` indica el primer repositorio
- `-c bioconda` indica el segundo repositorio
- el orden de los canales es importante para evitar conflictos

Podemos verificar que fastp quedó correctamente instalado revisando su versión y su ayuda:

```bash
fastp -v
fastp -h
```

Ahora podemos correr fastp, pero primero definimos los directorios donde se guardarán los resultados del trimming y los reportes generados por fastp. Estos directorios se crearán solo si no existen.

```bash
CLEAN="/home/courses/student21/Day02/CLEAN"
REP="/home/courses/student21/Day02/fastp_reports"

mkdir -p "${CLEAN}" "${REP}"
```

Luego, nos movemos al directorio donde se encuentran los datos brutos de secuenciación.
```bash
cd "${RAW}"
```

El comando para ejecutar fastp en **una** muestra (DSTEMU01) es:

```bash
fastp \
    --in1 "${RAW}/DSTEMU01_1.fq.gz" --in2 "${RAW}/DSTEMU01_2.fq.gz" \
    --out1 "${CLEAN}/DSTEMU01_1.clean.fq.gz" \
    --out2 "${CLEAN}/DSTEMU01_2.clean.fq.gz" \
    --detect_adapter_for_pe \
    --trim_poly_g \
    --cut_front --cut_tail --cut_mean_quality 20 \
    --length_required 50 \
    --thread 8 \
    --html "${REP}/DSTEMU01.fastp.html" \
    --json "${REP}/DSTEMU01.fastp.json"
```

A continuación se explica qué hace cada parte del comando.

| Categoría | Argumento | Qué hace |
|---------|-----------|----------|
| Entradas | `--in1`, `--in2` | Define los archivos de entrada correspondientes a las lecturas pareadas (R1 y R2). |
| Salidas | `--out1`, `--out2` | Define los archivos de salida para las lecturas trimeadas, manteniendo el nombre de la muestra y añadiendo el sufijo `.clean`. |
| Adaptadores | `--detect_adapter_for_pe` | Detecta y elimina adaptadores automáticamente en datos paired-end. |
| Sesgo Illumina | `--trim_poly_g` | Elimina colas de bases G consecutivas, comunes en secuenciación Illumina de dos colores. |
| Calidad | `--cut_front` | Recorta bases de baja calidad desde el inicio de la lectura. |
| Calidad | `--cut_tail` | Recorta bases de baja calidad desde el final de la lectura. |
| Calidad | `--cut_mean_quality 20` | Define un umbral de calidad promedio (Phred 20) para el trimming. |
| Longitud | `--length_required 50` | Descarta lecturas que quedan con menos de 50 bases tras el trimming. |
| Rendimiento | `--thread 8` | Indica el número de hilos de CPU usados por fastp. |
| Reportes | `--html` | Genera un reporte HTML interactivo con estadísticas antes y después del trimming. |
| Reportes | `--json` | Genera un archivo JSON con estadísticas, útil para integración con MultiQC. |


Una vez finalizado el proceso, los archivos trimeados quedarán listos para los siguientes pasos del pipeline. Los reportes HTML de fastp permiten además evaluar rápidamente el efecto del trimming sobre la calidad de las lecturas. El reporte HTML de fastp entrega un resumen visual y estadístico del proceso de trimming, permitiendo evaluar cómo eran los datos antes del filtrado y cómo quedaron después.

El reporte está organizado en secciones que describen distintos aspectos de la calidad de los datos. Después del **Summary**, el reporte HTML de fastp presenta una serie de secciones que describen distintos aspectos de la calidad de los datos y del efecto del trimming.

- **Adapters:** en esta sección se reporta la detección de adaptadores. Fastp evalúa de forma separada read1 y read2, mostrando cuántas lecturas contienen secuencias compatibles con adaptadores. Esta información permite confirmar si la presencia de adaptadores era relevante en los datos originales y si su eliminación fue necesaria.

- **Insert size estimation:** esta sección corresponde a una estimación del tamaño del inserto basada en el análisis de solapamiento entre lecturas paired-end. Fastp identifica pares de lecturas que se sobreponen y, a partir de ello, infiere la distancia entre ambos extremos del fragmento original. El reporte indica el porcentaje de lecturas que no pudieron ser solapadas, lo que puede deberse a insertos muy cortos, muy largos o a un alto nivel de errores de secuenciación. Este resultado permite evaluar si el tamaño de inserto concuerda con lo esperado para la librería.

- **Filtering statistics:** en esta sección se muestran gráficos de calidad por posición antes y después del trimming, tanto para read1 como para read2. En estos gráficos, el eje X representa la posición dentro de la lectura y el eje Y representa la calidad promedio de las bases. La comparación entre el estado previo y posterior al filtrado permite visualizar directamente la mejora en la calidad, especialmente en los extremos de las lecturas.

- **Quality score histogram:** estos histogramas muestran la distribución global de la calidad de las bases antes y después del trimming. El eje X corresponde al puntaje de calidad (Phred) y el eje Y al número de bases con ese puntaje. Esta sección permite evaluar si el filtrado produjo un desplazamiento de la distribución hacia valores de mayor calidad.

- **Base counts:** en estos gráficos se muestra la composición de bases a lo largo de la lectura, separados por read1 y read2, y comparando el estado antes y después del trimming. El eje X representa la posición en la lectura y el eje Y muestra la proporción relativa de cada nucleótido (A, T, C y G). Esta sección permite detectar sesgos en la composición de bases y evaluar si el trimming contribuyó a reducirlos.

- **KMER counting:** esta sección presenta la frecuencia de pequeños motivos de secuencia (k-mers) en las lecturas, nuevamente separadas por read y por estado antes y después del trimming. La sobre-representación de ciertos k-mers puede indicar adaptadores residuales, contaminación o artefactos técnicos. Comparar estas secciones antes y después del trimming permite verificar si estos patrones fueron efectivamente eliminados o reducidos.

En conjunto, estas secciones permiten evaluar de manera detallada y comparativa el impacto del trimming sobre la calidad de los datos, facilitando la validación de los parámetros utilizados y asegurando que las lecturas estén listas para las etapas posteriores del análisis genómico.