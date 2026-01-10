# Diagnóstico del VCF posterior al llamado de variantes (RADseq)

Este documento corresponde al **diagnóstico inicial del archivo VCF** generado después del llamado de variantes.  
El objetivo es **entender la calidad y estructura de los datos antes de aplicar cualquier filtrado**, algo fundamental en genética de poblaciones, especialmente con datos de representación reducida (ddRADseq / GBS).

---

## Inicio de Sesión

Antes de cargar cualquier herramienta, debemos pedir recursos al clúster para no trabajar en el nodo de acceso.

1. Solicitar nodo de cómputo: Ejecuta esto y espera a que el prompt cambie (ej. de [usuario@leftraru] a [usuario@cn045]).

```bash

srun -p labs --pty --mem=2G -n 1 -c 1 --time=03:00:00 /bin/bash

```


# 2. Crear tu espacio de trabajo y traer los datos

```bash

# Crear tu carpeta de trabajo
mkdir -p Day03/Resultados_Estudiante

# Crear el enlace simbólico a los archivos
# Esto crea un atajo llamado 'Data' que apunta a los archivos originales
ln -s /home/courses/student22/Day03/Data ./Day03/Data/

# Entrar a tu carpeta y copiar los inputs
cd ~/Day03/Resultados_Estudiante
cp ../Data/Orestias_final_variants.vcf.gz .

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

# Cargar las dependencias y luego BCFtools
module load icc/2019.2.187-GCC-8.2.0-2.31.1
module load impi/2019.2.187
module load BCFtools/1.10.2

bcftools view -H Orestias_final_variants.vcf.gz | wc -l

```

Este número incluye:

- SNPs de buena calidad

- SNPs de baja calidad

- SNPs presentes en muy pocos individuos

---

```bash

# 1. Limpiar módulos para evitar conflictos de arquitectura
module purge

# 2. Cargar el compilador compatible con la partición 'labs'
module load gcc/11.5.0-skylake-ukazxjg

# 3. DEFINIR RUTAS (Usando la carpeta del curso)
export VCFTOOLS_DIR="/home/courses/student22/projects/vcftools/vcftools-0.1.16"
export PATH="$VCFTOOLS_DIR/bin:$PATH"
export PERL5LIB="$VCFTOOLS_DIR/src/perl:$PERL5LIB"

echo "VCFtools cargado correctamente desde: $VCFTOOLS_DIR"

vcftools

```

```bash

# Crear la carpeta para los resultados si no existe
mkdir -p stats_full
VCF="Orestias_final_variants.vcf.gz"
PREFIX="stats_full/Orestias_full"

echo "1/7 Calculando Calidad por sitio..."
vcftools --gzvcf $VCF --site-quality --out $PREFIX

echo "2/7 Calculando Profundidad media por sitio..."
vcftools --gzvcf $VCF --site-mean-depth --out $PREFIX

echo "3/7 Calculando Datos faltantes por sitio..."
vcftools --gzvcf $VCF --missing-site --out $PREFIX

echo "4/7 Calculando Frecuencias alélicas..."
vcftools --gzvcf $VCF --freq2 --out $PREFIX --max-alleles 2

echo "5/7 Calculando Profundidad por individuo..."
vcftools --gzvcf $VCF --depth --out $PREFIX

echo "6/7 Calculando Datos faltantes por individuo..."
vcftools --gzvcf $VCF --missing-indv --out $PREFIX

echo "7/7 Calculando Heterocigosidad por individuo..."
vcftools --gzvcf $VCF --het --out $PREFIX

echo "¡Todo listo! Revisa la carpeta 'stats_full'"

```
