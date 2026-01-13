# ESTRUCTURA GENETICA

## 1. $F_{ST}$ por pares de especies (Ascotan versus Carcote y Lauca versus Chungará):

El $F_{ST}$ mide qué tanta de la variación genética total se debe a las diferencias entre poblaciones. Un valor de 0 indica que son una sola población panmíctica; un valor de 1 indica que están fijadas para alelos distintos.

```bash
# Cálculo para la divergencia antigua (Salares)

vcftools --vcf Orestias_only_SNPs.recode.vcf \
--weir-fst-pop Ascotan.txt \
--weir-fst-pop Carcote.txt \
--out FST_Antigua_Ascotan_Carcote

# Cálculo para la divergencia antigua (Salares)
vcftools --vcf Orestias_only_SNPs.recode.vcf \
--weir-fst-pop Lauca.txt \
--weir-fst-pop Chungara.txt \
--out FST_Reciente_Lauca_Chungara

# EXPLICACIÓN DE LOS PARÁMETROS:
# --weir-fst-pop: Archivo .txt con la lista de individuos de la población A y B.
# --out: Genera un archivo .weir.fst con el valor por sitio y un resumen en el log.
```

### Comparación: Ascotán vs. Carcote (Divergencia Antigua)

**- Weighted $F_{ST}$: 0.673**

**- Interpretación:** Un $F_{ST}$ de 0.67 significa que estas dos poblaciones están operando casi como especies distintas a nivel genómico. Casi no hay intercambio de genes y las frecuencias alélicas están "fijadas" en variantes distintas en cada salar.

**- Conclusión biológica:** El aislamiento en los salares del Altiplano es extremo. A pesar de estar cerca, la barrera (aridez, falta de conexión hídrica) ha sido infranqueable por miles de años.

### Comparación: Lauca vs. Chungará (Divergencia Reciente)

**- Weighted $F_{ST}$: 0.232**

**- Interpretación:** Sigue siendo una diferenciación moderada-alta (típica de poblaciones aisladas), pero es tres veces menor que la de los salares.

**- Conclusión biológica:** Esto refleja que compartieron un ancestro común mucho más recientemente. Es probable que antes de la formación del Lago Chungará (por el colapso del volcán), todo fuera un solo sistema fluyente donde los peces se mezclaban libremente.

### ¿Qué valor mirar? (Mean vs. Weighted)
El Mean $F_{ST}$ es un promedio simple de todos los sitios.
El Weighted $F_{ST}$ pondera los sitios según su varianza y es mucho más robusto frente a diferencias en el tamaño de las muestras.
Siempre reporten el Weighted $F_{ST}$.

---

## 2. Correr el PCA en el Clúster
Utilizaremos el archivo VCF que ya pasó por el filtro de LD Pruning (poda por desequilibrio de ligamiento) para evitar que regiones altamente ligadas sesguen los componentes principales.

```bash
plink2 --vcf Orestias_FINAL_PCA.vcf \
--double-id --allow-extra-chr \
--pca 10 \
--out orestias_pca_results

# --double-id: Copia el nombre de la muestra como ID de familia y de individuo.
# --allow-extra-chr: Permite procesar scaffolds (necesario en organismos no modelo).
# --pca 10: Calcula los primeros 10 componentes principales.
```

Al terminar, verás dos archivos clave en tu carpeta:

`orestias_pca_results.eigenvec`: Es la tabla de coordenadas.

`orestias_pca_results.eigenval`: Son los autovalores que nos dirán cuánta varianza explica cada PC.

---

# 3. ADMIXTURE

3.1. Antes de correr ADMIXTURE, necesitamos transformar los archivos VCF al formato binario de PLINK (`.bed`, `.bim`, `.fam`), que es lo que ADMIXTURE sabe leer.

```bash
ml PLINK/2.00-linux-avx2

plink2 --vcf Orestias_FINAL_PCA.vcf \
      --max-alleles 2 \
      --make-bed \
      --out orestias_admix \
      --allow-extra-chr

```

