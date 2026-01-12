# Mapeo

Una vez que las lecturas han sido limpiadas mediante trimming, el siguiente paso del pipeline es el **mapeo** (alignment) contra un genoma de referencia. El objetivo del mapeo es determinar en qué posición del genoma se originó cada lectura, permitiendo luego estimar cobertura, detectar variantes y realizar análisis poblacionales.

En este curso utilizaremos **BWA-MEM2** ([Vasimuddin et al., 2019](https://dx.doi.org/10.1109/IPDPS.2019.00041)), una versión optimizada del algoritmo BWA-MEM ([Li & Durbin, 2009](https://doi.org/10.1093/bioinformatics/btp324)), diseñada para ser más rápida y eficiente en datasets grandes como WGS. BWA-MEM2 es actualmente una de las herramientas estándar para mapeo de lecturas Illumina paired-end.

### ¿Qué hace el mapeo?

El mapeo consiste en comparar cada lectura trimeada con el genoma de referencia y encontrar la región donde encaja mejor, permitiendo cierto número de mismatches e indels. El resultado es un archivo que indica, para cada lectura:
- a qué cromosoma o contig mapea
- en qué posición
- con qué orientación
- con qué calidad de alineamiento

Esta información se almacena en archivos SAM/BAM, que serán la base de todos los análisis posteriores.

---
## Genoma de referencia

El genoma de referencia es un componente central en los análisis genómicos, ya que actúa como el marco sobre el cual se alinean las lecturas y se interpretan los datos de secuenciación. La calidad, completitud y anotación de la referencia influyen directamente en la precisión del mapeo, en la estimación de cobertura y en la detección de variantes. 

En el caso de *Drosophila suzukii*, se trata de una especie intensamente estudiada, por lo que dispone de genomas de referencia de muy alta calidad, los cuales han sido actualizados y mejorados de manera continua a lo largo de los años. Existen múltiples referencias disponibles públicamente que podemos ver en [**NCBI**](https://www.ncbi.nlm.nih.gov/datasets/genome/?taxon=28584), reflejando avances en tecnologías de secuenciación y ensamble. 

En este taller usaremos el actual genoma de referencia de la especie ([RefSeq de la especie](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_043229965.1/)) que corresponde al reportado por [Camus et al. (2025)](https://doi.org/10.1111/mec.70192). Sin embargo, para que los análisis sean computacionalmente manejables y adecuados al contexto docente, trabajaremos únicamente con el primer autosoma del genoma de referencia, lo que permitirá ilustrar todos los pasos del pipeline sin sacrificar claridad conceptual. 

---
## 3. BWA-MEM2 (Burrows-Wheeler Aligner)

Para evitar conflictos instalaremos los software para el mapeo dentro de un ambiente conda específico. En este caso, utilizaremos Miniconda provista como módulo por el cluster. Primero, cargamos el módulo de Miniconda:

```bash
# No olviden purgar los módulos anteriores
module purge

# Ahora cargamos el módulo que nos interesa
module load miniconda3/24.7.1-zen4-5
```

Luego, creamos un nuevo ambiente llamado `droso_map` y, a la vez, instalaremos los softwares:

```bash
conda create -n droso_map \
  -c bioconda \
  -c conda-forge \
  bwa-mem2 \
  samtools \
  picard \
  mosdepth \
  bedtools \
  bcftools
```

A continuación, activamos el ambiente recién creado:

```bash
conda activate droso_map
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


### 3.1 Preparación del genoma de referencia

Antes de mapear, el genoma de referencia debe ser indexado. El indexado genera estructuras auxiliares que permiten a BWA buscar coincidencias de manera mucho más rápida y eficiente. Este paso se realiza una sola vez por referencia.

```bash
cd /home/courses/$USER/Day02/REF

bwa-mem2 index Dsuzukii.chrNC_092080.1.fa
```

Tras este comando se crean varios archivos adicionales asociados al FASTA original, que BWA-MEM2 utilizará durante el mapeo.

### 3.2 Script de BWA-MEM2

Ahora podemos mapear o alinear nuestros reads a la referencia, lo que después nos permitirá buscar variantes. Este paso es bastante demandante computacionalmente y es recomendable correrlo usarlo un script `sbatch`. En el directorio `Day02`→`scripts` está el documento `bwa-droso.sbatch` que contiene las instrucciones para el mapeo. Primero, para ganar tiempo, lo lanzaremos como trabajo al clúster y después explicaremos su contenido.

```bash
cd /home/courses/$USER/Day02/scripts

# Veamos el contenido del directorio
ls

# Lancemos el trabajo
sbatch bwa_droso.sbatch
```

Ahora analicemos el detalle del script, la primera sección es la **cabecera y configuración del entorno**. Esta parte le indica al sistema operativo y al gestor de tareas (SLURM) cómo debe ejecutarse el script y qué recursos necesita.

```bash
#!/usr/bin/env bash
#SBATCH -J Ds_map
#SBATCH -p labs
#SBATCH -c 8
#SBATCH --mem=16G
#SBATCH -t 01:00:00
#SBATCH -o /home/courses/%u/Day02/LOGS/Ds_map_%j.out
#SBATCH -e /home/courses/%u/Day02/LOGS/Ds_map_%j.err

set -euo pipefail
```

El detalle de las instrucciones a SLURM es el siguiente:
- `#SBATCH -J Ds_map`: Asigna un nombre al trabajo (Job Name).
- `#SBATCH -p labs`: Indica la partición. En Leftraru, para el curso nos asignaron a la partición `labs`.
- `#SBATCH -c 8`: Solicita 8 núcleos de CPU (cores). Como el mapeo es una tarea computacionalmente pesada, usamos paralelismo para acelerar el proceso.
- `#SBATCH --mem=16G`: Reserva 16 G de memoria RAM. Este valor debe ser mayor a lo que consumen las herramientas para evitar el *error Out Of Memory* (**OOM**).
- `#SBATCH -t 01:00:00`: Define el tiempo máximo de ejecución (1 hora).
- `#SBATCH -o .../Ds_map_%j.out`: Define la ruta del archivo donde se guardará la salida estándar (lo que se vería en pantalla si corriesen el análisis sin SLURM). El símbolo %j se reemplaza automáticamente por el ID único del trabajo.
- `#SBATCH -e .../Ds_map_%j.err`: Define la ruta para el archivo de errores.
- `set -euo pipefail`: Esta línea es útil en bioinformática para evitar resultados silenciosamente erróneos (aunque no es obligatorio incluirla). Lo que detalla es lo siguiente:
	- `-e` (errexit): El script se detiene inmediatamente si cualquier comando falla (devuelve un error). Evita que el script siga corriendo si, por ejemplo, no encuentra los archivos del genoma de referencia.
	- `-u` (nounset): El script falla si se intenta usar una variable que no ha sido definida. Muy útil para detectar errores de tilde u ortográficos.
	- `-o pipefail`: Normalmente, en una cadena de comandos (instrucción1 | instrucción2), solo importa si el último comando falla. Con esta opción, si cualquiera de los comandos en la cadena falla (por ejemplo, si `bwa-mem2` se cae pero `samtools` sigue esperando), el script se detiene por completo.

Es importante notar que en las rutas de los archivos `.out` y `.err`, en vez de designar a un usuario (como `/student21/` u otro) se usó la variable `%u`, que es la notación estándar de SLURM para identificar al usuario. Es importante mencionar que esta notación es para SLURM, más adelante en el script usaremos la notación para Bash.

Vamos con la segunda sección de **definición de rutas y organización**. En esta parte definimos las variables de entorno que el script utilizará. En bioinformática, usar variables en lugar de rutas fijas ("hardcoded") es una buena práctica fundamental porque permite que el script sea reproducible, fácil de leer y rápido de adaptar a otros proyectos.

```bash
ID="DSTEMU01"
BASE="/home/courses/${USER}/Day02"
R1="${BASE}/CLEAN/DSTEMU01_1.clean.fq.gz"
R2="${BASE}/CLEAN/DSTEMU01_2.clean.fq.gz"
REF="${BASE}/REF/Dsuzukii.chrNC_092080.1.fa"

OUT_BAM="${BASE}/MAP/bam"
OUT_STATS="${BASE}/MAP/stats"
TMP="${BASE}/TMP"

mkdir -p "${OUT_BAM}" "${OUT_STATS}" "${TMP}" "${BASE}/LOGS"
```

El detalle de esta organización es el siguiente:
- `ID="DSTEMU01"`: Establece el identificador único de la muestra. Este nombre se usará para nombrar todos los archivos de salida, manteniendo la trazabilidad de los datos.
- `BASE="/home/courses/${USER}/Day02"`: Aquí definimos la carpeta raíz del trabajo. Noten el uso de `${USER}`; esta es una variable de entorno de Bash que identifica automáticamente el nombre del usuario que está ejecutando el script. A diferencia del `%u` de SLURM, esta notación se usa dentro del cuerpo del script.
- `R1` y `R2`: Son las rutas a los archivos de lecturas crudas (Forward y Reverse). Al construir la ruta usando la variable `${BASE}`, nos aseguramos de que el script sea consistente.
- `REF`: Indica la ubicación exacta del genoma de referencia de *Drosophila suzukii*. Como vimos antes, este archivo ya debe estar indexado para que bwa-mem2 pueda trabajar. No olviden que estamos trabajando solo con un cromosoma.
- `OUT_BAM`, `OUT_STATS` y `TMP`: Definimos dónde queremos guardar los resultados finales (BAM), algunas estadísticas de calidad del mapeo y dónde se guardarán los archivos temporales (TMP). Usar una carpeta temporal es clave para no llenar de archivos intermedios nuestro espacio de trabajo principal.
- `mkdir -p ...`: Este comando crea las carpetas necesarias. El parámetro `-p` (parents) es muy útil porque:
	- Crea carpetas anidadas si no existen.
	- Si la carpeta ya existe, no arroja ningún error y continúa con el script.

Al organizar el script de esta manera, si el día de mañana queremos procesar una muestra distinta, solo necesitamos cambiar el valor de la variable ID al principio del documento, y todo el resto del pipeline se actualizará automáticamente.

Sección **carga de ambiente y gestión de software**. En esta sección preparamos el entorno de software. En un clúster de alto rendimiento, conviven cientos de programas y versiones distintas. Por ello, es recomendable limpiar el entorno y cargar exactamente las herramientas que necesitamos para asegurar que nuestro análisis sea reproducible.

```bash
module purge
module load miniconda3/24.7.1-zen4-5
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate droso_map
```

El detalle de la carga de herramientas es el siguiente:
- `module purge`: Limpia todos los módulos cargados previamente en la sesión. Esto garantiza que no existan conflictos entre diferentes softwares que el sistema pueda tener activos por defecto.
- `module load miniconda3/24.7.1-zen4-5`: Carga el gestor de paquetes Miniconda en una versión optimizada para la arquitectura de los procesadores del clúster (Zen 4). Miniconda nos permite gestionar ambientes virtuales aislados.
- `source "$(conda info --base)/etc/profile.d/conda.sh"`: Sirve para inicializar las funciones de Conda dentro del script de Bash. Sin esta instrucción, el comando "activate" podría no ser reconocido por el sistema cuando corre de forma automática en SLURM.
- `conda activate droso_map`: Activa el ambiente virtual específico del curso. En este ambiente ya están pre-instaladas todas las herramientas necesarias (bwa-mem2, samtools, picard).

Sección **configuración de hilos y memoria**, en esta etapa del script vinculamos los recursos que le pedimos a SLURM hacia las herramientas de software específicas. Es un paso crítico porque establecemos (y limitamos) la cantidad de recursos que efectivamente los programas usarán. Nosotros debemos indicarle a los programas la cantidad de recursos que nos asignó el clúster para evitar que intenten usar más de lo disponible y el sistema detenga el proceso.

```bash
THREADS=8
MEM_SORT="1G" 
MEM_JAVA="6g"
```

El detalle de la gestión de recursos es el siguiente:
- `THREADS=8`: Establece el número de hilos de ejecución. Este valor coincide exactamente con los 8 núcleos solicitados en la cabecera del script (`#SBATCH -c 8`). Al definirlo como una variable, podemos pasar este número tanto a bwa-mem2 como a samtools, asegurando que el mapeo y el procesamiento de los archivos sean lo más rápidos posible.
- `MEM_SORT="1G"`: Define la cantidad de memoria RAM que utilizará el comando samtools sort para ordenar las secuencias mapeadas. Es muy importante entender que samtools asigna esta memoria por cada hilo. Como definimos 8 hilos, el programa usará un máximo de 8GB (8 x 1G) durante el peak de ordenamiento. Si pusiéramos un valor muy alto aquí, multiplicaríamos el consumo y colapsaríamos la memoria del trabajo.
- `MEM_JAVA="6g"`: Configura el espacio de memoria máximo (conocido como Heap) que tendrá disponible Java para ejecutar la herramienta Picard. Al asignar 6GB de los 16GB que pedimos originalmente, dejamos un margen de seguridad suficiente para que no colapsen bwa-mem2, el sistema operativo y el proceso de samtools sin exceder el límite de 16GB del nodo.

Esta configuración equilibrada es lo que permite que el script corra de forma fluida. Una regla de oro en bioinformática es siempre dejar un margen de RAM libre (en este caso unos 2GB) para las tareas básicas del sistema, lo que previene los errores de tipo *Out Of Memory*.

Sección de **mapeo y parámetros de BWA-MEM2**. Esta es la sección más importante del pipeline, aquí es donde transformamos las lecturas cortas de ADN (secuencias de letras A, C, T, G) en información posicional sobre un cromosoma. Para que el proceso sea eficiente, utilizamos una "tubería" (pipe) que conecta tres herramientas distintas sin necesidad de guardar archivos pesados entre medio.

```bash
RG="@RG\tID:${ID}\tSM:${ID}\tLB:${ID}\tPL:ILLUMINA\tPU:demo"
BAM_SORTED="${OUT_BAM}/${ID}.sorted.bam"
BAM_FINAL="${OUT_BAM}/${ID}.nodup.bam"

echo "[INFO] Iniciando mapeo para ${ID} (16G RAM)..."

set -x
bwa-mem2 mem -t "${THREADS}" -R "${RG}" "${REF}" "${R1}" "${R2}" \
  | samtools view -@ "${THREADS}" -b -F 4 -q 20 - \
  | samtools sort -@ "${THREADS}" -m "${MEM_SORT}" -T "${TMP}/${ID}.sort" -O BAM -o "${BAM_SORTED}" -
set +x
```

El detalle de este proceso de mapeo y filtrado es el siguiente:
- `RG` (Read Group): Define la identidad de nuestras lecturas. El Read Group contiene información sobre la muestra (SM), la librería (LB) y la plataforma de secuenciación (PL). Muchas herramientas posteriores, como GATK, exigen que esta información esté incrustada en el archivo para poder procesar los datos correctamente.
- `bwa-mem2 mem`: Es el algoritmo de alineamiento. Toma las lecturas R1 y R2 y busca su posición más probable en el genoma de referencia (REF). Al usar la versión 2 de BWA, aprovechamos instrucciones avanzadas de los procesadores modernos para que el cálculo sea significativamente más rápido.
- El símbolo del pipe (`|`): Funciona como una cinta transportadora. En lugar de escribir un archivo gigante en el disco después de mapear, el pipe pasa los datos directamente en la memoria RAM a la siguiente herramienta. Esto ahorra mucho espacio y tiempo de escritura.
- `samtools view -F 4 -q 20`: Actúa como un filtro de calidad. El parámetro `-F 4` indica que solo queremos conservar los reads que se mapearon con éxito (descarta los "unmapped"). El parámetro `-q 20` descarta alineamientos ambiguos o de baja calidad (MAPQ menor a 20). Esto asegura que los datos que usaremos después sean confiables.
- `samtools sort`: Los alineadores entregan los resultados en el orden en que aparecen en el archivo FASTQ (desordenados respecto al genoma). Este comando organiza las lecturas según su posición en el cromosoma (coordenadas). Es un paso obligatorio porque casi todas las herramientas de visualización y análisis requieren que el archivo BAM esté ordenado.
- `set -x` y `set +x`: Estos comandos rodean el bloque principal. Lo que hacen es imprimir en el archivo de error (.err) el comando exacto que se está ejecutando. Es sumamente útil para la transparencia y para detectar errores específicos durante el taller.

Al finalizar esta etapa, habremos pasado de gigabytes de secuencias desordenadas a un único archivo binario (BAM) que contiene solo las lecturas de alta calidad perfectamente ubicadas en el cromosoma de *Drosophila suzukii* que estamos usando.

Sección **marcado de duplicados de PCR**. En esta fase del procesamiento, identificamos y marcamos las lecturas que son duplicados técnicos. Los duplicados suelen ocurrir durante la preparación de la librería genómica (específicamente en la amplificación por PCR) y pueden sesgar los resultados si se interpretan erróneamente como múltiples fragmentos de ADN independientes, cuando en realidad son copias de uno solo.

```bash
picard -Xmx${MEM_JAVA} -Djava.io.tmpdir="${TMP}" MarkDuplicates \
  I="${BAM_SORTED}" \
  O="${BAM_FINAL}" \
  M="${OUT_BAM}/${ID}.dup_metrics.txt" \
  CREATE_INDEX=true \
  VALIDATION_STRINGENCY=SILENT
```

El detalle de este proceso de remoción de duplicados es el siguiente:
- `picard MarkDuplicates`: Es la herramienta utilizada para este propósito. Analiza las coordenadas de mapeo de cada par de lecturas para determinar si provienen del mismo fragmento original de ADN. Es un paso esencial para la limpieza de datos genómicos antes de buscar variantes (SNPs).
- `-Xmx${MEM_JAVA}`: Le indica a la máquina virtual de Java cuánta memoria RAM puede utilizar (6GB según nuestra configuración previa). Picard es una herramienta que consume mucha memoria, por lo que este límite evita que el proceso sea cancelado por el clúster al intentar sobrepasar los recursos asignados.
- `-Djava.io.tmpdir`: Define una ruta específica para archivos temporales. Picard escribe muchos datos intermedios en el disco; al dirigirlos a nuestra propia carpeta TMP, evitamos usar el directorio temporal por defecto del sistema, que suele ser pequeño y compartido por muchos usuarios en el clúster.
- `I` (Input) y `O` (Output): Establecen el archivo de entrada (el BAM que acabamos de ordenar) y el archivo de salida final. El resultado es un archivo BAM donde los duplicados han sido marcados para que las herramientas posteriores de análisis los ignoren.
- `M` (Metrics): Crea un informe de métricas en formato de texto. Este archivo nos dice qué porcentaje de la librería son duplicados. Es un indicador de calidad clave: un porcentaje muy alto de duplicación suele ser una señal de alerta sobre la calidad de la preparación de la muestra en el laboratorio.
- `CREATE_INDEX=true`: Ordena a Picard generar automáticamente el índice del archivo resultante (.bai). El índice funciona como el índice de un libro; permite que los programas accedan a cualquier parte del genoma sin tener que leer todo el archivo BAM desde el principio.
- `VALIDATION_STRINGENCY=SILENT`: Configura al programa para que sea menos estricto con errores menores de formato o advertencias en los encabezados. Esto asegura que el script sea más robusto y no se detenga por problemas técnicos irrelevantes que no afectan la calidad biológica del mapeo.

Sección **control de calidad y limpieza final**. Una vez que el archivo BAM está listo, es fundamental verificar la calidad del alineamiento antes de dar por terminado el proceso. Finalmente, realizamos una limpieza de los archivos intermedios para optimizar el espacio en disco.

```bash
# 5) Estadísticas rápidas (QC de mapeo)
samtools flagstat -@ "${THREADS}" "${BAM_FINAL}" > "${OUT_STATS}/${ID}.flagstat.txt"
samtools idxstats "${BAM_FINAL}" > "${OUT_STATS}/${ID}.idxstats.txt"

# 6) Limpieza
rm -f "${BAM_SORTED}"
rm -rf "${TMP}"

echo "[OK] Script ejecutado exitosamente."
```

El detalle de estos pasos finales es el siguiente:
- `samtools flagstat`: Genera un informe resumido con las estadísticas generales de alineamiento. Este comando nos permite ver rápidamente el porcentaje de lecturas que mapearon exitosamente y cuántas de ellas están "propiamente pareadas" (*properly paired*). Es el primer control de calidad para saber si nuestro experimento de secuenciación y el mapeo funcionaron correctamente.
- `samtools idxstats`: Proporciona un reporte detallado de cuántas lecturas se alinearon a cada secuencia de referencia (cromosoma o scaffold). En nuestro caso, como estamos trabajando con el cromosoma NC_092080.1 de *Drosophila suzukii*, este archivo nos confirmará cuántos datos logramos recuperar específicamente para esa región del genoma.
- `rm -f "${BAM_SORTED}"`: Elimina el archivo BAM ordenado inicial. Como ya generamos una versión final que tiene los duplicados marcados e indexados (BAM_FINAL), el archivo intermedio ya no es necesario. Borrarlo nos permite ahorrar varios GB de espacio.
- `rm -rf "${TMP}"`: Elimina la carpeta temporal de este trabajo. Durante el ordenamiento y el marcado de duplicados, los programas crean cientos de archivos pequeños. Si no los borramos, estos archivos pueden acumularse rápidamente.
- `echo "[OK] Script ejecutado exitosamente"`: Imprime un mensaje de confirmación en el archivo de salida estándar (.out). Si vemos este mensaje al final de nuestro log, tenemos la certeza de que el script completó todas sus etapas sin interrupciones.


---
### 3.3 Resultados del mapeo

El script de la sección anterior debería tardar unos **25 minutos** (en el clúster del NLHPC). Podemos ver el avance que lleva en la carpeta `LOGS`.

```bash
cd home/courses/student21/Day02/LOGS

ls
```

En ese directorio están dos documentos que son la salida estándar (terminación `.out`) y el registro de errores (terminación `.err`). El nombre de los documentos se refiere al nombre que le pusimos al trabajo en el encabezado del script, para este caso fue: `#SBATCH -J Ds_map`, seguido de un número que es el que fue asignado al trabajo por SLURM.

Si queremos ver el estado del análisis revisaremos el archivo `.err`. Si todo está bien, debería mostrar las instrucciones que indicamos en nuestro script.

```bash
+ bwa-mem2 mem -t 8 -R '@RG\tID:DSTEMU01\tSM:DSTEMU01\tLB:DSTEMU01\tPL:ILLUMINA\tPU:demo' [...]
+ samtools view -@ 8 -b -F 4 -q 20 -
+ samtools sort -@ 8 -m 1G -T /home/courses/student21/Day02/TMP/DSTEMU01.sort -O BAM -o [...]
Looking to launch executable "/home/courses/student21/.conda/envs/droso_map/bin/bwa-mem2.avx", simd = .avx
Launching executable "/home/courses/student21/.conda/envs/droso_map/bin/bwa-mem2.avx"
[...]
```

Si aún no ha terminado, cancelaremos el trabajo usando el comando `scancel` y el número de trabajo asignado por SLURM. Recuerden que el número del trabajo es el que aparace en el nombre de los archivos `.err` y `.out`.

```bash
scancel XXXXX
```

Previamente corrimos BWA-MEM2 y ahora copiaremos los resultados a cada una de sus cuentas. Para que no hayan problemas primero **tienen que cancelar el trabajo** que estaban corriendo.

```bash
cp -r \
  /home/courses/student21/Day02_Backup/MAP \
  /home/courses/${USER}/Day02/
```

Ahora, en sus directorios `MAP` deberían tener dos carpetas `bam` y `stats`. En la primera, cada muestra debe tener dos archivos resultados del mapeo:

1. `DSTEMU01.nodup.bam` Es el archivo principal. Es un formato binario comprimido (BAM = *Binary Alignment Map*) que contiene todas las lecturas que mapearon contra el cromosoma de referencia. Al decir `nodup`, significa que ya pasó por Picard y los duplicados de PCR han sido marcados (o eliminados), lo que lo hace listo para el análisis de variantes (SNPs).

2. `DSTEMU01.nodup.bai` Es el **índice** del archivo BAM. Es análogo al índice de un libro. Los programas que leerán el archivo BAM no tendrán que abrir todo el archivo (que puede ser muy pesado), sino que consultan el .bai para saber exactamente en qué posición del archivo están las lecturas de una región específica. Sin el .bai, no se puede visualizar el BAM rápidamente.

Por otro lado, en la carpeta `stats` tenemos:

3. `DSTEMU01.flagstat.txt` Es un resumen estadístico rápido. Indica cuántos reads mapearon en total, cuántos pasaron los filtros de calidad y cuántos están correctamente pareados (*properly paired*). Es el primer lugar donde miramos para saber si el experimento funcionó: si el "% de mapeo" es muy bajo, algo salió mal en la secuenciación o en la preparación de la muestra.

4. `DSTEMU01.idxstats.txt` Este archivo es una tabla que desglosa el mapeo por cada secuencia de la referencia. En nuestro caso, como solo usamos un cromosoma, veremos una línea con el nombre de ese cromosoma, su longitud, cuántos reads mapearon ahí y cuántos reads no mapearon. Es ideal para confirmar que los datos se concentraron donde esperábamos.

5. `DSTEMU01.markdup.metrics.txt` Es el reporte generado por Picard. El dato más importante aquí es el *Percent Duplication*.

    - Si es bajo (ej. < 5-10%), la librería es de alta complejidad.

    - Si es muy alto (ej. > 30%), significa que perdiste mucha información en la PCR y estás leyendo muchas veces las mismas moléculas, lo cual no es ideal.


<details>
<summary><strong>Opcional: inspección del BAM</strong></summary>

Primero navegamos hacia el directorio donde están los archivos:

```bash
cd /home/courses/${USER}/Day02/MAP/bam
ls
```

Los archivos BAM son archivos binarios, por lo que no pueden leerse directamente con comandos como `cat`, `less` o `head`. Para inspeccionar su contenido necesitamos usar herramientas especializadas, en este caso **samtools**. Antes de usar samtools, es importante asegurarse de tener activado el ambiente conda correcto (`droso_map`), ya que ahí se encuentran instalados los programas que utilizaremos.

Entre los comando básicos, uno muy útil es contar cuántos reads contiene un BAM. Este comando convierte internamente el BAM (binario) a formato SAM y cuenta cuántas alineaciones contiene, sin imprimirlas en pantalla. Luego, entrega un único número que corresponde al total de reads almacenados en el BAM.

```bash
samtools view -c DSTEMU01.nodup.bam
```

En nuestro ejemplo, el resultado indica que el archivo DSTEMU01.nodup.bam contiene 2.281.357 reads, es decir, los reads que sobrevivieron al mapeo y a los filtros aplicados previamente.

También podemos ver el header del BAM:

```bash
samtools view -H DSTEMU01.nodup.bam
```

Este comando muestra únicamente el encabezado del archivo BAM, que contiene información descriptiva y técnica del alineamiento. Entre lo que se muestra, podemos identificar:
- Versión del formato BAM y tipo de ordenamiento (@HD)
- Secuencias de referencia usadas en el mapeo, por ejemplo cromosomas y sus longitudes (@SQ)
- Read groups, que indican a qué muestra pertenece cada read (@RG)
- Programas utilizados durante el pipeline, con versiones y comandos exactos (@PG)

El header permite reconstruir cómo se generó el BAM, lo que es clave para reproducibilidad y control de calidad.

Ver los primeros reads del BAM:

```bash
samtools view DSTEMU01.nodup.bam | head
```

Este comando convierte el BAM a texto (formato SAM) y muestra las primeras líneas correspondientes a los primeros reads del archivo. Nos muestra:
- Identificador del read
- Flags que codifican información sobre el alineamiento
- Cromosoma y posición donde mapea
- Calidad de mapeo (MAPQ)
- CIGAR string, que describe cómo alinea el read
- Secuencia nucleotídica
- Calidades de base
- Tags adicionales generados durante el procesamiento (por ejemplo duplicados, mismatches, etc.)

Esto permite inspeccionar manualmente cómo luce un alineamiento real y verificar que el mapeo se haya realizado correctamente.

</details>