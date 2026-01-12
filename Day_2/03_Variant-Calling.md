<<<<<<< HEAD
# Variant Calling

Una vez que contamos con archivos BAM limpios, ordenados e indexados, el siguiente paso del pipeline es el llamado de variantes (*Variant Calling*).
Este proceso consiste en identificar posiciones del genoma donde las secuencias de una o más muestras difieren respecto al genoma de referencia, típicamente en forma de SNPs (Single Nucleotide Polymorphisms) o indels.

Las variantes constituyen la base de prácticamente todos los análisis en genómica poblacional: estructura genética, diversidad, selección natural, demografía y flujo génico, entre otros.

En este curso abordaremos dos enfoques complementarios, que responden a distintos tipos de datos:
- **FreeBayes** ([Garrison & Marth, 2012](https://doi.org/10.48550/arXiv.1207.3907)) → datos de alta cobertura (WGS > 30–50X), con llamado explícito de genotipos (*hard genotypes*)
- **ANGSD** ([Korneliussen et al., 2014](https://doi.org/10.1186/s12859-014-0356-4)) → datos de baja cobertura (lcWGS), usando genotype likelihoods en lugar de genotipos fijos
=======
# Mapeo

Una vez que las lecturas han sido limpiadas mediante trimming, el siguiente paso del pipeline es el **mapeo** (alignment) contra un genoma de referencia. El objetivo del mapeo es determinar en qué posición del genoma se originó cada lectura, permitiendo luego estimar cobertura, detectar variantes y realizar análisis poblacionales.
>>>>>>> e8d4a600f60e7a20db60c8693c23d577cad2504a

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

