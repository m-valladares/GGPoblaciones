 # Variant Calling

- **ANGSD** ([Korneliussen et al., 2014](https://doi.org/10.1186/s12859-014-0356-4)) → datos de baja cobertura (lcWGS), usando *genotype likelihoods* en lugar de genotipos fijos

### 4.1 Ambiente conda para Variant Calling (ANGSD)

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

### 4.3 ¿Qué hace FreeBayes?

FreeBayes es un variant caller haplotípico, lo que significa que:
- evalúa múltiples posiciones simultáneamente
- considera la información de reads pareados
- infiere variantes a nivel de haplotipos locales

A diferencia de enfoques más antiguos basados solo en pileup, FreeBayes modela explícitamente la variación genética esperada en poblaciones.

### 4.4 Preparación de archivos y rutas

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
ls /home/courses/${USER}/Day02/MAP/bam/*.nodup.bam > /home/courses/${USER}/Day02/MAP/bam/bamlist.txt
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
}' /home/courses/${USER}/Day02/REF/Dsuzukii.chrNC_092080.1.fa.fai > /home/courses/${USER}/Day02/REF/regions.txt
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

### 4.5 Ejecución de FreeBayes

Luego de construir los archivos accesorios (`bamlist.txt` y `regions.txt`) podemos hacer el llamado de variantes. Este paso es bastante demandante computacionalmente y es recomendable correrlo usarlo un script `sbatch`. En el directorio `Day02`→`scripts` está el documento `fbayes_droso.sbatch` que contiene las instrucciones para el mapeo. Primero, para ganar tiempo, lo lanzaremos como trabajo al clúster y después explicaremos su contenido.

```bash
cd /home/courses/$USER/Day02/scripts

# Veamos el contenido del directorio
ls

# Lancemos el trabajo
sbatch fbayes_droso.sbatch
```

Ahora analicemos el detalle del script, como ya vimos en el script de BWA-MEM2, la primera sección es la **cabecera y configuración del entorno**. Esta parte le indica al sistema operativo y al gestor de tareas (SLURM) cómo debe ejecutarse el script y qué recursos necesita. La segunda sección de **definición de rutas y organización**. En esta parte definimos las variables de entorno que el script utilizará. Luego, tenemos la sección de **carga de ambiente y gestión de software**.

Revisemos en detalle la **sección configuración de recursos**, en esta etapa vinculamos los recursos solicitados a SLURM con las herramientas de análisis en paralelo. A diferencia del mapeo, donde un solo proceso usa muchos hilos, aquí utilizaremos un enfoque de paralelismo masivo por tareas, donde dividimos el genoma en trozos pequeños (ventanas) y procesamos varios trozos simultáneamente.

```bash
THREADS=4
FLAGS="-K -C 1 -F 0.01 --limit-coverage 500"
```

El detalle de la gestión de recursos y parámetros es el siguiente:
- `THREADS=4`: Define el número de trabajos simultáneos que ejecutará GNU Parallel. Este valor es coherente con los 4 núcleos solicitados en `#SBATCH -c 4`. En este esquema, cada núcleo se encargará de procesar una ventana genómica independiente de forma completa. Al finalizar una ventana, el núcleo queda libre y parallel le asigna la siguiente automáticamente hasta agotar el archivo regions.txt.
- `FLAGS`: Aquí agrupamos los parámetros que controlan la sensibilidad del llamado de variantes en FreeBayes:
  - `-K`: Instruye al programa a reportar sitios monomórficos (posiciones donde no hay variación respecto a la referencia). Esto es útil si luego queremos calcular estadísticas que requieran conocer el total de sitios variantes y no variantes.
  - `-C 1`: Establece que se requiere al menos 1 lectura (read) apoyando una variante para considerarla.
  - `-F 0.01`: Define que la frecuencia mínima de la variante debe ser del 1% para ser reportada.
  - `--limit-coverage 500`: Es una medida de seguridad. Si una región tiene una profundidad de lectura superior a 500x (lo cual suele ocurrir en regiones repetitivas o de baja complejidad), FreeBayes la saltará. Esto evita que el script se quede "atrapado" durante horas procesando una sola región problemática.

<details>
<summary><strong>Nota sobre los parámetros de calidad</strong></summary>

Es importante notar que los parámetros definidos en la variable `FLAGS` han sido simplificados para fines pedagógicos. Debido a que en este taller trabajamos con un subconjunto reducido de datos (un solo cromosoma y datos filtrados), el uso de filtros extremadamente estrictos resultaría en la pérdida total de señales genómicas.

En el estudio real, se utilizaría una configuración mucho más rigurosa para asegurar la máxima confiabilidad en los SNPs detectados. Esta configuración debería considerar por lo menos:

```bash
FLAGS="-K -C 1 -F 0.01 -G 5 -E -1 --limit-coverage 500 -n 4 -m 30 -q 20"
```

El detalle de estos parámetros es:
- `-G 5` (Min sum of alt quals): Requiere que la suma de las calidades de las bases que soportan la variante sea al menos 5. Esto ayuda a descartar variantes que solo aparecen en bases de muy mala calidad.
- `-E -1` (Complex events): Indica cómo tratar eventos complejos. El valor -1 permite a FreeBayes evaluar polimorfismos complejos de manera más flexible, integrando diferentes tipos de variantes (SNPs e Indels) si ocurren en la misma región.
- `-n 4` (NHot alleles): Limita el número de alelos "calientes" (hot alleles) que se consideran en una posición. Esto evita que el programa consuma demasiada memoria intentando modelar demasiadas variantes raras en un solo sitio.
- `-m 30` (Min mapping quality): Excluye del análisis cualquier lectura que tenga una calidad de mapeo inferior a 30. Esto asegura que solo usemos lecturas que se alinearon de forma única y confiable en el genoma.
- `-q 20` (Min base quality): Solo considera bases con una calidad (Phred score) de al menos 20. Una base con Q20 tiene una probabilidad de error de 1 en 100.

En resumen: Mientras que en el taller priorizamos "ver resultados" para entender el flujo de trabajo, en una investigación real priorizamos la pureza de los datos para evitar falsos positivos que puedan arruinar las conclusiones biológicas.

</details>

---
Sección **llamado de variantes por ventana**, en esta etapa ejecutamos el análisis propiamente tal. Debido a que el llamado de variantes es una tarea computacionalmente intensiva, no procesamos el cromosoma completo de una sola vez, sino que utilizamos GNU Parallel para fragmentar el trabajo.

```bash
parallel -j "${THREADS}" --joblog "${LOGS}/parallel_jobs.log" "
    region_name=\$(echo {1} | sed 's/:/_/g; s/-/_/g')
    
    freebayes -f ${REF} -L ${BAMLIST} -r {1} ${FLAGS} | \
    bgzip -c > ${OUT_VCF}/ventana_\${region_name}.vcf.gz
    
    tabix -p vcf ${OUT_VCF}/ventana_\${region_name}.vcf.gz
" :::: "${REGIONS}"
```

El funcionamiento de este bloque tiene tres componentes clave:
- Gestión de tareas con GNU Parallel:
  - `-j "${THREADS}"`: Indica cuántas ventanas se procesan simultáneamente (en nuestro caso, 4).
  - `--joblog`: Crea un registro detallado que nos permite monitorear qué ventanas terminaron exitosamente y cuánto tiempo tomó cada una. Es fundamental para el diagnóstico de errores.
  - `:::: "${REGIONS}"`: Esta sintaxis le dice a parallel que lea el archivo regions.txt línea por línea. Cada línea (por ejemplo, chr1:1-150000) será enviada al comando como el argumento {1}.
- Procesamiento de cada ventana:
  - `region_name=...`: Transformamos el formato de la región (ej. de chr1:1-15000 a chr1_1_15000) para poder usarlo como un nombre de archivo válido y organizado.
  - `freebayes ... | bgzip -c`: Utilizamos un "pipe" (`|`) para conectar la salida de FreeBayes directamente con bgzip. Esto es extremadamente eficiente porque el archivo VCF (que es texto plano muy pesado) se comprime en tiempo real mientras se genera, ahorrando una enorme cantidad de espacio en el disco duro.
  - `> ...vcf.gz`: El resultado final de cada ventana es un archivo comprimido listo para ser indexado.
- Indexación inmediata (tabix):
  - Ejecutamos `tabix` justo después de crear cada archivo .vcf.gz. Esto genera un índice .tbi para cada ventana. Aunque parezca un paso extra, es necesario para que en el siguiente paso bcftools pueda unir los archivos de forma ultra rápida accediendo directamente a las coordenadas genómicas.


Sección **concatenación de resultados**, una vez que todas las ventanas individuales han sido procesadas exitosamente, procedemos a unirlas en un único archivo que represente el cromosoma completo. Este paso es similar a armar un rompecabezas donde cada pieza es una de las ventanas de 150 kb que procesamos anteriormente.

```bash
BAM_FINAL="${OUT_VCF}/final_chr1_raw.vcf.gz"

bcftools concat -a -Oz -o "${BAM_FINAL}" "${OUT_VCF}"/ventana_*.vcf.gz
bcftools index -t "${BAM_FINAL}"
```

El detalle de esta operación es el siguiente:
- `bcftools concat`: Es la herramienta estándar para unir archivos VCF. A diferencia de un comando `cat` normal, bcftools entiende la estructura del archivo (cabeceras y cuerpo) y asegura que el resultado sea un VCF válido.
  - `-a` (naive concat): Esta opción es clave. Permite una concatenación ultra rápida siempre y cuando los archivos tengan las mismas muestras y estén en orden. Como usamos ventana_*.vcf.gz, el sistema operativo entrega los archivos en orden alfabético/numérico, lo que coincide con el orden genómico del cromosoma.
  - `-Oz`: Indica que la salida debe ser comprimida en formato BGZF (Blocked GNU Zip Format). Este formato es esencial en bioinformática porque permite el acceso aleatorio al archivo sin tener que descomprimirlo entero.
- Indexado final (`bcftools index -t`): Generamos el índice .tbi para nuestro archivo final. Este índice es el que permite que herramientas de visualización como IGV o programas de filtrado posteriores carguen solo las regiones necesarias del archivo, haciendo que el análisis sea fluido incluso con archivos de varios gigabytes.


<details>
<summary><strong>El Filtrado de Calidad (Post-procesamiento)</strong></summary>

Tras obtener el archivo VCF concatenado, el siguiente paso en un flujo de trabajo real es el **Filtrado de Variantes**. El objetivo es eliminar falsos positivos causados por errores de secuenciación, mapeos ambiguos o sesgos en la preparación de las librerías. Aunque en este taller no ejecutaremos este paso para conservar los pocos SNPs detectados en nuestro subconjunto de datos, a continuación desglosamos la lógica de un filtrado profesional utilizando bcftools:

```bash
bcftools view --threads "${THREADS}" -m2 -M2 -v snps -Ou "${IN}" \
bcftools filter --threads "${THREADS}" -Ou -i '
    QUAL>20 &&
    INFO/NS>=35 &&
    INFO/DP>100 && INFO/DP<5000 &&
    INFO/SAF[0]>0 && INFO/SAR[0]>0 &&
    INFO/RPR[0]>1 && INFO/RPL[0]>1 &&
    INFO/EPP[0]>0 &&
    INFO/SRP>0 &&
    ( (1.0*INFO/AO[0])/(INFO/AO[0]+INFO/RO) )>0.01 &&
    ( (1.0*INFO/AO[0])/(INFO/AO[0]+INFO/RO) )<0.99
'
```

Explicación de los criterios de filtrado:
- Restricción de Alelos (`-m2 -M2 -v snps`):
  - Nos aseguramos de quedarnos únicamente con sitios bialélicos (solo dos alelos posibles) y que sean estrictamente SNPs. Esto facilita los análisis poblacionales posteriores.
- Calidad y Representatividad (`QUAL > 20 && INFO/NS >= 4`):
  - `QUAL > 20`: Filtramos sitios con baja confianza estadística (Score Phred).
  - `NS >= 4`: Exigimos que la variante esté presente en los 4 pools analizados. Si falta información en uno de ellos, descartamos el sitio para mantener la consistencia estadística.
- Profundidad de Lectura (`DP`):
  - Ponemos un piso (`DP > 20`) para evitar sitios con poco soporte y un techo (`DP < 500`) para evitar regiones repetitivas o duplicaciones colapsadas que suelen generar falsos SNPs.
- Sesgo de Hebra y Posición (*Strand & Position Bias*):
  - `SAF[0]>0 && SAR[0]>0`: Exigimos que el alelo alternativo haya sido leído tanto en la hebra Forward como en la Reverse. Si solo aparece en una hebra, es probable que sea un artefacto técnico.
  - `RPR[0]>1 && RPL[0]>1`: Verificamos que el alelo alternativo no esté siempre al final o al inicio de los reads, lo cual es un indicador común de errores en los bordes de alineamiento.
  - `EPP[0]>0`: (End Placement Probability). Es un score de probabilidad que penaliza variantes que ocurren exclusivamente en los extremos de las lecturas.
  - `SRP>0`: (Strand Reference Probability). Evalúa el balance de hebras, pero aplicado al alelo de referencia. Se usa aquí para asegurar consistencia general en el sitio.
- Frecuencia Alélica Mínima (MAF-like):
  - `(1.0*INFO/AO[0])/(INFO/AO[0]+INFO/RO) > 0.01`: Calculamos la proporción de reads del alelo alternativo (AO) respecto al total (AO + RO). Esto actúa como un filtro de frecuencia alélica mínima (1%), eliminando variantes que aparecen tan poco que podrían ser simples errores de la polimerasa.

Conclusión: Filtrar un VCF es un equilibrio constante entre Sensibilidad (no perder variantes reales) y Especificidad (no incluir errores). En el estudio real, estos filtros aseguran que los SNPs analizados representen la biología verdadera de Drosophila suzukii.

</details>

### 4.6 Exploración del VCF

Dado que el análisis de variantes es un proceso computacionalmente demandante y el tiempo del taller es limitado, no esperaremos a que los trabajos terminen de procesarse en el clúster. Para avanzar a la etapa de exploración y filtrado, procederemos a cancelar nuestras tareas actuales y a utilizar un conjunto de datos pre-calculado que representa el análisis completo.

1. Cancelar el trabajo actual: Identifica el JOBID de las tareas y las detendremos para liberar los recursos del nodo:

```bash
# Reemplaza <JOBID> con el número de tu trabajo
scancel <JOBID>
```

2. Sincronizar datos desde el Backup: Utilizaremos los resultados finales generados previamente para asegurar que todos trabajemos sobre la misma base de datos. Cabe mencionar que este VCF fue generado con el script que usamos.

```bash
cp -r \
  /home/courses/student21/Day02_Backup/VCF \
  /home/courses/${USER}/Day02/
```

Ahora exploraremos el VCF con bcftools, para evitar sorpresas lo haremos en un nodo de cómputo, así que pediremos recursos a SLURM.

```bash
srun --partition=labs --nodes=1 --cpus-per-task=8 --time=04:00:00 --mem=8G --pty bash
```

Antes de usar los comandos de bcftools, tenemos que activar el ambiente que contiene a la herramienta, y navegar a la carpeta donde está el VCF.

```bash
conda activate droso_vc

cd /home/courses/${USER}/Day02/VCF
```

Una vez dentro de la sesión interactiva de srun y con el ambiente activado, utilizaremos bcftools para interrogar al archivo.
1. Ver el encabezado (Header): El encabezado contiene los metadatos: los comandos usados, la referencia y, lo más importante, la definición de todas las etiquetas (como DP, QUAL, AO).

```bash
# -h muestra solo el encabezado
bcftools view -h Dsuzukii_chr1_final.vcf.gz | less -S
```

2. Ver los registros de variantes: Para examinar los datos propiamente tales (los SNPs), usamos el comando sin el flag -h. Usamos less -S para poder desplazarnos horizontalmente sin que las líneas se corten.

```bash
# -H omite el encabezado para ir directo a los datos
bcftools view -H Dsuzukii_chr1_final.vcf.gz | less -S
```

3. Resumen estadístico (Stats): Antes de mirar línea por línea, es mejor tener una visión global: ¿Cuántos SNPs hay? ¿Cuál es la calidad promedio? ¿Cuántas transiciones y transversiones?

```bash
# Generar un reporte estadístico rápido
bcftools stats Dsuzukii_chr1_final.vcf.gz > stats.txt

# Ver el resumen de tipos de variantes y recuentos
grep ^SN stats.txt
```

4. Consultar regiones específicas: Si queremos ver qué está pasando en una coordenada exacta del cromosoma (por ejemplo, entre la base 1.000.000 y 1.050.000):

```bash
# El flag -r permite filtrar por región instantáneamente gracias al índice .tbi
bcftools view -r chrNC_092080.1:1000000-1050000 Dsuzukii_chr1_final.vcf.gz | bcftools view -H | wc -l
```

5. Extraer información específica (Query): Este comando es útil para "limpiar" la vista. Si solo queremos ver la posición, el alelo de referencia, el alternativo y la profundidad total (DP):

```bash
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%INFO/DP\n' Dsuzukii_chr1_final.vcf.gz | head -n 20
```

