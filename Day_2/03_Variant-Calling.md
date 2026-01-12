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
Day03/
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



