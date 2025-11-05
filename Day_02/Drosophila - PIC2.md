Proyecto: Análisis Genómico de Drosophila suzukii - WGS Pool-seq
Responsable: Moisés A. Valladares
Ruta base: /home/lcastaneda/Drosophila/

Antecedentes: comencé el estudio asociado a la objetivo 1 del Anillo en mayo 2025. El envío de el primer batch de muestras se realizó el 11 junio. Los resultados de calidad fueron entregados por BMK el 23 de junio. Los resultados y datos brutos fueron enviados por BMK el 11 de julio. Lamentablemente no tuvimos capacidad de almacenamiento en el servidor hasta la primera semana de agosto y recién durante la segunda semana de agosto registraron nuestra cuenta en SLURM. Posteriormente, durante ~20 días el nodo principal no estuvo disponible (allocated por otros investigadores). Finalmente, durante la semana del 18 de septiembre comencé los análisis sin mayores obstáculos. Aunque la última semana de septiembre se cortó la electricidad durante el variant calling (FreeBayes).

1. Se creó la estructura de carpetas para organizar los análisis de Drosophila suzukii:

- RAW/batch01       → archivos originales .fq.gz (datos sin procesar)
- QC_pretrim        → FastQC + MultiQC antes de limpieza
- CLEAN             → archivos limpiados con fastp
- QC_posttrim       → FastQC + MultiQC después de limpieza
- LOGS              → logs de SLURM y reportes de ejecución
- scripts           → SLURM scripts y automatizaciones

Comando utilizado:
mkdir -p RAW/batch01 QC_pretrim CLEAN QC_posttrim LOGS scripts

2. Ruta actual de los datos RAW:
pwd = /home/lcastaneda/Drosophila/RAW/batch01

Archivos en batch01 (cada muestra tiene dos archivos _1 y _2), se seleccionaro solo machos:
- DSCHLL01_R05 → Chillán (pool 50 ind)
- DSLING01_R02 → Los Lingues (pool 50 ind)
- DSMALL01_R03 → Mallarauco (pool 50 ind)
- DSTALC01_R04 → Talca (pool 50 ind)
- DSTEMU01_R06 → Temuco (pool 50 ind)
- DSVICE01_R01 → San Vicente (pool 38 ind)

3. Análisis inicial

a) Evaluación de calidad inicial con FastQC y MultiQC
  - Crear carpeta QC_pretrim
  - Ejecutar FastQC sobre todos los .fq.gz
  - Luego ejecutar MultiQC dentro de la carpeta con los resultados

b) Trimming con fastp
  - Crear carpeta CLEAN y LOGS
  - Ejecutar fastp por cada muestra (pares _1 y _2)
  - Salidas: archivos .clean.fq.gz + archivos .html y .json con reporte

c) Evaluación de calidad post-trimming
  - Crear carpeta QC_posttrim
  - Ejecutar FastQC nuevamente sobre los archivos limpios
  - Ejecutar MultiQC para resumen final

4. Buenas prácticas en el servidor
  - No saturar CPU ni RAM
  - Usar SLURM para ejecutar todos los análisis
  - Solicitar recursos adecuados (ej: 4 threads y 4GB RAM por tarea)
  - Guardar todos los logs en la carpeta LOGS

5. Pendientes
  - Crear script de SLURM para FastQC
  - Crear script de SLURM para fastp
  - Automatizar procesamiento por lote (loop o array jobs)
  - Planificar siguientes pasos: mapeo a genoma de referencia, estimación de cobertura, SNP calling, análisis de estructura poblacional, etc.

---------

Miniconda no estaba instalado en el sistema. Se instaló manualmente en ~/miniconda3
Pasos seguidos:
1. wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
2. bash miniconda.sh
3. Ruta de instalación: ~/miniconda3
4. Activación: source ~/miniconda3/bin/activate
5. Creación de entorno de análisis: conda create -n drosophila_qc fastqc fastp multiqc -c bioconda -c conda-forge
6. Activación: conda activate drosophila_qc

