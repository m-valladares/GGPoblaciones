# Diagnóstico del VCF posterior al llamado de variantes (RADseq)

Este documento corresponde al **diagnóstico inicial del archivo VCF** generado después del llamado de variantes.  
El objetivo es **entender la calidad y estructura de los datos antes de aplicar cualquier filtrado**, algo fundamental en genética de poblaciones, especialmente con datos de representación reducida (ddRADseq / GBS).

---

# Guía de Instalación: Ambiente de Análisis Genómico
Para asegurar que las herramientas funcionen correctamente en la partición de cómputo, crearemos un ambiente aislado utilizando Conda. Esto evitará conflictos de versiones y errores de arquitectura.

## 1. Preparación del entorno
Primero, limpiaremos cualquier módulo previo y cargaremos el gestor de paquetes Miniconda.

```bash

# Limpiar módulos anteriores
module purge

# Cargar el módulo de Miniconda
module load miniconda3/24.7.1-zen4-5

```


## 2. Creación y activación del ambiente
Crearemos un ambiente específico llamado filt_vcf. Si el sistema te pide confirmar la instalación, presiona y.

```Bash

# Crear el ambiente vacío
conda create -n filt_vcf -y

# Activar el ambiente
conda activate filt_vcf

```

*Nota:* Solo en caso que solicite iniciar conda, indicaremos `conda init`. Y luego, para poder activar ambientes conda en la sesión actual, recargamos la configuración del shell:

```bash
source ~/.bashrc
```

3. Instalación de herramientas (BCFtools y VCFtools)
Instalaremos las versiones más recientes desde los canales oficiales de Bioinformática.

```Bash

# Instalar las herramientas necesarias
conda install -c conda-forge -c bioconda bcftools

conda install -c conda-forge -c bioconda vcftools

```

## Inicio de Sesión

Antes de cargar cualquier herramienta, debemos pedir recursos al clúster para no trabajar en el nodo de acceso.

1. Solicitar nodo de cómputo: Ejecuta esto y espera a que el prompt cambie (ej. de [usuario@leftraru] a [usuario@cn045]).

```bash

# srun -p labs --pty --mem=2G -n 1 -c 1 --time=03:00:00 /bin/bash
srun -p labs -n 1 -c 8 --mem-per-cpu=1000 --pty bash

```

A continuación, activamos el ambiente recién creado:

```bash

conda activate filt_vcf

```

# 2. Crear tu espacio de trabajo y traer los datos

```bash

# Crear tu carpeta de trabajo
mkdir -p Day03/Resultados_Estudiante
mkdir -p Day03/Data

# Crear el enlace simbólico a los archivos
# Esto crea un atajo llamado 'Data' que apunta a los archivos originales
ln -s /home/courses/student22/Day03/Data ./Day03/Data/

# Entrar a tu carpeta y copiar los inputs
cd ~/Day03/Resultados_Estudiante
cp ../Data/Data/Orestias_final_variants.vcf.gz .

```

---

## Paso siguiente: el filtrado de calidad

Para genética de poblaciones **no puedes usar el VCF tal cual sale del llamado de variantes**.  
Es necesario **“limpiarlo”**.

Existen dos tipos de filtrado conceptualmente distintos:

### 1. Filtrado de calidad (VCF → Clean VCF)
Su objetivo es eliminar el **ruido técnico** (errores de secuenciación, mapeo deficiente, sitios poco confiables).

Aquí decides:
- qué posiciones del genoma son confiables
- qué SNPs representan variación biológica real

### 2. Filtrado por ligamiento (LD pruning; Clean VCF → Pruned VCF)
Su objetivo **NO es eliminar errores**, sino cumplir los **supuestos estadísticos** de ciertos modelos (PCA, Admixture).

Aquí eliminas **redundancia**, no mala calidad.

---

### ¿Por qué separarlos?

- **Para FST y diversidad genética (π, Ho, He, FIS):**  
  Debes usar el archivo **SIN LD pruning**.  
  Quieres **todos los SNPs posibles** para maximizar la resolución de la historia evolutiva.

- **Para PCA y Admixture:**  
  Debes usar el archivo **CON LD pruning**.  
  Si no lo haces, los SNPs ligados (bloques heredados juntos) “pesan” más en el análisis y pueden crear **estructura artificial**, haciendo parecer que hay diferenciación poblacional cuando solo hay cercanía física en el cromosoma.

---

## Conteo de SNPs crudos

Antes de cualquier análisis, es importante saber con cuántos sitios variantes estamos trabajando.

Para ello se puede utilizar una de las herramientas de BCFtools

```bash

bcftools view -H Orestias_final_variants.vcf.gz | wc -l

```

Este número incluye:

- SNPs de buena calidad

- SNPs de baja calidad

