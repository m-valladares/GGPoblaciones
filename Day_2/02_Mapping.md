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

**Pregunta:** ¿Qué es un archivo BAM?

<details>
<summary><strong>Si no pudieron activar el ambiente</strong></summary>

*Solo en caso que solicite iniciar conda**, indicaremos `conda init`. Y luego, para poder activar ambientes conda en la sesión actual, recargamos la configuración del shell:

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
# No olviden cambiar studentXX por el nombre real de su cuenta.
cd /home/courses/studentXX/Day02/REF

bwa-mem2 index Dsuzukii.chrNC_092080.1.fa
```

Tras este comando se crean varios archivos adicionales asociados al FASTA original, que BWA-MEM2 utilizará durante el mapeo.

### 3.1 Preparación del genoma de referencia

Ahora podemos mapear o alinear nuestros reads a la referencia, lo que después nos permitirá buscar variantes. Este paso es bastante demandante computacionalmente y es recomendable correrlo usarlo un script `sbatch`. En el directorio `Day02`→`scripts` está el documento `bwa-droso.sbatch` que contiene las instrucciones para el mapeo.
