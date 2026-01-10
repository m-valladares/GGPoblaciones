# Filtrado y Diagnóstico de un archivo VCF (RADseq)

Este documento describe paso a paso el **diagnóstico, filtrado y preparación** de un archivo `.vcf.gz` para análisis de **genética de poblaciones**, usando datos RADseq de *Orestias*.

El objetivo no es solo ejecutar comandos, sino **entender qué información tiene el VCF**, **por qué se pierde (o no) información en cada filtro**, y **cómo tomar decisiones informadas** según el tipo de datos.

---

## Conteo inicial de SNPs crudos

Antes de cualquier filtrado, es importante saber con cuántos SNPs estamos partiendo.

```bash
bcftools view -H Orestias_final_variants.vcf.gz | wc -l

Este número corresponde al total de sitios variantes detectados en el llamado inicial, incluyendo muchos sitios de baja calidad o presentes en muy pocos individuos.

Objetivos de los análisis posteriores
1. Diversidad genética

Se calculará:

Heterocigosidad observada y esperada (Ho, He)

Diversidad nucleotídica (π)

Coeficiente de consanguinidad (FIS)

Importante:
Para estos análisis NO se debe aplicar LD pruning, ya que eliminar SNPs ligados puede sesgar la diversidad real.

2. Estructura poblacional

PCA

Admixture

Estos análisis son los “gráficos estrella” en genética de poblaciones.

Importante:
Aquí SÍ es obligatorio aplicar LD pruning, porque estos métodos asumen que los marcadores son independientes.

3. Diferenciación genética

FST

Matrices de distancia

Manhattan plots para detectar regiones altamente diferenciadas

Diagnóstico inicial del VCF con VCFtools

Antes de filtrar, debemos mirar los datos.

Cargar módulos necesarios

