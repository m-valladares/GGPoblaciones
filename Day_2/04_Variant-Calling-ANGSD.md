 # Variant Calling

- **ANGSD** ([Korneliussen et al., 2014](https://doi.org/10.1186/s12859-014-0356-4)) → datos de baja cobertura (lcWGS), usando *genotype likelihoods* en lugar de genotipos fijos

### 5.1 Comparación de aproximaciones

En este taller hemos explorado dos aproximaciones distintas para estudiar la variación genética a partir de datos de secuenciación masiva (NGS). Entender cuándo usar cada una es clave para cualquier estudio.

1. FreeBayes: El enfoque del "Hard Calling"
FreeBayes es un llamador de variantes (variant caller) basado en un modelo Bayesiano. Su objetivo es decidir: para cada posición y cada individuo, intenta determinar con certeza si el genotipo es homocigoto (AA, TT) o heterocigoto (AT).
  - Resultado: Un archivo VCF con genotipos definidos.
  - Ventaja: Los resultados son fáciles de interpretar y compatibles con casi todas las herramientas de genética.
  - Limitación: Si la cobertura es baja (pocas lecturas por sitio), el programa se ve obligado a "adivinar" el genotipo, lo que introduce sesgos y errores que se propagan en los análisis posteriores.

2. ANGSD: El enfoque de "Probabilidades"
ANGSD (Analysis of Next Generation Sequencing Data) representa un cambio de paradigma. En lugar de forzar una decisión sobre qué genotipo tiene cada individuo, ANGSD calcula la Verosimilitud del Genotipo (Genotype Likelihoods).
  - Resultado: Archivos de frecuencias (MAFs) y probabilidades (Beagle).
  - Filosofía: "No estoy seguro de si este individuo es AT o AA, así que mantendré ambas probabilidades para el análisis estadístico final".
  - Ventaja: Es el estándar de oro para datos de baja o media cobertura y para Pool-seq. Al no "llamar" genotipos, evita errores sistemáticos y permite estimar frecuencias alélicas, estructuras poblacionales (PCA) y diversidad nucleotídica de forma mucho más precisa.

En resumen: Mientras que FreeBayes nos da un veredicto (VCF), ANGSD nos da una estimación estadística que preserva la incertidumbre de los datos crudos.

### 5.2 Nota sobre la ejecución en el Taller

El análisis con ANGSD es computacionalmente más intenso que los pasos anteriores, ya que realiza cálculos estadísticos complejos para cada sitio del genoma. Debido a que el tiempo de nuestra sesión es limitado y queremos priorizar la interpretación de los datos biológicos, no ejecutaremos este script en vivo.

En su lugar, realizaremos las siguientes actividades:

1. Análisis del Script: Desglosaremos la lógica del comando para entender cómo se configuran los filtros de calidad y los modelos probabilísticos.
2. Exploración de Resultados: Utilizaremos archivos pre-calculados (idénticos a los que generaría el script) para aprender a leer y extraer información de los formatos de salida de ANGSD.

Este enfoque nos permite entender la "caja negra" del software sin las esperas del procesamiento, asegurando que tengamos tiempo suficiente para discutir qué nos dicen estos datos sobre las poblaciones de *Haematobia irritans*.

### 5.3 Script ANGSD

El script necesario para realizar este análisis se encuentra disponible en la carpeta de scripts del Día 2 en el servidor del curso:

```bash
~/Day02/SCRIPTS/angsd_dsuz.sh
```

Ahora analicemos el detalle del script, como ya vimos en los scripts previos, la primera sección es la **cabecera y configuración del entorno**. Esta parte le indica al sistema operativo y al gestor de tareas (SLURM) cómo debe ejecutarse el script y qué recursos necesita. La segunda sección de **definición de rutas y organización**. En esta parte definimos las variables de entorno que el script utilizará. Luego, tenemos la sección de **carga de ambiente y gestión de software**.

Sección **configuración de hilos y filtros de calidad**, en esta etapa preparamos las variables que ANGSD utilizará para decidir qué datos son lo suficientemente buenos para ser analizados.

```bash
THREADS=${SLURM_CPUS_PER_TASK:-8}

# Filtros de cobertura y presencia
MIN_IND=25          
MIN_DP_IND=1        
MIN_DP_TOTAL=15     
MAX_DP_TOTAL=100    

# Calidad de mapeo y base
MIN_MAPQ=20
MIN_Q=20
SNP_PVAL=1e-6
```

El detalle de la gestión de estos parámetros es el siguiente:
- `THREADS`: Al igual que en los scripts anteriores, sincronizamos el software con los núcleos pedidos a SLURM. ANGSD es muy eficiente utilizando múltiples hilos para procesar diferentes regiones del genoma simultáneamente.
- `MIN_IND 25`: Este es uno de los filtros más importantes. Le indica a ANGSD que solo analice sitios que tengan datos en, al menos, 25 individuos. Esto asegura que nuestras estimaciones de frecuencias alélicas representen a la población y no a unos pocos individuos aislados.
- `MIN_DP_IND` y `MIN_DP_TOTAL`: Controlamos la profundidad de lectura (cobertura). Exigimos al menos 1 lectura por individuo y un total de 15 lecturas sumando a todos. Esto evita zonas de baja confianza donde el error de secuenciación podría confundirse con variantes reales.
- `MAX_DP_TOTAL 100`: Ponemos un límite superior. Si un sitio tiene más de 100 lecturas (cuando nuestra media es mucho menor), probablemente se deba a un error de ensamblaje o a una región repetitiva que "atrapó" lecturas de otras partes del genoma.
- `MIN_MAPQ` y `MIN_Q`: Filtramos lecturas mal mapeadas (calidad < 20) y bases individuales donde el secuenciador no estuvo seguro de su lectura (calidad Phred < 20).
- `SNP_PVAL 1e-6`: A diferencia de los métodos tradicionales, ANGSD usa un test estadístico para identificar SNPs. Compara la hipótesis de que un sitio es variable frente a la de que es constante. Solo los sitios con un valor de p (p-value) menor a 10−6 serán considerados como SNPs verdaderos.


Sección **ejecución de ANGSD (GL + MAF + BEAGLE)**. En este bloque invocamos el comando principal. A diferencia de otros programas que requieren múltiples pasos, ANGSD puede realizar el filtrado, el cálculo de verosimilitudes y la estimación de frecuencias en una sola ejecución.

```bash
angsd \
  -b "${BAMLIST}" \
  -ref "${REF}" \
  -out "${PREFIX}" \
  -nThreads "${THREADS}" \
  -uniqueOnly 1 -remove_bads 1 -only_proper_pairs 1 -C 50 \
  -minMapQ "${MIN_MAPQ}" \
  -minQ "${MIN_Q}" \
  -minInd "${MIN_IND}" \
  -setMinDepthInd "${MIN_DP_IND}" \
  -setMinDepth "${MIN_DP_TOTAL}" \
  -setMaxDepth "${MAX_DP_TOTAL}" \
  -doCounts 1 \
  -GL 1 \
  -doMajorMinor 1 \
  -doMaf 1 \
  -doGlf 2 \
  -SNP_pval "${SNP_PVAL}"
  ```

El desglose de los módulos específicos de ANGSD es el siguiente:
- Pre-procesamiento de lecturas:
  - `-uniqueOnly 1`: Descarta lecturas que mapean en múltiples sitios del genoma.
  - `-remove_bads 1`: Elimina lecturas con flags de mala calidad (segmentos rotos, fallos de secuenciación).
  - `-only_proper_pairs 1`: Solo utiliza pares de reads (R1 y R2) que mapearon a la distancia y orientación esperada.
  - `-C 50`: Ajusta la calidad de mapeo para lecturas con muchos desajustes (mismatches), reduciendo el peso de lecturas dudosas.

- Cálculo de Verosimilitudes y Frecuencias:
  - `-GL 1`: Activa el modelo de Genotype Likelihoods. En lugar de decidir un genotipo fijo, calcula la probabilidad de todos los posibles genotipos basándose en la calidad de las bases y la cobertura.
  - `-doMajorMinor 1`: Indica al programa que determine cuáles son los alelos mayoritarios y minoritarios a partir de las verosimilitudes. Esto es esencial para estudios de poblaciones.
  - `-doMaf 1`: Ordena el cálculo de la Frecuencia Alélica Minoritaria (MAF). Esta frecuencia no se obtiene contando genotipos, sino estimándola estadísticamente para compensar la baja cobertura.

- Formatos de Salida:
  - `-doGlf 2`: Exporta las probabilidades de los genotipos en formato BEAGLE. Este archivo es el estándar para realizar análisis posteriores como PCAngsd (estructuramiento poblacional) o imputación.
  - `-doCounts 1`: Obliga al programa a realizar un conteo de bases por sitio, necesario para aplicar los filtros de profundidad (`-setMinDepth`).


### 5.4 Entendiendo los Resultados de ANGSD




Una vez que el script finaliza, encontraremos varios archivos con el prefijo definido en el script (hi_chr1_demo). Cada uno tiene una función específica para los análisis posteriores:
- `.mafs.gz`: Es el archivo principal para el análisis de variantes. Contiene la posición de cada SNP, los alelos identificado como mayoritario y minoritario, y la frecuencia alélica estimada. A diferencia de un VCF, aquí no vemos individuos, sino la información agregada de la población.
- `.beagle.gz`: Este archivo contiene las probabilidades de los genotipos para cada individuo en cada sitio. Es un formato especializado que se utiliza como entrada para herramientas de estructura poblacional (como PCAngsd) o para estimar niveles de mezcla (admixture).
- `.arg`: Es un archivo de texto plano que registra todos los parámetros y comandos exactos utilizados en la ejecución. Es la pieza clave para la reproducibilidad; si necesitas publicar tus resultados, este archivo te dice exactamente qué filtros aplicaste.
- `.glf.gz`: Contiene las verosimilitudes de los genotipos en formato binario. Es el archivo más pesado y sirve como base para generar otros formatos o realizar cálculos de diversidad nucleotídica (theta, pi, D de Tajima).