Este entorno contiene:
- fastqc (control de calidad de archivos .fq.gz)
- fastp (trimming y limpieza)
- multiqc (resumen de reportes QC)

Para confirmar:
fastqc --version
fastp --version
multiqc --version

Esto pasó para varios análisis, así que posteriormente creé otros entornos de acuerdo al estado de avance. Así evité incompatibilidad entre las versiones de software, aunque algunos environments tienen redundancia de programas.

Se creó el script local `run_fastqc_local.sh` para ejecutar FastQC sin SLURM.
Ubicación: /home/lcastaneda/Drosophila/scripts/

Comando para ejecutar:
./run_fastqc_local.sh

Este script activa el entorno conda `drosophila_qc` y corre FastQC sobre todos los archivos .fq.gz en RAW/batch01.
Los resultados se almacenan en QC_pretrim/.


Resumen de trabajo – 2025-08-08

1. Organización del proyecto

Se definió y creó la estructura de carpetas del proyecto Drosophila en el servidor:

```
/home/lcastaneda/Drosophila/
├── RAW/
│   ├── batch01/            ← Lecturas Pool-seq propias (6 localidades)
│   ├── public_data/        ← Lecturas públicas (28 pools a descargar)
│   └── public_data_02/     ← Lecturas públicas de Portugal (paper de Sario et al. 2024)
├── REFERENCE/              ← Genoma de referencia y elementos auxiliares
├── QC/                     ← Resultados de FastQC y trimming (hay pretriming y post)
├── ALIGNMENT/              ← Archivos de mapeo (BAM, etc.)
├── VARIANT/                ← Archivos VCF, matrices, etc.
├── LOGS/                   ← Logs de ejecución
├── scripts/                ← Scripts del proyecto (en minúscula)
├── METADATA/               ← Trazabilidad y metadatos
├── MAP/                    ← Genomas mapeados (post BWA-MEM2)
└── CLEAN/                  ← Genomas trimeados (post fastp)
```


2. Genoma de referencia

Se descargó el ensamble nuclear completo de Drosophila suzukii (GCF_043229965.1) utilizando NCBI datasets CLI. Este genoma es el actual RefSeq de la especie.

Ruta de descarga:
/home/lcastaneda/Drosophila/REFERENCE/ncbi_dataset/data/GCF_043229965.1/

Archivos clave extraídos y renombrados para facilitar su uso posterior:
- GCF_043229965.1_CBGP_Dsuzu_IsoJpt1.0_genomic.fna → D_suzukii_ref.fasta
- genomic.gff → D_suzukii_ref.gff

Archivos finales quedaron en:
/home/lcastaneda/Drosophila/REFERENCE/
- D_suzukii_ref.fasta
- D_suzukii_ref.gff

3. Próximos pasos planificados

- Descargar y agregar:
  - El genoma mitocondrial de D. suzukii (Accession KU588141)
  - El genoma de Wolbachia wRI (GCA_000022285.1)
- Concatenar los tres FASTA para crear una referencia híbrida.
- Indexar con bwa-mem2 y samtools.

Obtención de datos públicos (otros genomas)

A partir del paper de Camus et al. (2025) obtuve los códigos para descargar de SRA 28 genomas pool-seq de diferentes lugares del mundo.

Como el internet de la UChile es muy lento, los descargué en mi casa a un disco externo y luego los subí al servidor.

Para descargarlos usé el SRA Toolkit (prefetch y fetch). En este link hay varios detalles útiles:

https://bioinformaticsworkbook.org/dataAcquisition/fileTransfer/sra.html#gsc.tab=0

Para que fuese automatizado creé un script (.sh) para descargar los datos (un único .SRA), dividirlos en dos (.fastq), comprimirlos en dos elementos (.f.gz) y eliminar los elementos temporales.

