# Flujo Genético y Conectividad Poblacional

El flujo genético es la fuerza microevolutiva que mantiene la cohesión de las especies. A diferencia de la deriva genética, que promueve la divergencia, el intercambio de alelos entre poblaciones tiende a homogeneizar las frecuencias alélicas y a aumentar la diversidad genética local.

En este taller, pasaremos de la teoría de los modelos a la práctica con datos genómicos reales, explorando cómo el movimiento de individuos (o gametos) moldea la arquitectura genética de las poblaciones de estudio.

### 1.1 De la Teoría a los Datos Genómicos

En las sesiones teóricas previas, discutimos modelos clásicos como el modelo de islas de Wright y el modelo de *stepping-stone*. Vimos que, bajo ciertas condiciones, podemos estimar el número de migrantes por generación (**N<sub>e</sub>​M**) a partir del estadístico <b>F<sub>ST</sub></b>​. Sin embargo, en la era de la genómica, tenemos la oportunidad de ir más allá de estas simplificaciones:

- Más allá del equilibrio: Los modelos clásicos suelen asumir un equilibrio entre migración y deriva. Con las herramientas actuales, podemos detectar eventos de flujo genético recientes vs. históricos.
- Direccionalidad: No solo nos interesa saber cuánto flujo hay, sino hacia dónde va (fuentes y sumideros).
- El paisaje como barrera: El flujo genético no ocurre en el vacío; está limitado por la geografía, el ambiente y la ecología de la especie.

### 1.2 Una Aproximación Multi-Herramienta

En bioinformática, no existe una herramienta que sea útil en todos los escenarios para inferir el flujo genético. Cada software utiliza diferentes algoritmos y "sustratos" de información (algunos usan frecuencias alélicas, otros genotipos individuales o matrices de disimilitud).

Para este taller, hemos diseñado un flujo de trabajo que integra dos aproximaciones complementarias. El objetivo es que aprendan a contrastar resultados: cuando diferentes métodos con distintas naturalezas de datos coinciden, nuestra hipótesis biológica se robustece.

### 1.3 BayesAss (BA3): Estimando Migración Reciente

