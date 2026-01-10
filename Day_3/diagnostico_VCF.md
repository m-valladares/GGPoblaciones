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

Nota: Si es la primera vez que usas conda y recibes un mensaje indicando que debes inicializarlo, ejecuta conda init, cierra tu sesión y vuelve a entrar. Si ya lo has usado, puedes recargar tu configuración con: source ~/.bashrc y activar de nuevo: conda activate filt_vcf.

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

srun -p labs --pty --mem=2G -n 1 -c 1 --time=03:00:00 /bin/bash

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
4. Verificación del análisis
Ahora que estamos dentro del ambiente filt_vcf, los comandos de conteo deberían funcionar perfectamente, incluso con archivos comprimidos.

```Bash

# Contar el número de SNPs crudos (sin encabezado)
bcftools view -H Orestias_final_variants.vcf.gz | wc -l

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
