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

### 2. BayesAss (BA3): Estimando Migración Reciente

[BayesAss](https://doi.org/10.1093/genetics/163.3.1177), específicamente la versión [BA3-SNPs]( https://doi.org/10.1111/2041-210X.13252), es uno de los programas más utilizados para estimar tasas de migración contemporánea. A diferencia de los métodos basados en <b>F<sub>ST</sub></b>, que asumen un equilibrio de largo plazo entre migración y deriva, BayesAss nos da una "fotografía" de lo que ha ocurrido en las últimas 2 a 3 generaciones.

#### 2.1 ¿Cómo funciona y qué información utiliza?

El "sustrato" de BayesAss son los genotipos individuales multicapa. El programa utiliza un algoritmo de Cadenas de Markov Monte Carlo (MCMC) para estimar la probabilidad de que un individuo sea un migrante de primera o segunda generación.

- Identificación de "Extranjeros": BA3 busca combinaciones de alelos que son comunes en una población pero raras en la población donde el individuo fue muestreado. Si un individuo tiene un genotipo que es mucho más probable en la Población B que en la Población A (donde se colectó), el modelo lo identifica como un posible migrante.

- Supuestos clave:
    - Desequilibrio de ligamiento (LD): Asume que los loci son independientes.
    - Frecuencias alélicas: Requiere que las poblaciones tengan ciertas diferencias en sus frecuencias para poder asignar el origen de los individuos.
    - Muestreo: Los resultados son más robustos cuando se han muestreado todas las poblaciones que intercambian migrantes (sistema cerrado).

**Nota Teórica**: A diferencia de muchos métodos de asignación, BayesAss no asume equilibrio de Hardy-Weinberg. Esto lo hace ideal para sistemas reales donde puede haber endogamia o donde el flujo genético reciente ha perturbado las proporciones genotípicas. Lo que sí hace es utilizar la información de los genotipos para estimar simultáneamente las tasas de migración y los coeficientes de inbreeding (F).

#### 2.2 Preparación de los datos

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


#### 2.3 Ejecución de BayesAss

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

#### 2.4 Interpretación de la Matriz de Migración

Al finalizar, BA3 nos entregará una tabla en `hi_chr1_BA3_test.txt` donde las filas son la población de origen y las columnas la de destino.
- La Diagonal: Representa la proporción de individuos que no migraron (auto-reclutamiento). Valores altos (cercanos a 1.0) indican poblaciones aisladas.
- Valores fuera de la diagonal: Es la tasa de inmigración. Por ejemplo, si el valor en la celda [Pob A][Pob B] es 0.15, significa que el 15% de la Población B está compuesta por individuos que llegaron desde la Población A en las últimas generaciones.

#### 2.5 Visualización de Resultados en R

La salida estándar de BayesAss es una tabla de texto con medias y desviaciones estándar que puede resultar difícil de digerir a primera vista (sobre todo si se analizan múltiples poblaciones). Para transformar estos números en una historia biológica clara, utilizaremos un script de visualización que facilita la identificación de patrones de conectividad.

En la carpeta de recursos del taller en GitHub, encontrarán el script Graph_BA3.R.
1. Descarga el script: Pueden abrirlo directamente en RStudio.
2. Librerías: El script utiliza paquetes para manejo de matrices y gráficos circulares (o de flechas). Si es la primera vez que los usan, asegúrense de instalarlos eliminando el comentario # en las primeras líneas del código.

**Nota**: Para este taller, ya hemos pre-cargado los valores de la matriz de migración de *Haematobia irritans* dentro del script. Esto significa que pueden ejecutarlo de inmediato para ver los gráficos, aunque en un análisis real, ustedes cargarían su propio archivo de salida de BA3.

**¿Qué podemos decir de los resultados?**

- Simetría vs. Asimetría: ¿El flujo de individuos entre las poblaciones es bidireccional? Si vemos que una flecha es mucho más gruesa en un sentido que en el otro, estamos ante un potencial sistema de Fuente-Sumidero (*Source-Sink*).
- Auto-reclutamiento: ¿Qué tan grandes son los valores de la diagonal (o los bucles sobre la misma población)? Si son muy altos (ej. > 0.90), la población está funcionando de forma virtualmente aislada.
- Migración Significativa: BayesAss nos entrega un intervalo de confianza. Si el valor de migración es muy bajo (ej. 0.01) y su desviación estándar es grande, es probable que ese flujo sea ruido estadístico y no un evento biológico real.
- Observen el gráfico resultante para las tres poblaciones de la mosca de los cuernos. ¿Existe alguna población que esté actuando como el principal emisor de migrantes hacia las demás?

### 3. EEMS: Modelando el Paisaje Genético

Mientras que BayesAss nos da tasas de migración entre grupos que nosotros definimos de antemano, EEMS (*Estimated Effective Migration Surfaces*) nos permite visualizar cómo varía la migración a través del espacio sin necesidad de asignar individuos a poblaciones a priori.

#### 3.1 ¿Cómo funciona y qué información utiliza?

EEMS utiliza un modelo de "aislamiento por distancia" (IBD) pero lo hace más complejo al añadir una superficie de migración. Imaginemos una red o grilla de nodos cubriendo el mapa donde viven las poblaciones:
- El Sustrato (Matriz de Disimilitud): A diferencia de BA3 que usa genotipos, EEMS utiliza una matriz de distancias genéticas calculada a partir de los SNPs. Mide qué tan diferentes son todos los pares de individuos.
- La Grilla (Demes): El programa coloca a los individuos en los nodos más cercanos de una grilla espacial. Luego, utiliza MCMC para estimar la "resistencia" al movimiento entre esos nodos.
- Barreras y Corredores: * Si dos individuos están geográficamente cerca pero son genéticamente muy distintos, EEMS identifica una barrera (baja migración, color naranja/café).
- Si dos individuos están lejos pero se parecen genéticamente más de lo esperado por la distancia, EEMS identifica un corredor (alta migración, color azul).

#### 3.2 Preparación de los datos para lcWGS

Para EEMS utilizaremos nuestro set de datos de lcWGS (cobertura baja) de las 3 poblaciones. Dado que EEMS se basa en distancias genéticas, los datos de baja cobertura pueden ser ruidosos si no se manejan bien.
- Matriz de Distancia (`hi_chr1_EEMS.diff`): Utilizaremos las verosimilitudes de genotipos (GL) de ANGSD para generar una matriz de distancias genéticas. Esto es mucho más preciso que usar genotipos "duros" de baja calidad, ya que integra la incertidumbre del secuenciamiento.
- Coordenadas Geográficas (`hi_chr1_EEMS.coord`): EEMS requiere un archivo con la latitud y longitud de cada individuo. Cabe mencionar que agregamos difusión a las coordenadas reales.
- El archivo de Mapa (`hi_chr1_EEMS.outer`): Definiremos un polígono que encierra el área de muestreo para decirle al programa dónde debe realizar las inferencias.
- Archivo con los parámetros (`params.ini`): Se indican los parámetros para el análisis.

```bash
datapath = ./hi_chr1_EEMS
mcmcpath = ./hi_chr1_EEMS_output
nIndiv = 30
nSites = 4000
nDemes = 50
diploid = TRUE
numMCMCIter = 10000000
numBurnIter = 3000000
numThinIter = 9999
```

#### 3.3 Instalación y Configuración del Software

Para este taller, el software EEMS (runeems_snps) fue compilado desde el código fuente debido a dependencias específicas del sistema operativo del clúster (Rocky Linux 9).
- Dependencias: Se utilizaron los módulos Eigen/3.3.7 y boost/1.68.0-i.
- Compilación: Se modificó el Makefile original para vincular estáticamente las librerías de Boost (boost_program_options, boost_filesystem) y evitar conflictos de versiones en tiempo de ejecución.
    - Ubicación del Binario: El ejecutable se encuentra centralizado y disponible para todos los usuarios.

#### 3.4 Ejecución de EEMS

Cada estudiante tiene asignada una carpeta de trabajo con los archivos de entrada necesarios (`.diffs`, `.coord`, `.outer`) y un archivo de configuración (`params.ini`).

1. Solicitar recursos a SLURM.
```bash
srun -p labs -n 1 -c 8 --mem-per-cpu=1000 --pty bash
```

2. Preparación del entorno: Antes de correr el software, debemos cargar las librerías necesarias para que el binario pueda "llamar" a las funciones matemáticas de Boost y Eigen:
```bash
module purge
module load Eigen
module load boost/1.68.0-zen4-i
```

3. Ejecución del análisis

No necesitan compilar el programa. Utilizaremos el ejecutable compartido. Pero primero, debemos cambiarnos al directorio de trabajo y llamar al programa usando su ruta absoluta:

```bash
# Entra a tu carpeta de trabajo
cd /home/courses/$USER/Day04/EEMS/

# Ejecuta EEMS apuntando al binario compartido
/home/courses/student21/eems/runeems_snps/src/runeems_snps --params params.ini
```

#### 3.5 Ejecución y Obtención de Resultados

El análisis de EEMS es computacionalmente intensivo y puede tardar varias horas en completar los millones de iteraciones requeridos para una buena convergencia.
1. Interrupción de la prueba: Si lograron iniciar la corrida y vieron que el contador de iteraciones comenzó a avanzar, es porque el software está bien configurado. Ahora, para optimizar el tiempo del taller, detengamos el proceso presionando: `Ctrl + C`.
2. Copia de resultados finales (Pre-calculados): Para que todos puedan trabajar con una corrida que ya alcanzó la convergencia total (10 millones de iteraciones), copiaremos los resultados desde el backup del curso a tu directorio personal:

```bash
cp -r /home/courses/student21/Day04_Backup/EEMS_OK/ \
  /home/courses/$USER/Day04/
```

#### 3.6 Visualización de Resultados en R

La visualización se realizará de forma local en sus computadora para mayor comodidad y fluidez con los gráficos.
1. Descarga de archivos: Descarguemos la carpeta `hi_chr1_EEMS_output` desde el clúster a nuestro computador.
2. Descarguen desde este GitHub el script `Graph_EEMS.R` y colóquenlo en la misma carpeta donde descargaron los resultados.
3. Instalación de librerías en RStudio: Como la librería principal `rEEMSplots` no se encuentra en el repositorio oficial de R (CRAN), debemos instalarla directamente desde el GitHub de su desarrolladora. Al comienzo del script se indican los comandos.
4. Generación de gráficos: Una vez instaladas todas las dependencias indicadas al inicio del script, pueden ejecutarlo. El script generará automáticamente los mapas de:
    - Migración (m): Identificación de barreras y corredores.
    - Diversidad (q): Heterocigosidad a través del paisaje.
    - Diagnósticos: Gráficos de convergencia y ajuste del modelo.

#### 3.7 Detalle de los Resultados

1. Figura: `pilogl01` (Trace plot): Muestra la evolución del log-posterior durante la corrida.
2. Figura: `rdist` (Aislamiento por Distancia):Grafica la disimilitud genética observada frente a la distancia geográfica real (en km).
    - Dissimilarities within sampled demes (α): Este gráfico analiza la diversidad interna de cada localidad.Compara la disimilitud promedio entre individuos de la misma localidad (Observada) contra lo que el modelo estima basándose en el parámetro de diversidad local (q).
        - Si los puntos están cerca de la diagonal, significa que el modelo entendió bien cuánta variación hay "dentro" de cada uno de los 3 grupos de Chile. Si un punto está muy lejos, indicaría que esa población es mucho más (o menos) diversa de lo que el paisaje sugiere.
    - Dissimilarities between pairs of sampled demes (α,β): Este es el gráfico de Aislamiento por Distancia (IBD), pero enfocado en las diferencias entre grupos. En el eje Y tienes la distancia genética neta entre la población A y la B. En el eje X, tienes la predicción del modelo basada en la geografía y las tasas de migración (m). 
    - Dissimilarities between pairs of sampled demes (vs Great circle distance): Compara la disimilitud genética contra la distancia física real en kilómetros (Great circle distance). Sirve para mostrar el decaimiento de la similitud con la distancia. En los resultados, ver que a los 1200 km (distancia aproximada entre los puntos extremos en Chile) la disimilitud es mayor que a los 200 km, valida que el sistema tiene una señal espacial coherente.
3. Figura: `mrates01` (Superficie de Migración): El color Naranja (Centro-Sur) indica una barrera al flujo genético. La migración en esa zona es menor a la media (log(m)<0). Hay algo que dificulta que las moscas del centro de Chile se mezclen libremente con las del sur. El color Celeste (Norte y Extremo Sur) indica corredores o alta conectividad. En estas zonas, la similitud genética es mayor de lo esperado para esa distancia.
4. Figura: `qrates01` (Superficie de Diversidad): Muestra la diversidad genética local (log(q)). Color Celeste, áreas con alta diversidad. Las poblaciones del sur parecen tener una reserva de variación genética mayor. Color Naranja, áreas con baja diversidad o mayor endogamia relativa.