[BayesAss](https://doi.org/10.1093/genetics/163.3.1177), específicamente la versión [BA3-SNPs]( https://doi.org/10.1111/2041-210X.13252), es uno de los programas más utilizados para estimar tasas de migración contemporánea. A diferencia de los métodos basados en <b>F<sub>ST</sub></b>, que asumen un equilibrio de largo plazo entre migración y deriva, BayesAss nos da una "fotografía" de lo que ha ocurrido en las últimas 2 a 3 generaciones.

#### 1.3.1 ¿Cómo funciona y qué información utiliza?

El "sustrato" de BayesAss son los genotipos individuales multicapa. El programa utiliza un algoritmo de Cadenas de Markov Monte Carlo (MCMC) para estimar la probabilidad de que un individuo sea un migrante de primera o segunda generación.

- Identificación de "Extranjeros": BA3 busca combinaciones de alelos que son comunes en una población pero raras en la población donde el individuo fue muestreado. Si un individuo tiene un genotipo que es mucho más probable en la Población B que en la Población A (donde se colectó), el modelo lo identifica como un posible migrante.

- Supuestos clave:
    - Desequilibrio de ligamiento (LD): Asume que los loci son independientes.
    - Frecuencias alélicas: Requiere que las poblaciones tengan ciertas diferencias en sus frecuencias para poder asignar el origen de los individuos.
    - Muestreo: Los resultados son más robustos cuando se han muestreado todas las poblaciones que intercambian migrantes (sistema cerrado).

**Nota Teórica**: A diferencia de muchos métodos de asignación, BayesAss no asume equilibrio de Hardy-Weinberg. Esto lo hace ideal para sistemas reales donde puede haber endogamia o donde el flujo genético reciente ha perturbado las proporciones genotípicas. Lo que sí hace es utilizar la información de los genotipos para estimar simultáneamente las tasas de migración y los coeficientes de inbreeding (F).

#### 1.3.2 Preparación de los datos

Primero copiemos los datos que usaremos durante esta sesión
```bash
cp -r /home/courses/student21/Day04 \
  /home/courses/${USER}/
```

BayesAss fue diseñado originalmente para microsatélites o SNPs de representación reducida (RADseq/GBS). Entonces, para este taller, realizamos un procesamiento especial de los datos de *Haematobia irritans*:

- De Probabilidades a Genotipos Duros: BA3 no puede leer archivos BEAGLE o verosimilitudes de ANGSD directamente; requiere genotipos definidos (0/0, 0/1, 1/1). Por ello, en ANGSD utilizamos:
    - `-doPost 2`: Para calcular las probabilidades posteriores de los genotipos usando un prior uniforme.
    - `-doGeno 3`: Para realizar el "Hard Calling" y obtener el genotipo más probable para cada individuo.

- Simulando RADseq (Filtros Estrictos): Para evitar el ruido inherente a la baja cobertura y cumplir con el supuesto de independencia, aplicamos una estrategia de "submuestreo y limpieza":
    - Filtros de Calidad: Solo conservamos sitios con alta probabilidad de ser SNPs verdaderos y alta cobertura.
    - Pruning por cercanía: En lugar de usar todo el primer cromosoma, seleccionamos SNPs espaciados para minimizar el ligamiento (LD).

- Resultado: Terminamos con un set de 4,127 loci de alta confianza, que representan ventanas de información a lo largo del cromosoma, simulando la estructura de un set de datos de representación reducida.


#### 1.3.3 Ejecución de BayesAss

El script de BayesAss requiere que definamos la duración de la cadena MCMC y los parámetros de "salto" (mixing parameters) para las frecuencias alélicas (a), las tasas de migración (m) y el coeficiente de inbreeding (f). A continuación explicamos la sección de parámetros del script sbatch que se encuentra en el directorio de `BA3`.

```bash
# ---- Parámetros ----
NLOCI=4127
ITER=1000000
BURN=100000
SAMP=1000
SEED=12345

DELTA_M=0.35
DELTA_A=0.85
DELTA_F=0.04

# ---- Ejecutar BayesAss ----
${BA3} \
  -F ${INPUT} \
  -l ${NLOCI} \
  -i ${ITER} \
  -b ${BURN} \
  -n ${SAMP} \
  -m ${DELTA_M} \
  -a ${DELTA_A} \
  -f ${DELTA_F} \
  -s ${SEED} \
  -v \
  -t \
  -o ${OUT}
```

Para que BayesAss estime correctamente las tasas de migración, no basta con darle los datos; debemos configurar el algoritmo de Cadenas de Markov Monte Carlo (MCMC). A continuación, explicamos qué hace cada parámetro en nuestro script sbatch:
1. Configuración de la Cadena (MCMC)
- `-i ${ITER}` (1,000,000): Es el número total de iteraciones. El programa explorará el espacio de probabilidades buscando la mejor solución.
- `-b ${BURN}` (100,000): El Burn-in o período de calentamiento. Descartamos las primeras 100,000 iteraciones porque al principio el algoritmo está "adivinando" y sus resultados no son confiables.
- `-n ${SAMP}` (1,000): El intervalo de muestreo (thinning). Para evitar que los datos estén autocorrelacionados, solo guardamos el resultado de cada 1,000 pasos.
- `-s ${SEED}` (12345): La semilla aleatoria. Es vital para la reproducibilidad. Si usas la misma semilla y los mismos datos, obtendrás exactamente el mismo resultado.

2. Los Parámetros de Salto (Delta Δ): Estos son los parámetros más técnicos y críticos de BA3. Controlan el tamaño del "paso" que da el algoritmo en cada iteración:
- `-m DELTA_M` (0.35 - Tasas de migración): Controla cuánto cambian las tasas de migración propuestas en cada paso.
- `-a DELTA_A` (0.85 - Frecuencias alélicas): Controla la variación en las propuestas de frecuencias de alelos.
- `-f DELTA_F` (0.04 - Coeficiente de inbreeding): Controla los cambios en la estimación de la endogamia.

¿Cómo saber si estos valores son correctos? La regla de oro en BayesAss es que las tasas de aceptación (que veremos en el archivo de salida .out) deben estar entre el 20% y el 60%.
    - Si la aceptación es muy alta (ej. 90%), los pasos son muy cortos y el programa no explora bien el espacio.
    - Si es muy baja (ej. 5%), los saltos son demasiado grandes y el algoritmo "se cae" constantemente.

**Nota:** Para el taller, ya hicimos corridas de prueba ajustando estos deltas para asegurar que la cadena converja de forma eficiente con los datos de *Haematobia irritans*.

3. Flags Adicionales
- `-v`: Activa el modo verbose para que podamos ver el progreso en el archivo de log.
- `-t`: Calcula las probabilidades de asignación total, lo que nos permite saber con qué confianza un individuo es asignado a su propia población o como migrante.

Para enviar el trabajo a SLURM pueden usar el comando `sbatch ba3_test.sbatch`. Sin embargo, el análisis es bastante lento y nosotros ya hemos corrido BA3 con los mismos datos (aunque usamos 5 millones de iteraciones). Para revisar los resultados copien los resultados desde `student21`:

```bash
cp -r /home/courses/student21/Day04_Backup/BA3_OK/ \
  /home/courses/$USER/Day04/
```

#### 1.3.4 Interpretación de la Matriz de Migración

Al finalizar, BA3 nos entregará una tabla en `hi_chr1_BA3_test.txt` donde las filas son la población de origen y las columnas la de destino.
- La Diagonal: Representa la proporción de individuos que no migraron (auto-reclutamiento). Valores altos (cercanos a 1.0) indican poblaciones aisladas.
- Valores fuera de la diagonal: Es la tasa de inmigración. Por ejemplo, si el valor en la celda [Pob A][Pob B] es 0.15, significa que el 15% de la Población B está compuesta por individuos que llegaron desde la Población A en las últimas generaciones.