- SNPs presentes en muy pocos individuos

---


```bash

# Crear la carpeta para los resultados si no existe
mkdir -p stats_full
VCF="Orestias_final_variants.vcf.gz"
PREFIX="stats_full/Orestias_full"

```

### 1. CALIDAD POR SITIO (.lqual)
Calcula el puntaje Phred de calidad para cada variante.
Útil para identificar qué tan confiable es el llamado de cada SNP.

```bash
echo "1/7 Calculando Calidad por sitio..."
vcftools --gzvcf $VCF --site-quality --out $PREFIX
```

### 2. PROFUNDIDAD MEDIA POR SITIO (.ldepth.mean)
Calcula cuántas lecturas (reads) hay en promedio para cada posición genómica sumando todos los individuos.
Ayuda a identificar regiones mal mapeadas (exceso de profundidad) o con poca confianza (baja profundidad).

```bash
echo "2/7 Calculando Profundidad media por sitio..."
vcftools --gzvcf $VCF --site-mean-depth --out $PREFIX
```

### 3. DATOS FALTANTES POR SITIO (.lmiss)
Reporta qué proporción de individuos NO tiene un genotipo para cada variante.
Sirve para eliminar SNPs que solo están presentes en unos pocos individuos.

```bash
echo "3/7 Calculando Datos faltantes por sitio..."
vcftools --gzvcf $VCF --missing-site --out $PREFIX
```

### 4. FRECUENCIA ALÉLICA (.frq)
Calcula la frecuencia de los alelos en cada sitio.
El flag `--max-alleles 2` asegura que solo analicemos sitios bialélicos (más simples para análisis de poblaciones).
Sirve para filtrar por Minor Allele Frequency (MAF).

```bash
echo "4/7 Calculando Frecuencias alélicas..."
vcftools --gzvcf $VCF --freq2 --out $PREFIX --max-alleles 2
```

### 5. PROFUNDIDAD POR INDIVIDUO (.idepth)
Calcula la profundidad media de lecturas para cada pez individualmente.
Permite identificar si alguna muestra falló en la secuenciación o tiene mucho menos datos que el resto.

```bash
echo "5/7 Calculando Profundidad por individuo..."
vcftools --gzvcf $VCF --depth --out $PREFIX
```

### 6. DATOS FALTANTES POR INDIVIDUO (.imiss)
Reporta cuántos sitios le faltan a cada individuo.
Es crucial para decidir si debemos descartar un individuo completo antes de filtrar SNPs.

```bash
echo "6/7 Calculando Datos faltantes por individuo..."
vcftools --gzvcf $VCF --missing-indv --out $PREFIX
```

### 7. HETEROCIGOSIDAD POR INDIVIDUO (.het)
Calcula el coeficiente de consanguinidad (F) y la heterocigosidad observada/esperada.
Ayuda a detectar contaminación de muestras (exceso de heterocigotos) o individuos muy endogámicos.

```bash
echo "7/7 Calculando Heterocigosidad por individuo..."
vcftools --gzvcf $VCF --het --out $PREFIX
echo "¡Todo listo! Revisa la carpeta 'stats_full'"
```
---

Ahora, tendremos los archivos resultantes que podemos clasificarlos en dos:

**- Los análisis "por Sitio" (Site):** Son para limpiar el genoma. Buscamos las mejores "posiciones" para estudiar.

**- Los análisis "por Individuo" (Indv):** Son para limpiar la población. Buscamos si algún pez tiene tan mala calidad que nos va a sesgar los resultados (ej. un pez con mucho missing data hará que perdamos miles de SNPs en el filtrado final).

---

*"vistazo rápido"* desde la terminal para tener una idea de lo que te vas a encontrar:
Por ejemplo, mira el archivo de datos faltantes por individuo para ver si hay algún pez que destaque negativamente:

```bash
column -t stats_full/Orestias_full.imiss | head -n 10

```

### Resultado:

```bash
INDV    N_DATA  N_GENOTYPES_FILTERED  N_MISS  F_MISS
ASC01   260377  0                     223395  0.857967
ASC02   260377  0                     221358  0.850144
ASC03   260377  0                     222878  0.855982
ASC05   260377  0                     222696  0.855283
ASC06   260377  0                     223558  0.858594
ASC07   260377  0                     222169  0.853259
ASC08   260377  0                     223094  0.856811
ASC09   260377  0                     222431  0.854265
ASC10   260377  0                     222931  0.856185
```

Tenemos una situación importante aquí: un nivel de datos faltantes **extremadamente alto**.

Fíjate en la columna `F_MISS`: las muestras tienen alrededor de un **85% de datos faltantes (0.85)**. Esto significa que de cada 100 sitios que el programa intentó llamar, solo encontró información en 15.