Actualización (octubre 2025): agregué dos genomas públicos obtenidos del paper de Sario et al. 2024 (BMC Genomics). En particular me interesa incluir la muestra PT-VM19 (SRR28145939) que en el PCA aparece en un sector aislado del espacio multivariado. Especulo que podría ser una invasión reciente (o re-invasión) con señales de endogamia extrema (revisar al final los resultados de heterocigosidad).

BITÁCORA — Drosophila suzukii — 2025-08-29
Tema: Referencia compuesta (nuclear + mitocondrial + Wolbachia) y entorno de mapeo

Objetivo: Construir una referencia “compuesta” que incluya: genoma nuclear de D. suzukii (GCF_043229965.1), mitogenoma (KU588141) y Wolbachia wRi (GCF_000022285.1), para que los reads se alineen a su origen correcto y luego poder filtrar mito/Wolbachia antes del llamado de variantes.

Dejar listo el entorno de software para indexación y mapeo.

Estado de archivos en la carpeta REFERENCE
Ruta: /home/lcastaneda/Drosophila/REFERENCE
Archivos relevantes presentes:

D_suzukii_ref.fasta (nuclear; GCF_043229965.1)

D_suzukii_ref.gff

mito_Dsuz_KU588141.fa (mitogenoma; header esperado: >dsuz_mito_KU588141)

wolbachia_wRi_GCF000022285.fa (Wolbachia wRi; headers prefijados con “>WOLB_”)

README.md / README.txt, md5sum.txt, indices/, ncbi_dataset/, drosophila_suzukii_ref.zip

Entorno de software (Conda)

Intento inicial de instalar bwa-mem2 y samtools en el env “drosophila” falló por pin de Python 3.13 y conflictos (LibMambaUnsatisfiableError).

Solución: crear un entorno limpio “maptools” con Python 3.11 y herramientas de mapeo.


BITÁCORA — Drosophila suzukii — 2025-09-01
Tema: Trimeo post-trim, QC y mapeo en SLURM (pipeline resume-safe)

Objetivos desde la última entrada (2025-08-29)

Completar el trimeo con fastp de todas las muestras (propias y SRA).

Ejecutar QC post-trim con FastQC y generar resúmenes con MultiQC.

Preparar y lanzar el mapeo contra la referencia compuesta (nuclear + mito + Wolbachia) usando bwa-mem2 en SLURM.

Endurecer el pipeline para ser reanudable (resume-safe), evitando rehacer muestras terminadas.

Estructura de datos (actual)

Lecturas post-trim (propias): /home/lcastaneda/Drosophila/CLEAN/batch01
Ej.: DSCHLL01_R1.trim.fq.gz, DSCHLL01_R2.trim.fq.gz, etc.

Lecturas post-trim (SRA): /home/lcastaneda/Drosophila/CLEAN/public_data
Ej.: SRR1026xxxx_R1.trim.fq.gz / _R2.trim.fq.gz, etc.

Referencia compuesta: /home/lcastaneda/Drosophila/REFERENCE/D_suzukii_plus_mito_wolb.fa (+ índices .0123, .bwt.2bit.64, .fai)

Entornos de software (Conda)

drosophila: FastQC y MultiQC instalados. Activación usada con: source ~/miniconda3/bin/activate drosophila

maptools: bwa-mem2, samtools (y recomendados: picard, mosdepth). Activación: source ~/miniconda3/bin/activate maptools

QC post-trim

Script FastQC post-trim adaptado para ambas carpetas (batch01 y public_data).
Salidas: /home/lcastaneda/Drosophila/QC_posttrim/fastqc/batch01 y .../public_data

MultiQC pre-trim: se preparó SBATCH; al detectar “Illegal instruction” en el cluster (posible falta de AVX2), se propusieron dos opciones: entorno “multiqc_legacy” (defaults + bioconda) o ejecutar MultiQC localmente en el Mac. Decisión: ejecutar MultiQC en el Mac (consumo liviano).

Mapeo (bwa-mem2 → samtools sort → markdup → index → flagstat)