- `--vcf Orestias_FINAL_PCA.vcf`: Indica el archivo de entrada. En este caso, es el VCF que ya pasó por los filtros de calidad y el pruning (poda) por desequilibrio de ligamiento.

- `--max-alleles 2`: Este es el "filtro de seguridad". Fuerza a PLINK a ignorar cualquier sitio que tenga 3 o más alelos. Como ADMIXTURE solo entiende variaciones entre dos estados (ej. A o T), este parámetro evita el error de "multiallelic variants" que vimos antes.

- `--make-bed`: Es la instrucción para crear el formato binario. Genera tres archivos inseparables:

    - `.bed`: Los genotipos comprimidos (no legibles por humanos).

    - `.bim`: Información de los SNPs (posiciones y alelos).

    - `.fam`: Información de los individuos y familias.

- `--out orestias_admix`: Define el prefijo de los archivos de salida. Todos los archivos resultantes empezarán con este nombre (ej. orestias_admix.bed).

- `--allow-extra-chr`: Es vital para organismos no modelo. PLINK por defecto espera cromosomas humanos (1-22, X, Y). Como el genoma de referencia está en scaffolds con nombres como "Scaffold_123", este parámetro le dice al programa: "Acepta nombres de cromosomas que no sean los estándar".

3.2. Hack para los nombres de Scaffolds
Como ADMIXTURE no acepta nombres de cromosomas con texto (solo números), renombraremos todos los scaffolds a "0" de forma temporal.

A diferencia de PLINK2, ADMIXTURE es muy rígido con los nombres de los cromosomas. Aunque le pusimos `--allow-extra-chr` en PLINK, ADMIXTURE solo acepta números enteros (1, 2, 3...). Al ver nombres como `"Scaffold_1"`, se bloquea y lanza el mensaje: `Invalid chromosome code! Use integers`.

Para solucionar esto sin perder la información de los scaffolds, vamos a engañar un poco al programa cambiando temporalmente los nombres de los scaffolds por números en el archivo `.bim`.

Ejecuten el siguiente comando en la terminal antes de correr el bucle de ADMIXTURE. Lo que haremos será reemplazar la primera columna del archivo `.bim` (donde están los nombres de los scaffolds) por un "0", lo cual ADMIXTURE acepta sin problemas:

```bash
# 1. Crear una copia de seguridad del archivo original por si acaso
cp orestias_admix.bim orestias_admix.bim.bak

# 2. Cambiar los nombres de los scaffolds por '0' en el archivo .bim
awk '{$1=0;print $0}' orestias_admix.bim.bak > orestias_admix.bim

# Nota: No te preocupes por ponerles "0" a todos; ADMIXTURE usará las posiciones de los SNPs para diferenciarlos. Como ya hicimos el pruning, esto no afectará el resultado de la ancestría.
```

3.3. Ejecución del análisis (Bucle de K=2 a K=5).
Correremos múltiples valores de $K$ para encontrar el modelo que mejor explique la estructura de las Orestias.

```bash
# 1. Cargar el módulo
ml ADMIXTURE/1.3.0-x86_64
```

```bash
# 2. Bucle para procesar de K=2 a K=5
for K in 2 3 4 5; do 
  admixture --cv orestias_admix.bed $K -j4 | tee log${K}.out; 
done
```

3.4. Interpretación de Resultados: ¿Cuál es el K óptimo?
El siguiente paso es fundamental: **verificar cuál es el K con menor error**.
La siguiente línea nos permite comparar los errores:

```bash
grep "CV" log*.out
```

**Resultado:**

```bash
log2.out:CV error (K=2): 0.43135
log3.out:CV error (K=3): 0.40059
log4.out:CV error (K=4): 0.29087
log5.out:CV error (K=5): 0.30351
```

Para determinar el número óptimo de poblaciones ancestrales ($K$), utilizamos el procedimiento de **Validación Cruzada (Cross-Validation)** implementado en ADMIXTURE. A diferencia del método de Evanno usado en STRUCTURE, el CV Error identifica el modelo con mayor poder predictivo. En nuestro análisis, el valor mínimo se alcanzó en K=4, indicando que esta es la estructura más probable para las poblaciones de Orestias.