### ¿Por qué está pasando esto?
Si los datos provienen de secuenciación de representación reducida, esto es relativamente común en archivos VCF "crudos". La razón es que el comando de `bcftools mpileup` que se ejecutó para hacer el llamado de variantes antes intentó llamar variantes en todos los lugares donde al menos un individuo tenía una lectura. Como RADseq solo secuencia pequeños fragmentos dispersos, la gran mayoría de los individuos no tendrán lecturas en los sitios que sí tiene el individuo de al lado.

### ¿Qué significa para nuestro filtrado?
Olvídate de hacer un filtro del 90% (que se usa rutinariamente): Si aplicas un filtro estricto como `--max-missing 0.9` (que exige que el 90% de los individuos tengan el SNP), te vas a quedar con cero variantes.

### Ajuste de expectativas:
Para RADseq en especies silvestres, solemos ser más permisivos. Un umbral común es 0.5 (50%) o incluso 0.25 (25%) si el objetivo es tener muchos SNPs para filogenia o estructura.

**Conclusión: No hay un "botón mágico" de filtrado.**

Si tienes un 85% de missing data inicial, filtrar al 90% es un suicidio de datos.

Tienes que encontrar el balance entre "sitios muy confiables pero pocos" vs "muchos sitios con algunos datos faltantes".

Para ver si hay algún sitio que realmente valga la pena rescatar, corre este comando en la terminal:

¿Cuántos sitios tienen datos en al menos el 50% de los peces?
(Buscamos sitios donde F_MISS en el archivo .lmiss sea menor a 0.5)

```bash
awk '$6 < 0.5' stats_full/Orestias_full.lmiss | wc -l
```

**Resultado:** 35265 sitios con 50% de los individuos con datos

Esto quiere decir que tenemos 35,265 SNPs que están presentes en al menos la mitad de los individuos.

Para un análisis de genética de poblaciones (*Orestias* en este caso), 35 mil marcadores de alta calidad es un número perfecto. Es más que suficiente para obtener un PCA nítido, un Admixture detallado y estimaciones de $F_{ST}$ muy robustas.

### Análisis de la situación:
Este es un buen ejemplo de por qué el filtrado por sitio es más importante que el filtrado por individuo en datos de representación reducida (como RADseq):
- El problema: Los archivos .imiss decían que a cada individuo le falta el 85% de los datos. Eso suena alarmante.
- La realidad: El archivo VCF crudo es gigantesco porque incluye sitios que quizás solo tiene un individuo.
- La solución: Al pedir sitios compartidos por al menos el 50% de la población, "limpias" toda esa periferia de datos pobres y te quedas con el "corazón" del dataset: esos 35,265 SNPs donde los individuos sí coinciden.

### Descarga los archivos generados por vcftools a tu computador y corre el script `diagnostico_vcf.R` en RStudio

En este caso, al ser 95 individuos, el `mean_depth` se calcula sumando la profundidad de todos y dividiéndola por 95. Si un sitio tiene un `mean_depth` de 500x, significa que o es una zona de ADN repetitivo (donde se pegan lecturas de muchas partes del genoma) o es un parálogo (un gen duplicado que se mapea erróneamente en el mismo lugar).

### Ejecuta esto en tu consola de R:

```bash
summary(var_depth$mean_depth)
```

Fíjate en los cuantiles (5% y 95%)
Esto te dará los umbrales basados puramente en tus datos, sin adivinar:

```bash
quantile(var_depth$mean_depth, probs = c(0.05, 0.95))
```

### El diagnóstico: Una distribución con "inflación de ceros"

- Media vs. Mediana: La media es 4.11, pero la mediana es casi cero (0.03). Esto sucede porque tenemos una cantidad masiva de sitios que solo están presentes en 1 o 2 individuos (profundidades bajísimas), lo que arrastra la mediana al suelo.

- El 75% de los datos (3rd Qu.): Sigue siendo bajísimo (0.06). Esto significa que la gran mayoría de los sitios en el VCF crudo son "sitios huérfanos" que no nos sirven para genética de poblaciones.

- El 5% superior (95% quantile): Salta hasta 32.87. Aquí es donde están los SNPs que sí están presentes en muchos individuos.

Entonces, para este dataset lo más adecuado sería:

**- Mínimo (`--min-meanDP`):** No pongamps un mínimo muy alto. Si ponemos 10x, perderíamos casi todo. Como ya vamos a usar `--max-missing 0.5`, ese filtro se encargará de eliminar los sitios de baja profundidad automáticamente.

**- Máximo (`--max-meanDP`):** El cuantil 95% es 32.87. Podríamos redondear a 40x o 50x. Todo lo que esté por encima de eso es sospechoso de ser un error de mapeo o una secuencia repetitiva (parálogos).