Se creó un SBATCH de mapeo inicial y luego se actualizó a versión “resume-safe”:
• Usa hilos elásticos: THREADS=${SLURM_CPUS_PER_TASK:-16}
• Usa TMPDIR local para acelerar sort: samtools sort -T "${TMPDIR}/${sm}.tmp"
• Lógica de reanudación:

Si existe <muestra>.sorted.nodup.bam + .bai + flagstat → se salta.

Si existe <muestra>.sorted.bam (pero no nodup) → reanuda desde markdup/index/flagstat.

Si no hay sorted → mapea desde cero.
• Lockfile por muestra para evitar colisiones si se ejecutan dos jobs por error.

Directorios de salida:
• /home/lcastaneda/Drosophila/MAP/batch01
• /home/lcastaneda/Drosophila/MAP/public_data
Métricas de duplicados: /home/lcastaneda/Drosophila/METRICS/<muestra>.markdup.txt
Log por muestra de BWA: /home/lcastaneda/Drosophila/LOGS/<muestra>.bwa.log

Planificación en SLURM y afinamientos

sinfo mostró 3 nodos en la partición “basic”: n001 (64 CPU, ~252 GB), n002 (24 CPU, ~31.1 GB), n003 (48 CPU, ~31.0 GB).

El job quedó inicialmente PD (Resources) por pedir --mem=32G; se ajustó a --mem=30G para caber en n002/n003.

Job en curso: 30445, ejecutándose en n002 con -c 16 y --mem=30G.

Monitoreo y estado actual

En el momento de esta entrada, el job está procesando la primera muestra (DSCHLL01). La presencia de archivos temporales “DSCHLL01.sorted.bam.tmp.000*.bam” indica que samtools sort sigue activo; al completar, aparecerá DSCHLL01.sorted.bam y luego DSCHLL01.sorted.nodup.bam + .bai + flagstat.

Se entregaron comandos de seguimiento (squeue, sstat, tail de logs) y un sumador de QC: summarize_flagstat.sh, que consolida métricas de flagstat en /home/lcastaneda/Drosophila/METRICS/mapping_qc_flagstat.tsv (puede correrse mientras el job avanza; recoge solo muestras completas).

Buenas prácticas acordadas

No ejecutar dos mapeos simultáneos sobre el mismo directorio de salida. En caso de necesidad, separar por subconjuntos o usar carpetas de salida distintas.

Al re-lanzar (por límite de tiempo), usar el script resume-safe para saltar lo ya hecho y retomar lo pendiente.

Preferir TMPDIR local del nodo para sort (I/O más rápido) y ajustar hilos según -c.

Próximos pasos

Dejar terminar el job actual y luego ejecutar summarize_flagstat.sh para consolidar QC de mapeo.

Generar cobertura con mosdepth (global y por contigs nucleares; excluir mito/Wolbachia según contigs_nuclear.list).

MultiQC post-trim (en el Mac) para unificar los FastQC post-trim.

Preparar filtros por contig (remover lecturas mapeadas a mito/Wolbachia) antes del llamado de variantes.

Si se requiere relanzar mapeo: usar el script resume-safe con walltime mayor y, si fuese necesario, fijar nodo o ajustar recursos.


15 de septiembre.
Bitácora — Cobertura y llamado de variantes en D. suzukii (Pool-seq)

Contexto y datos
Trabajé con 34 pools: 6 propios (MAP/batch01) y 28 públicos (MAP/public\_data), todos en formato BAM final deduplicado e indexado (\*.sorted.nodup.bam + \*.bai). El genoma de referencia es D\_suzukii\_plus\_mito\_wolb.fa (con .fai) en /home/lcastaneda/Drosophila/REFERENCE. El objetivo es reproducir la metodología del paper base: cobertura con mosdepth usando -Q 20 y llamado de variantes con FreeBayes (modo Haplotype Caller) en ventanas de 250 kb, más concatenación y filtrado posterior para obtener sets comparables (autósomas y X estrictos). Se decidió excluir de los promedios de cobertura los scaffolds centroméricos/unlocalized que deprimen la media (scf\_2c y scf\_Xc), manteniéndolos como categorías separadas para diagnóstico.

