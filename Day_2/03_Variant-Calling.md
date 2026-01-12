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