**Interpretación de los resultados (CV Error)**

- El **Cross-Validation (CV) error** nos indica qué valor de $K$ (número de poblaciones ancestrales) explica mejor los datos genómicos.

- **K=2 (0.431)** y **K=3 (0.400)**: Tienen errores altos. Seguramente aquí solo vemos la separación más gruesa (Salares vs. Altiplano).

- **K=4 (0.290)**: ¡Es el ganador! Aquí el error cae drásticamente. Esto significa que el modelo de 4 poblaciones es el que mejor representa la realidad biológica de tus Orestias.

- **K=5 (0.303)**: El error vuelve a subir. Esto indica que intentar forzar una quinta población empieza a introducir "ruido" o sobreajuste (overfitting).

**¿Por qué no usamos el Delta K de Evanno en ADMIXTURE?**
El método de Evanno ($\Delta K$) se basa en la segunda derivada de la función de verosimilitud ($\ln P(D)$). STRUCTURE calcula esta verosimilitud mediante un método llamado MCMC (Cadenas de Markov Monte Carlo), que es muy lento pero genera los datos necesarios para esa estadística.
ADMIXTURE utiliza un método diferente (Máxima Verosimilitud por algoritmos de optimización rápida). Por diseño, ADMIXTURE no genera el valor de "lnP(D)" que Evanno requiere.

**El sustituto: Cross-Validation (CV) Error**
En lugar del Delta K, ADMIXTURE utiliza la Validación Cruzada (CV). Es un método estadístico más robusto y moderno:
El programa oculta una parte de los datos (genotipos) y trata de predecirlos usando el resto.
El valor de $K$ que tenga el menor error es el que mejor predice los datos sin "sobre-ajustarlos".

**¿Qué significa esto?**
Con K=4, es muy probable que los datos estén mostrando estas cuatro unidades genéticas claras:
- Ascotán
- Carcote
- Lauca
- Chungará

---

# Organización de Datos en computador local: Estructura Genética

Crea una nueva carpeta específica para esta fase del análisis y descarga los siguientes archivos específicos del Clúster:

- ($F_{ST}$): `FST_Antigua_Ascotan_Carcote.weir.fst` y `FST_Reciente_Lauca_Chungara.weir.fst`

- Resultados de PCA (PLINK): `orestias_pca_results.eigenvec`, `orestias_pca_results.eigenval`

- Resultados de Admixture: `for_admixture.4.Q` y `orestias_admix.fam`

- Metadatos: Copiar el archivo `metadatos_orestias.csv` a esta carpeta también.

Ahora puedes correr los scripts R: `PCA_Orestias.R`, `FST_Orestias.R` y `Admixture_Orestias.R`

---

# DISCUSIÓN INTEGRADA DE RESULTADOS

Al combinar los tres análisis, podemos inferir parte de la historia evolutiva de estas poblaciones:

1. Coherencia entre PCA y ADMIXTURE
En el PCA, las muestras de Ascotán y Carcote están separadas por una distancia enorme en el PC1. Esto se refleja perfectamente en el ADMIXTURE (K=4), donde cada una de estas poblaciones aparece como un bloque de color sólido y puro (sin barras de mezcla). No hay flujo génico actual entre estos salares.

2. La relación Lauca-Chungará
Mientras que en los salares el $F_{ST}$ es altísimo (0.67), en el Altiplano (Lauca vs Chungará) es mucho menor (0.23). Esto explica por qué en el PCA estas poblaciones están más cerca y por qué, si corriéramos un ADMIXTURE con K=3, probablemente estas dos aparecerían bajo el mismo color. Solo al llegar a K=4 el programa logra identificar las variantes sutiles que las separan.

3. Paisaje Genómico
El FST por sitio muestra una "nube" alta en los salares, pero en el Altiplano (Lauca-Chungará), la base es baja con muy pocos SNPS que llegan a $F_{ST}=1$.
Integración: Esos peaks de $F_{ST}$ podrían ser candidatos a ser genes de adaptación local (río vs lago).

---