Entorno de software
Se creó un environment conda “dsuz.vc” con herramientas principales: mosdepth, freebayes, bcftools, samtools, bedtools, parallel, jq, htslib. Activación estándar:
source \~/miniconda3/etc/profile.d/conda.sh
conda activate dsuz.vc

Limpieza de intermedios
Los \*.sorted.bam (previos a deduplicación) se eliminaron, manteniendo únicamente *.sorted.nodup.bam y sus índices .bai. Las salidas de samtools flagstat (*.flagstat.txt) se conservaron como QC.

Resumen de flagstat (calidad de mapeo)
Se generó un script en shell/awk para recorrer \*.flagstat.txt en batch01 y public\_data y consolidar métricas por muestra en un TSV. Ubicación del script y salida:
\~/Drosophila/scripts/flagstat\_summary.sh
/home/lcastaneda/Drosophila/METRICS/flagstat\_summary.tsv
El TSV contiene total\_reads, primary, supplementary, duplicates y tasas de mapped/properly paired, etc., útil para comparar pools propios vs públicos.

Definición de categorías cromosómicas (clave para reproducibilidad)
El ensamblaje dsu isojap1.0 se toma desde NCBI datasets:
sequence\_report.jsonl en /home/lcastaneda/Drosophila/REFERENCE/ncbi\_dataset/data/GCF\_043229965.1/sequence\_report.jsonl
El .fai del FASTA usa accesiones RefSeq (NC\_/NW\_), por lo que extraje los nombres por refseqAccession con jq. Se definieron tres BEDs principales en /home/lcastaneda/Drosophila/REFERENCE/indices:
autosomes.strict.bed = {NC\_092080.1 (chr2L), NC\_092081.1 (chr2R), NC\_092082.1 (chr3), NC\_092083.1 (chr4)}
sexX.strict.bed      = {NC\_092084.1 (chrX)}
Centroméricos/unlocalized para diagnóstico:
scf2c.bed  = {NW\_027255896.1 (scf\_2c, \~40 Mb)}
scfXc.bed  = {NW\_027255894.1 (scf\_Xc, \~6.3 Mb)}
Se justificó separar scf\_2c y scf\_Xc porque son regiones enriquecidas en TE/centroméricas con baja densidad génica y cobertura atípica; incluirlas en “autósomas” o “X” subestima la cobertura frente a lo reportado por el paper. Con “estrictos” (2L/2R/3/4 y X solo) las medias se alinean con los valores publicados.

Cobertura con mosdepth (reproducible)
Parámetros: -Q 20 para ignorar lecturas de baja calidad de mapeo. Se añadió explícitamente -F 1796 (filtro por flags por defecto de mosdepth: excluye duplicates, secondary, qcfail, unmapped; incluye supplementary). No se emitieron perfiles por base (--no-per-base) para ahorrar disco; el insumo para medias es \*.mosdepth.summary.txt.

Se implementaron dos scripts SLURM:

1. mosdepth\_all.sbatch (versión base, misma carpeta de salida que el primer ensayo)
   Calcula para cada muestra: global, autósomas estrictos y X estricta.

2. mosdepth\_all\_unplaced.sbatch (versión “no pisar”)
   Misma lógica, pero escribe en /home/lcastaneda/Drosophila/METRICS/coverage\_unplaced/ y consolida en coverage\_summary\_unplaced.tsv. Además calcula columnas separadas para scf\_2c y scf\_Xc. Este script crea los BEDs estrictos/centroméricos si no existen y usa parallel para lanzar múltiples muestras en paralelo. Recursos por defecto: -c 24, --mem=16G, pero ajustables; internamente cada mosdepth usa THREADS=2 por muestra y parallel reparte los jobs.

