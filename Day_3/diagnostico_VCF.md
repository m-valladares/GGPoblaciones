# Diagnóstico del VCF posterior al llamado de variantes (RADseq)

Este documento corresponde al **diagnóstico inicial del archivo VCF** generado después del llamado de variantes.  
El objetivo es **entender la calidad y estructura de los datos antes de aplicar cualquier filtrado**, algo fundamental en genética de poblaciones, especialmente con datos de representación reducida (ddRADseq / GBS).

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



