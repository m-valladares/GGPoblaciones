
# Vamos a hacer un "Filtrado Secuencial", para ir limpiando el set de datos (`.vcf`) paso a paso

## Paso 1: Filtro de Calidad (El "Ruido")
Eliminamos los sitios donde la máquina no está segura de las bases llamadas.

```bash
vcftools --gzvcf Orestias_final_variants.vcf.gz --minQ 30 --recode --out step1_qual
```

**¿Cuántos SNPs eran simplemente mala lectura?**

`
After filtering, kept 156592 out of a possible 260377 Sites
`

## Paso 2: Filtro de Datos Faltantes (El "Missingness")
Este es el que más "duele" en RADseq. Eliminamos sitios que no están en al menos el 50% de los individuos.

```bash
vcftools --vcf step1_qual.recode.vcf --max-missing 0.5 --recode --out step2_missing
```

**¿Cuántos SNPs perdimos por no estar compartidos entre poblaciones?**

`
After filtering, kept 31124 out of a possible 156592 Sites
`

## Paso 3: Filtro de Profundidad (Outliers/Parálogos)
Eliminamos lo que tiene muy poca cobertura y lo que tiene demasiada (posibles duplicaciones).

```bash
vcftools --vcf step2_missing.recode.vcf --min-meanDP 2 --max-meanDP 50 --recode --out step3_depth
```

**Resultado**

`
After filtering, kept 30303 out of a possible 31124 Sites
`

## Paso 4: Filtro de Alelos Menores (MAF)
Eliminamos errores de secuenciación que parecen SNPs pero solo aparecen en un individuo (singletons).

```bash
vcftools --vcf step3_depth.recode.vcf --maf 0.05 --recode --out Orestias_final_filtered
```

**Resultado:**
`
After filtering, kept 14277 out of a possible 30303 Sites
`

El filtro MAF (Minor Allele Frequency) controla qué tan común debe ser una variante para que la consideremos "real" y útil para el análisis.

**1. ¿Qué es técnicamente?**
En cada posición del genoma donde hay un SNP, tenemos un alelo mayoritario (el más frecuente) y uno minoritario. El MAF es la frecuencia del alelo menos común.
Si pones `--maf 0.05`, le estás diciendo a VCFtools: "Solo quédate con los SNPs donde el alelo raro aparezca en al menos el 5% del total de alelos de la población".
En nuestro caso, con 95 individuos (que son 190 alelos, porque cada individuo es diploide), un MAF de 0.05 significa que el SNP debe aparecer al menos en 9 o 10 alelos (aprox. 5 individuos heterocigotos).

**2. ¿Por qué elimina errores de secuenciación (Singletons)?**
A veces, la máquina de secuenciación comete un error en una sola base para un solo individuo.
Si no filtramos por MAF, el software de Variant Calling verá ese error y dirá: "¡Mira, encontré un SNP nuevo!".
Pero ese SNP solo existe en ese individuo, en esa lectura. Eso se llama **Singleton**.
Los singletons suelen ser ruido técnico. Al exigir un 5% de frecuencia, te aseguras de que el SNP sea una variante biológica real que ha sido heredada y compartida por un grupo de individuos, y no un error aleatorio de la máquina.

**3. ¿Por qué es vital para los análisis de estructuración genética?**
**- Para el PCA:** Los SNPs que solo tiene un individuo (MAF muy bajo) no ayudan a agrupar poblaciones; al contrario, agregan "ruido" que puede separar a un individuo del resto de su grupo sin una razón biológica real.
**- Para modelos estadísticos:** Muchos modelos de genética de poblaciones asumen que las variantes están en equilibrio. Los SNPs extremadamente raros pueden sesgar los cálculos de FST y diversidad.

*Nota:* A veces, en conservación, los SNPs raros son importantes. Pero para un análisis de estructura poblacional y filogeografía como el de este set de datos, lo estándar es usar un MAF entre 0.01 y 0.05.

**Si usamos un MAF de 0.05, estamos limpiando el dataset para quedarnos con la "señal clara" de la historia de la población, eliminando los "susurros" que podrían ser solo errores de la máquina.**

## Paso 5: Remover indels

```bash
vcftools --vcf Orestias_final_filtered.recode.vcf --remove-indels --recode --out Orestias_only_SNPs
```

**Resultado:**

`
After filtering, kept 12712 out of a possible 14277 Sites
`

**Entonces ya tenemos listo nuestro set de datos para realizar cálculos de diversidad genética (He, Ho, pi, FIS)**
Para calcular la diversidad genética, queremos ver todos los SNPs reales. El ligamiento no es un problema aquí; de hecho, eliminar SNPs por LD podría sesgar los cálculos de heterocigosidad o riqueza alélica, ya que estarías quitando variantes biológicas reales de la muestra.

## Paso 6: LD prunning

**Para Estructura (PCA y Admixture)**
Requiere LD Pruning. 
Razón: Necesitamos SNPs independientes. Si dejamos SNPs ligados, el PCA mostrará agrupamientos artificiales basados en bloques de herencia y no en la historia de la población.

**1. Cargar PLINK 2**
```bash
ml PLINK/2.00-linux-avx2
```

PLINK2 no puede trabajar si hay variantes que se llaman igual. En muchos archivos VCF generados con herramientas automáticas, la columna "ID" aparece como un punto (.) para todos los SNPs. PLINK necesita que cada uno tenga un nombre único para poder decirte cuáles debe "podar".

Para solucionarlo, debemos usar el comando `--set-all-var-ids` en el primer paso también.

Los dos pasos definitivos corregidos:

**Paso 1:** Identificar SNPs independientes (creando IDs únicos en el vuelo)

```Bash

plink2 --vcf Orestias_only_SNPs.recode.vcf \
--double-id --allow-extra-chr \
--set-all-var-ids @:#:\$r:\$a \
--indep-pairwise 50 5 0.2 \
--out orestias_pruning

```


- `50 5 0.2` significa: Mira ventanas de 50 SNPs, muévete de a 5, y si dos SNPs tienen un r^2 > 0.2 (están muy ligados), elimina uno.

- `--extract`: Buscará los 2,357 nombres exactos en la lista.

- `--recode vcf`: Le ordena a PLINK que el resultado sea un archivo VCF (de lo contrario, crearía archivos binarios .pgen).


¿Qué cambió? Agregamos `--set-all-var-ids @:#:\$r:\$a`. Esto le pone a cada SNP un nombre único basado en su Cromosoma:Posición:Referencia:Alternativo. Ahora PLINK ya no se quejará de IDs duplicados.

**Paso 2:** Generar el VCF final filtrado

```Bash

plink2 --vcf Orestias_only_SNPs.recode.vcf \
--double-id --allow-extra-chr \
--set-all-var-ids @:#:\$r:\$a \
--extract orestias_pruning.prune.in \
--export vcf \
--out Orestias_FINAL_PCA
```
 
¿Por qué es importante el formato @:#:$r:$a?
El archivo `.prune.in` después de correr el Paso 1, verá algo como esto:
`Scaffold_1:1045:A:G Scaffold_1:2130:C:T`

Sin esos nombres únicos, PLINK no tiene forma de hacer la lista de los SNPs que "pasan el examen".


**Resultado:**

`
2357 variants remaining after main filters.
`

**Resultado del filtro LD Prunning**

Independencia Estadística: Los 10,000 que eliminaste no se fueron porque fueran "malos", sino porque eran redundantes 


```bash
cp -r \
  /home/courses/student22/Day03/Results/ \
  /home/courses/${USER}/Day03/Resultados_Estudiante
```