Consolidación de coberturas
Se añadió coverage\_collect.sh para leer \*.mosdepth.summary.txt y computar medias ponderadas por longitud (si existe fila “total”, toma su mean). Salida principal:
/home/lcastaneda/Drosophila/METRICS/coverage\_summary.tsv  (o …\_unplaced.tsv en la versión alternativa)
Columnas: dataset, sample, global\_mean, autosomes\_mean (estricto), X\_mean (estricto), y opcionalmente scf2c\_mean, scfXc\_mean.
Observación: en muestras testeadas, autosomes\_mean estricto ≈ valores del paper; incluir scf\_2c baja la media \~3–5% según muestra, consistente con su naturaleza centromérica.

Recursos y buenas prácticas de SLURM
Se inspeccionaron los nodos con sinfo/scontrol para decidir un uso prudente de recursos en un entorno compartido. Regla aplicada: pedir \~¼–⅓ de CPUs/RAM del nodo libre. Memoria empírica para FreeBayes por ventana con 34 BAMs: 1–2 GB; se dimensiona “mem ≈ 2 GB × ventanas en paralelo”.

Prueba piloto de FreeBayes (Haplotype Caller) en ventanas de 250 kb
Objetivo: validar throughput, tamaño de VCF y campos INFO/FORMAT necesarios para filtros, antes del run completo.

Entradas:
FASTA: /home/lcastaneda/Drosophila/REFERENCE/D\_suzukii\_plus\_mito\_wolb.fa (+ .fai)
Lista de BAMs (34 pools): /home/lcastaneda/Drosophila/VARIANT/bams.list
Ventanas: se generan desde el .fai con tamaño 250,000 bp (no solapadas). Para el piloto se tomaron las primeras 10 ventanas de NC\_092080.1 (chr2L) para acelerar.

Ejecución:
Script: \~/Drosophila/scripts/freebayes\_pilot.sbatch
Recursos piloto: -c 12, --mem=32G, tiempo 3 h, ejecutado en nodo idle (n001) sin monopolizar recursos.
Flags FreeBayes (según paper):
-K -C 1 -F 0.01 -G 5 -E -1 --limit-coverage 500 -n 4 -m 30 -q 20
Se usó freebayes-parallel si estaba disponible; de lo contrario, GNU parallel repartiendo por -r [chr\:start-end](chr:start-end). La salida del piloto se comprimió e indexó con bgzip/tabix:
/home/lcastaneda/Drosophila/VARIANT/raw\_vcfs/pilot/pilot\_2L\_10wins.vcf.gz

Notas metodológicas para la fase completa
Se llamará en todo nuclear, pero el reporte/estadísticas principales se harán por categorías “estrictas” (autosomas = 2L/2R/3/4; X solo). Y y centroméricos se podrán mantener aparte. El filtro del paper incluye NS>100, pero esa condición proviene de su coanálisis pool+individuos; con 34 pools, NS>100 sería inoperable. Decisión para reproducibilidad con nuestros datos de pools: mantener filtros duros (QUAL, DP, SAF/SAR, RPR/RPL, EPP/SRP) y MAF global > 0.01, y omitir NS o reemplazarlo por un umbral compatible (p. ej., NS≥20). Esto se documentará explícitamente en el pipeline final.

Plan de pipeline completo (pendiente de lanzar tras el piloto)

1. Generar todas las ventanas de 250 kb desde el .fai.
2. Ejecutar FreeBayes multi-muestra con las flags del paper repartiendo por ventana (parallel) y escribir VCFs por ventana.
3. Concatenar con bcftools por categorías: autósomas estrictos y X estricta, asegurando el orden de contigs y generando índices CSI/Tabix.
4. Filtrar variantes bialélicas y aplicar los filtros:
   QUAL>20; 100\<DP<5000; SAF>0; SAR>0; RPR>1; RPL>1; EPP>0; SRP>0; MAF global > 0.01 (con RO/AO sumadas a través de muestras).
   Respecto a NS, documentar decisión (omitir o NS≥20).
5. Cuantificar por tipo de variante para comparar con el paper: SNP, MNP, indel y “complex”.
6. Mantener VCFs “raw” y “filtered” en /home/lcastaneda/Drosophila/VARIANT/{raw\_vcfs,concat,filtered} con un README de versiones y parámetros.

Verificación de consistencia con el paper
Se contrastó la cobertura realizada en pools públicos: al usar autósomas estrictos y X estricta, las medias se alinearon con lo publicado (las discrepancias iniciales se explicaron por la inclusión de scf\_2c/scf\_Xc y, en general, por qué bases entran al promedio). Para reporte de cobertura, se acordó usar autósomas estrictos y X estricta, y conservar columnas separadas para scf\_2c y scf\_Xc como referencia.

Rutas y archivos clave
Referencia y derivados:
/home/lcastaneda/Drosophila/REFERENCE/D\_suzukii\_plus\_mito\_wolb.fa(.fai)
/home/lcastaneda/Drosophila/REFERENCE/ncbi\_dataset/data/GCF\_043229965.1/sequence\_report.jsonl
/home/lcastaneda/Drosophila/REFERENCE/indices/{autosomes.strict.bed,sexX.strict.bed,scf2c.bed,scfXc.bed}
Mapeos:
/home/lcastaneda/Drosophila/MAP/batch01/*.sorted.nodup.{bam,bam.bai}
/home/lcastaneda/Drosophila/MAP/public\_data/*.sorted.nodup.{bam,bam.bai}
Coberturas:
/home/lcastaneda/Drosophila/METRICS/coverage\*/\[dataset]/\[sample].{global,autosomes,sexX,scf2c,scfXc}.mosdepth.summary.txt
/home/lcastaneda/Drosophila/METRICS/coverage\_summary\*.tsv
Variantes (piloto):
/home/lcastaneda/Drosophila/VARIANT/bams.list
/home/lcastaneda/Drosophila/VARIANT/regions/{regions.250kb.txt,pilot\_2L\_10.txt}
/home/lcastaneda/Drosophila/VARIANT/raw\_vcfs/pilot/pilot\_2L\_10wins.vcf.gz(.tbi)
Logs:
/home/lcastaneda/Drosophila/LOGS/\*

Recursos SLURM y prácticas
Inspección de nodos y recursos: sinfo -N -o "%N %c %m %t %E", scontrol show node <nodo>, squeue -w <nodo>. Se eligió no exceder \~¼–⅓ del nodo. Piloto con -c 12, --mem=32G en n001 (idle). Para el run completo, apuntar a -c 24 y --mem\~64–96G en n001, o escalas proporcionales en n002/n003, verificando FreeMem antes de enviar.

Notas para el manuscrito
Especificar que las coberturas reportadas para autósomas y X se calcularon con mosdepth (-Q 20, -F 1796) usando “autosome strict” (2L/2R/3/4) y “X strict” (X), con scf\_2c y scf\_Xc analizados por separado como regiones centroméricas. Para variantes, indicar flags exactas de FreeBayes, partición en ventanas no solapadas de 250 kb, concatenación con bcftools y filtros duros (QUAL/DP/SAF/SAR/RPR/RPL/EPP/SRP) más MAF global > 0.01; clarificar el tratamiento de NS en el contexto de 34 pools.

Próximos pasos inmediatos
Esperar a que termine el piloto para medir tiempos/tamaños y confirmar presencia de campos AO/RO/DP necesarios para MAF. Con eso, lanzar el pipeline completo (todas las ventanas sobre autósomas estrictos y X estricta), concatenar y aplicar los filtros finales, y obtener los conteos por clase de variante comparables con el paper.


Bitácora – Proyecto D. suzukii (variant-droso), etapa de variant calling y PCA

Después del mapeo de los 34 pools (28 públicos SRA y 6 propios), se procedió al llamado de variantes usando FreeBayes v1.3.6. El análisis se ejecutó en 1,158 ventanas no solapadas de 250 kb que cubren todo el genoma nuclear, siguiendo los parámetros del paper base: -K -C 1 -F 0.01 -G 5 -E -1 --limit-coverage 500 -n 4 -m 30 -q 20. La salida de cada ventana se almacenó en /home/lcastaneda/Drosophila/VARIANT/raw_vcfs/by_window/ como archivos comprimidos (.vcf.gz) e indexados (.tbi). Se realizaron controles de calidad de los VCFs con bcftools view -h, vt validate y vcf-validator, los cuales confirmaron que la mayoría de las ventanas tenían variantes válidas, aunque algunas resultaron vacías (sin variantes).

La concatenación inicial de todas las ventanas falló por la limitación de “Too many open files”. Para solucionarlo, se implementó un esquema por bloques (chunks) de ~150 ventanas, concatenando después los bloques en un paso final. Esto permitió obtener tres conjuntos principales de datos en /home/lcastaneda/Drosophila/VARIANT/concat:

autosomes.raw.vcf.gz (~16 GB) con 22,059,959 variantes.

X.raw.vcf.gz (~3 GB) con 4,387,848 variantes.

nuclear_all.raw.vcf.gz (~21 GB) con 28,773,207 variantes (incluye autosomas, X y contigs nucleares unplaced).

Posteriormente se aplicó un filtrado “paper-like” para retener solo variantes bialélicas de alta calidad. Los filtros aplicados fueron: QUAL>20, 100<DP<5000, SAF>0, SAR>0, RPR>1, RPL>1, EPP>0, SRP>0, 0.01<AF<0.99 y F_MISSING<0.15. Con esto se obtuvieron los siguientes resultados:

autosomes.raw.filt.vcf.gz (~4.3 GB) con 6,471,262 SNPs.

X.raw.filt.vcf.gz (~0.8 GB) con 1,273,026 SNPs.

nuclear_all.raw.filt.vcf.gz (~5.3 GB) con 8,058,240 SNPs.

Los archivos fueron indexados con .tbi y validados para asegurar consistencia. El conteo de variantes concuerda con las expectativas del paper de referencia, confirmando la integridad del pipeline.

Se construyó además un archivo de metadatos sample_meta.tsv en formato tabulado (3 columnas: SRA_ID, ID, Location), que permite enlazar cada muestra con su código interno y su localidad de origen. Este archivo es esencial para la interpretación de los resultados y la visualización posterior.

Para los análisis de estructura poblacional, se creó un nuevo entorno de R (dsuz.R) con instalación de poolfstat, vcfR, data.table, ggplot2, optparse y acceso a bcftools desde el sistema. Se escribió un script en R (random_allele_pca.R) que toma el archivo nuclear_all.raw.filt.vcf.gz, lo convierte con vcf2pooldata, y realiza un PCA usando la función randomallele.pca de poolfstat. Como aún no se definió un archivo con los tamaños reales de los pools (pool_sizes.tsv), se asumió un tamaño estándar de 40 individuos por pool. El SLURM script asociado (pca_poolfstat.sbatch) corre el análisis en el cluster HPC y genera como salida:

random_allele_pca_scores.tsv (coordenadas de individuos en el PCA).

random_allele_pca_var_explained.tsv (proporción de varianza explicada por cada eje).

random_allele_pca_PC1_PC2.pdf (gráfico de dispersión).

random_allele_pca_scree.pdf (gráfico de scree plot).

El análisis de PCA se encuentra actualmente en curso, procesando los 34 pools con los SNPs nucleares filtrados. Los siguientes pasos contemplan revisar la distribución de muestras en el PCA, incorporar los tamaños de pool reales en pool_sizes.tsv para aumentar la precisión, calcular FST global y por pares usando poolfstat, y preparar el pipeline para inferencias demográficas mediante espectros de frecuencia alélica (SFS) y fastsimcoal2.