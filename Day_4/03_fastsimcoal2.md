# Taller: Inferencia Demográfica con fastsimcoal2

**Día 4 (PM): Genómica de la Invasión Objetivo:** Modelar la historia demográfica de la invasión de *Rattus rattus* en Santiago, comparandola con Brasil

 ---


## 0. Ingreso al Nodo de Cómputo

Primero, solicitamos recursos interactivos en el clúster.

```bash
srun -p labs --pty --mem=2G -n 1 -c 1 --time=02:00:00 /bin/bash
```

## 1. Configuración del Entorno y Datos

Como estamos trabajando en un clúster compartido, primero debemos conectar nuestra sesión con las herramientas y datos del curso que están alojados en el usuario del instructor (`student23`).

**1. Definir la ubicación de las herramientas (Binarios)**
Esto nos permitirá llamar a los programas sin escribir la ruta completa cada vez.

Agregamos la carpeta de binarios al PATH para que el sistema encuentre el programa principal (`fsc27`).


```bash
# Agregar la carpeta de binarios del curso a nuestro PATH
export PATH=$PATH:/home/courses/student23/Day05/bin_taller

# Verificar que funciona (Buscamos fsc27, que es el motor de simulación)
which fsc27
# Salida esperada: /home/courses/student23/Day05/bin_taller/fsc27
```

2. Crear accesos directos a los Datos Vamos a traer los datos del Día 5 (VCF) y del Día 4 (Backups de fastsimcoal) a tu carpeta usando enlaces simbólicos.

```bash
#### 1. Preparar carpeta:
# Crear estructura de carpetas
mkdir -p ~/Day04/fsc_taller/Input_Gen
cd ~/Day04/fsc_taller/Input_Gen

# Enlace a los Datos Crudos (VCF y Mapas) ubicados en la cuenta del instructor
# Nota: Usamos rutas absolutas para no perdernos
ln -s /home/courses/student23/Day05/Data/santiago.vcf.gz .
ln -s /home/courses/student23/Day05/Data/popmap.txt .

# Verificar que los enlaces funcionan (deben verse en celeste/azul)
ls -l
```

3. Configurar Python e Instalar Librerías:

Cargaremos Miniconda e instalaremos las herramientas necesarias (pandas, numpy, scipy).

Nota: Este paso descarga archivos de internet. Puede tardar 1 o 2 minutos.

```bash

# Limpiar módulos y cargar Miniconda
module purge
module load miniconda3

# Instalar librerías científicas en nuestro usuario
pip install --user pandas numpy scipy

```

## 2. Input para fastsimcoal2

A diferencia de otros programas que leen todas las secuencias (archivos gigantes), fastsimcoal2 resume toda la variabilidad genómica en una tabla estadística compacta: el SFS (Site Frequency Spectrum).

Antes de generar el archivo, debemos entender qué le estamos preguntando a los datos.

### 2.1 Concepto: ¿Folded o Unfolded?

El SFS es un histograma que nos dice cuán frecuentes son las mutaciones en nuestra población. Pero hay dos formas de construirlo y esto define el nombre del archivo:

- **Unfolded (Desplegado):** Sabemos cuál es el estado ancestral (usando un outgroup). Contamos alelos Derivados.
  - Nombre del archivo: _DAFpop0.obs (Derived Allele Frequency).
   - Ventaja: Es mucho más informativo para detectar selección o expansión.

- **Folded (Plegado):** No sabemos cuál es el ancestral. Contamos el alelo Menor (el menos común).
  - Nombre del archivo: _MAFpop0.obs (Minor Allele Frequency).
   - Uso: Cuando no tenemos buena referencia. "Doblamos" el histograma porque no distinguimos p de q.

En este taller: Usaremos SFS Unfolded (DAF), asumiendo que el genoma de referencia indica el estado ancestral. El VCF se construyo utilizando a *Rattus norvergicus* como grupo externo.


### 2.2 Ejecución Práctica: easySFS

Para generar este archivo desde un VCF, usaremos la herramienta easySFS. Esta herramienta resuelve un problema clásico: los Datos Faltantes.

- El Problema de la Proyección: El SFS necesita que todos los sitios tengan el mismo número de muestras. Pero en la vida real, algunos individuos fallan en algunos sitios.
  - Si pedimos 20 individuos, perdemos todos los sitios donde falló 1 solo.
  - easySFS hace una "Proyección a la baja" (Downsampling): Simula que tenemos menos individuos (ej. 15) para maximizar la cantidad de SNPs retenidos.


Para generar el archivo SFS desde un VCF, usaremos la herramienta easySFS. Esta herramienta resuelve el problema de los Datos Faltantes mediante una "proyección a la baja".

1. Filtrar el Mapa de Poblaciones easySFS es estricto. Si el mapa tiene poblaciones que no están en el VCF (como Brasil), fallará.

```bash

# IMPORTANTE: Filtrar el mapa
# easySFS fallará si el mapa tiene poblaciones que no están en el VCF.
# Creamos un mapa solo para Santiago.
grep "SANTIAGO" popmap.txt > popmap_santiago.txt

```

2. Ejecutar el "Preview" de easySFS: Este paso lee el VCF y nos dice: "Si bajas a 10 cromosomas, tienes X SNPs. Si usas todos (14), tienes Y SNPs".

**Nota Técnica:** Agregamos la opción -a (All SNPs) porque estamos usando datos de genoma completo (WGS), no RAD-seq.

```bash
# Ejecutar easySFS en modo 'preview'
# Esto puede tardar unos minutos...
python3 /home/courses/student23/Day05/bin_taller/easySFS/easySFS.py \
-i santiago.vcf.gz \
-p popmap_santiago.txt \
--preview \
-a
```

⏳ TIEMPO DE ESPERA (Simulación) Leer un VCF entero toma memoria y tiempo. En una investigación real, esperarían unos 10-20 minutos.

- Esperen 30 segundos observando la terminal.
- Interrumpan el proceso, presionen Ctrl + C.
- Usaremos un archivo ya procesado donde elegimos proyectar a 14 individuos (maximiza SNPs para Santiago).

Resultado del Preview (Lo que habrían visto):

  SANTIAGO
  (2, 602056)    (3, 903085)    (4, 1098654)    (5, 1241494)
  (6, 1352836)   (7, 1443295)   (8, 1518896)    (9, 1583369)
  (10, 1639178)  (11, 1631609)  (12, 1673357)   (13, 1265671)
  (14, 1290271)

**Interpretación:**

    (12, 1673357): Si usamos 12 "cromosomas" (6 individuos), maximizamos los SNPs (1.67 millones).

    (14, 1290271): Si usamos 14 "cromosomas" (7 individuos, todos), tenemos 1.29 millones.

Decisión: Elegimos 14. Aunque perdemos algunos SNPs, 1.29 millones son más que suficientes y preferimos mantener el tamaño muestreal máximo para mejorar la resolución del SFS.

3. Generación del Archivo Final (Proyección)

Si tuviéramos tiempo infinito, correríamos esto:** (No lo ejecuten, tardaría mucho)**
```bash
#Comando teórico para generar el output
#--proj 14: Elegimos proyectar a 14 cromosomas
#python3 /home/courses/student23/Day05/bin_taller/easySFS/easySFS.py \
#-i santiago.vcf.gz \
#-p popmap_santiago.txt \
#--proj 14 \
#-a
```

4. **Usar el Backup listo** Como no podemos esperar, copiaremos el archivo .obs que ya generamos con esa proyección.

```bash

# A. Configurar el acceso a los datos (Solo si no lo han hecho)
cd ~/Day04
ln -s /home/courses/student23/Day04/Data_fsc .

# B. Ir a la carpeta de trabajo y copiar el archivo
cd ~/Day04/fsc_taller
cp ~/Day04/Data_fsc/Santiago_DAFpop0.obs .

# Verificar
ls -lh Santiago_DAFpop0.obs

```
Este archivo se construyó usando ANGSD, ya que esta basado en mis datos de baja cobertura. ANGSD tiene su propia formar de generar SFS desde los archivos .bam no del VCF

Aca dejo la lista de codigos necesario para que pueden replicar con sus datos:

**NO CORRAN ESTO**

```bash
# ------------ ANGSD SAF (UNFOLDED) ------------
#angsd -P $NT \
#      -bam  "$BAM" \
#      -ref  "$REF" \
#      -anc  "$ANC" \
#      -uniqueOnly 1  -remove_bads 1 \
#      -minMapQ 30    -minQ 20 \
#      -doSaf 1       -GL 2 \
#      -out  "$POP"

```
Igual que antes, realSFS toma ese archivo intermedio (lo que hace esasySFS para un VCF) y optimiza el espectro.

```bash
#realSFS Santiago_PRO_BAM.saf.idx -P 8 > Santiago_BAM_DAFpop0.obs
```

## 2. Definición de modelos demográficos.

Ahora usaremos el archivo de respaldo. Pero antes, lean esto con atención. El 90% de los errores en fastsimcoal ocurren por no respetar estas 3 Reglas:

- El Nombre: El archivo de entrada TIENE que terminar en _DAFpop0.obs (si es una población) o _jointDAFpop1_0.obs (si son dos). Si le cambias el nombre a midato.obs, el programa no lo encontrará.
- Sin Espacios: Nunca uses espacios en los nombres de archivos o carpetas. Usa _ (guiones bajos).
- Coherencia: El prefijo del archivo .obs debe ser IDÉNTICO al nombre del archivo de parámetros .tpl que crearemos después.

Para comunicarse con fastsimcoal2, necesitamos dos archivos que trabajan en equipo. Piensen en esto como construir una casa:

- El archivo .tpl (Template/Plantilla): Es el **PLANO DEL ARQUITECTO**. Define la estructura de la población, cuántos cromosomas tenemos y, lo más importante, qué eventos ocurrieron en el pasado (migraciones, colapsos, separaciones).

- El archivo .est (Estimation/Estimación): Son las **REGLAS DE BÚSQUEDA**. Aquí le decimos al programa: *"No sé exactamente cuántas ratas hay, pero busca un número entre 100 y 100,000"*.

**A. El Archivo .tpl**

El .tpl describe la historia desde el Presente (tiempo 0) hacia el Pasado. Fíjense en la sección crítica: historical event.

La matriz de eventos tiene 7 columnas que controlan el destino de la población:
```plaintext

TIEMPO  SRC   SINK  MIG   SIZE   GROWTH  MIG-MAT
TBOT    0     0     0     RESBOT 0       0`

```

1. TIEMPO (TBOT): ¿Hace cuántas generaciones ocurrió? (Hacia atrás).

2. SRC (Source) / SINK (Destino): Usado para fusiones (Join). Si la pob 0 se une a la 1, ponemos 0 1. (Aquí es 0 0 porque solo tenemos una población).

3. MIG (Migrantes): Proporción de migrantes.

4. SIZE (RESBOT): ¡Clave! Cambio de tamaño. No se pone el número absoluto, se pone la proporción respecto al tamaño actual.

    Ejemplo: Si RESBOT = 0.1, la población se redujo al 10% de su tamaño anterior.

5. GROWTH: Nueva tasa de crecimiento exponencial.

6. MIG-MAT: Cambiar la matriz de migración (si hubiera).

B.**El Archivo .est**

Aquí definimos las variables (como NCUR, TBOT) que pusimos en el .tpl.

1. Distribuciones de Búsqueda: ¿Cómo busca el programa el mejor valor?

 1. unif (Uniforme): "Cualquier valor entre 10 y 100 tiene la misma probabilidad". Útil para tiempos (TBOT).

 2. logunif (Log-Uniforme): "Es igual de probable que sea 10, 100, 1,000 o 10,000". Vital para Tamaños Poblacionales (Ne​).

C.**Parámetros Complejos**: A veces necesitamos calcular valores basados en otros para evitar errores biológicos.

 - Problema: Si le decimos al programa "Busca el inicio del Cuello de Botella (TBOT) entre 10 y 100" y "Busca el fin (TEND) entre 10 y 100", el programa podría probar un TEND menor que TBOT. ¡Eso es viajar al futuro! Imposible.
 - Solución: Definimos la Duración (LBOT) y usamos matemática simple:
    TEND​=TBOT​+LBOT​

Así garantizamos que el fin del evento siempre ocurra después del inicio (en el pasado).

1. Preparar los inputs para los Modelos Vamos a probar dos modelos: uno de Tamaño Constante (CONST) y uno de Cuello de Botella (BOT1).

```bash

cd ~/Day04/fsc_taller

#1 Copiar el archivo listo desde el backup
cp ~/Day04/Data_fsc/Santiago_DAFpop0.obs .

# 2. Crear los "Avatars" para cada modelo
# Modelo Constante: El archivo .tpl se llamará Santiago_CONST.tpl,
# así que el obs debe llamarse Santiago_CONST_DAFpop0.obs
cp Santiago_DAFpop0.obs Santiago_CONST_DAFpop0.obs

# Modelo Botella: El .tpl se llamará Santiago_BOT1.tpl
cp Santiago_DAFpop0.obs Santiago_BOT1_DAFpop0.obs

# Verificar que los nombres sean exactos
ls -lh *.obs

```

Resultado esperado (ls):

Santiago_BOT1_DAFpop0.obs
Santiago_CONST_DAFpop0.obs
Santiago_DAFpop0.obs

**¿Qué hay dentro del archivo?**

Si miran el contenido (cat Santiago_CONST_DAFpop0.obs), verán una sola línea de números: 1 d0_0 d0_1 d0_2 ...
- d0_0: Número de sitios donde el alelo derivado aparece 0 veces (Monormórficos ancestrales)
- d0_1: Número de sitios donde el alelo derivado aparece 1 vez (Singletons).

Modelo A: Población Constante (Nulo)

Este es el modelo más simple. Asumimos que la población de Santiago ha tenido el mismo tamaño desde siempre.

2. Crear archivo TPL (Template - El Plano): Define la estructura. Fíjense en FREQ 1 0 2.5e-8: indica que usamos datos SNP (FREQ) y la tasa de mutación es 2.5×10−8.

```bash

cat <<EOL > Santiago_CONST.tpl
//Number of population samples (demes)
1
//Population effective sizes (number of genes)
NCUR
//Sample sizes
14
//Growth rates : negative growth implies population expansion
0
//Number of migration matrices : 0 implies no migration
0
//historical event: time, source, sink, migrants, new size, new growth rate, migr. matrix
0 historical event
//Number of independent loci [chromosome]
1 0
//Per chromosome: Number of contiguous linkage Block
1
//per Block: data type, num loci, rec. rate and mut rate + optional parameters
FREQ 1 0 2.5e-8
EOL

```

**Population effective sizes (number of genes): NCUR**

- Significado: Es el tamaño poblacional efectivo (Ne​).
- Por qué dice "number of genes": Al igual que con el tamaño de muestra, el programa trabaja en unidades haploides. Si tu población real tiene 5,000 individuos diploides, el valor de NCUR que el programa estimará (o que tú debes ingresar) será 10,000.

**Sample sizes: 14**

- Significado: Es el número de linajes o copias haploides que muestreaste de esa población.
- Si tus datos vienen de 7 individuos diploides, pones 14, esto tiene que coincidir en la proyección que usaste en realSFS. Es el número total de "versiones de alelos" que el coalescente rastreará hacia el pasado.

**Number of independent loci [chromosome]: 1 0**

Aquí es donde el término "chromosome" suele confundir más.

- El primer número (1): Indica cuántos "cromosomas" (o bloques independientes) quieres simular.
- El segundo número (0): Indica si estos cromosomas son estructuralmente iguales (0) o diferentes (1).
 - Al poner 1 0, le estás diciendo: "Simula 1 tipo de estructura genómica". Si estuvieras simulando datos de todo el genoma (RADseq o WGS), normalmente tratas todo como un solo set de parámetros estadísticos.

**Per chromosome: Number of contiguous linkage Block: 1**

- Significado: Dentro de ese "cromosoma" que definiste arriba, ¿cuántos bloques hay que tengan diferentes tasas de recombinación o mutación?
- Al poner 1, dices que todo tu segmento de ADN se comporta bajo las mismas reglas (una sola tasa de mutación y una sola tasa de recombinación).

**per Block: data type, num loci, rec. rate and mut rate + optional parameters**

- Data type	FREQ: Indica que estás usando frecuencias alélicas (SFS). Otros tipos son DNA o MSAT.
- Num loci:	1	En el contexto de SFS, se pone 1 porque el SFS ya es un resumen estadístico de todos tus SNPs.
- Rec. rat:	0	Tasa de recombinación. En SFS de SNPs independientes, se suele dejar en 0 porque se asume que no hay ligamiento entre los sitios.
- Mut. rate:	2.5e-8	La probabilidad de que un alelo cambie por generación. Este valor es clave para escalar los resultados a años o individuos reales y varia según tu modelo de estudio.

3. Crear archivo EST (Estimation - Las Reglas): Aquí definimos los rangos de búsqueda para los parámetros (ej. NCUR entre 100 y 100,000).

```bash
cat <<EOL > Santiago_CONST.est
// Priors and rules file
[PARAMETERS]
//#isInt? #name #dist.#min #max
//output
1 NCUR logunif 100 100000 output

[RULES]

[COMPLEX PARAMETERS]

EOL

```

Modelo B: Cuello de Botella (La Invasión)

Asumimos que la población ancestral (NANC) era grande, luego sufrió una reducción drástica (NBOT) al llegar a Chile hace TBOT generaciones.

4. Crear archivo EST (Bottleneck): Usamos Parámetros Complejos para calcular las proporciones de cambio de tamaño (RESBOT, RESANC), ya que fastsimcoal no usa números absolutos en los eventos históricos, sino ratios.

```bash

cat <<EOL > Santiago_BOT1.est
// Priors and rules file
[PARAMETERS]
//#isInt? #name #dist.#min #max
//output
1 NANC logunif 10000 200000 output
1 NCUR logunif 1000 100000 output
1 NBOT unif 10 1000 output
1 TBOT unif 10 200 output
1 LBOT unif 1 50 output

[RULES]

[COMPLEX PARAMETERS]
// Definimos el tiempo final del cuello de botella (TEND)
0 TEND = TBOT + LBOT
// Calculamos la PROPORCION de reduccion (Target / Actual)
0 RESBOT = NBOT / NCUR
// Calculamos la PROPORCION de recuperacion (Ancestral / Botella)
0 RESANC = NANC / NBOT
EOL

```

5. Crear archivo TPL (Bottleneck): Definimos los eventos históricos hacia el pasado.

- TBOT: Ocurre el cuello de botella (Tamaño se reduce a RESBOT).

- TEND: Termina el cuello de botella (Tamaño se recupera a RESANC).

```bash

cat <<EOL > Santiago_BOT1.tpl
//Number of population samples (demes)
1
//Population effective sizes (number of genes)
NCUR
//Sample sizes
14
//Growth rates
0
//Number of migration matrices
0
//historical event: time, source, sink, migrants, new size, new growth rate, migr. matrix
2 historical event
TBOT 0 0 0 RESBOT 0 0
TEND 0 0 0 RESANC 0 0
//Number of independent loci [chromosome]
1 0
//Per chromosome: Number of contiguous linkage Block
1
//per Block: data type, num loci, rec. rate and mut rate + optional parameters
FREQ 1 0 2.5e-8
EOL

```

**Ejecución de los Modelos**

Correremos una simulación corta (100 iteraciones).

```bash
# Correr Modelo Constante
/home/courses/student23/Day05/bin_taller/fsc27 -t Santiago_CONST.tpl -e Santiago_CONST.est -n 100 -M -L 40 -d -q -c 1

# Correr Modelo Botella
/home/courses/student23/Day05/bin_taller/fsc27 -t Santiago_BOT1.tpl -e Santiago_BOT1.est -n 100 -M -L 40 -d -q -c 1

```

**Inspección Rápida de Resultados**

Antes de ver los resultados finales, miremos qué generó el programa en nuestra breve corrida de prueba. fastsimcoal2 crea una carpeta por cada ejecución.

1. Revisar el Modelo Constante (Nulo)

El archivo más importante es el .bestlhoods. Este contiene los mejores parámetros encontrados y qué tan bien se ajustan al modelo (Likelihood).

```bash
# Entrar a la carpeta o leer desde fuera
cat Santiago_CONST/Santiago_CONST.bestlhoods
```

NCUR          MaxEstLhood      MaxObsLhood
79851         -68855582.174    -37059578.986

Interpretación:

- NCUR: Estima que hay unas ~40,000 ratas (o el número que les haya dado dividido en 2 por ser diploides).

- MaxEstLhood (-68.8 millones): Este es el puntaje del modelo. Mientras más cerca de Cero (o menos negativo), mejor.

2. Revisar el Modelo Cuello de Botella (Invasión)

Ahora miremos el modelo que incluye el evento de colonización.
```bash
cat Santiago_BOT1/Santiago_BOT1.bestlhoods
```

NANC    NCUR   NBOT   TBOT   LBOT ...  MaxEstLhood
254241  9773   574    73     5    ...  -66409468.624

Comparemos los valores de MaxEstLhood (Log-Likelihood):

- Modelo Constante: -68,855,582
- Modelo Botella: -66,409,468

El valor del Modelo "Botella" es "menos negativo" (mayor) que el Constante. Incluso con una simulación corta

*Nota sobre los parámetros: Fíjense en NBOT (aprox 500) vs NCUR (aprox 10,000). El modelo detecta que la población pasó de ser muy pequeña a crecer explosivamente.*

## 3. Análisis Comparativo: Resultados (Santiago vs Brasil)

Para este taller, accederemos a la carpeta de Resultados Consolidados generados en el clúster Rosalind, donde compararemos Santiago contra otra población con historia contrastante, Brasil.


1. Cargar Resultados

```bash
cd ~/Day04/fsc_taller
# Copiar resultados consolidados
cp -r ~/Day04/Data_fsc/FSC_Results_Comp .
cd FSC_Results_Comp
ls -F
```

2. Nota Técnica: ¿Por qué mis datos tienen decimales? Si miran el archivo .obs de Santiago:
```bash
head -n 3 Santiago_FOUNDER_EXP/Santiago_FOUNDER_EXP_DAFpop0.obs
```

Verán números como 377476372.98.

- easySFS (Taller): Usa Hard Calling (Si/No). Entrega números Enteros.

- ANGSD (Pro): Usa Probabilistic Calling. Suma la probabilidad de genotipo de cada individuo. Entrega números Decimales.

Los decimales son más precisos para baja cobertura.


3. Selección del Mejor Modelo Utilizando el criterio de AIC (que premia el ajuste y castiga la complejidad), los ganadores fueron:

- Brasil: Modelo 3Epoch. (Población antigua, estable y gigante ~Ne​≈150,000).

- Santiago: Modelo FOUNDER_EXP. (Efecto fundador severo seguido de expansión explosiva).

## 4. Visualización Gráfica en R 

Ver tablas de números es difícil y poco intuitivo. Vamos a usar R para dibujar la historia evolutiva que *fastsimcoal2* reconstruyó, generando gráficos listos para publicación.

Utilizaremos el script *plot_best_blocks_gg.R*, diseñado para leer los parámetros demográficos y dibujar los cambios de tamaño poblacional en el tiempo.


1. Preparar la "Tabla de Instrucciones"

El script de R necesita saber exactamente qué modelos graficar y dónde buscarlos. Crearemos un archivo CSV donde la columna model debe coincidir exactamente con el nombre de la carpeta de resultados.

```bash

cd ~/Day04/fsc_taller

# Crear el archivo resumen para R
# Formato: NombrePoblacion, NombreModelo, NombreCarpeta
cat <<EOL > best_model_per_pop.csv
pop,best_model,model
Santiago,FOUNDER_EXP,Santiago_FOUNDER_EXP
Brasil,3Epoch,Brasil_3Epoch
EOL

# Verificar que se creó
cat best_model_per_pop.csv
```
2. Configurar R y Librerías

Como el R del clúster es básico, usaremos una versión específica y conectaremos nuestra sesión a una biblioteca compartida donde ya se instaló las herramientas de graficado (ggplot2, dplyr).

```bash

# A. Cargar R (Versión específica 4.3.0 con compiladores Intel)
module load intel-compilers/2022.0.1 impi/2021.5.0 R/4.3.0

# B. Configurar Librerías Compartidas
# Le decimos a R: "Busca los paquetes en la carpeta del curso"
export R_LIBS=/home/courses/student23/Day05/bin_taller/R_libs_4.3

# Verificar que Rscript está listo
Rscript --version
```

3. Ejecutar el Script de Visualización

Ahora lanzamos el script. Este leerá el CSV, buscará los archivos .bestlhoods dentro de FSC_Results_Comp y generará los gráficos.

- Argumento 1: best_model_per_pop.csv (Nuestra tabla).
- Argumento 2: 0.5 (Tiempo de generación: 2 generaciones por año).
- Argumento 3: schematics_pub (Carpeta de salida).

```bash
# Ejecutar script
Rscript /home/courses/student23/Day05/bin_taller/scripts_R/plot_best_blocks_gg.R \
best_model_per_pop.csv 0.5 schematics_pub
```

4. Interpretar los Resultados

Si todo salió bien, verán el mensaje Graficado exitosamente. Abran la carpeta schematics_pub en su navegador de archivos y busquen los PDF o PNG.

Lo que deben observar:

- Brasil (Brasil_3Epoch_pub.pdf/.png):
  - Verán bloques anchos y profundos en el tiempo.
  - Esto representa una población Antigua y Estable (Ne​≈150,000).

- Santiago (Santiago_FOUNDER_EXP_pub.pdf): *
  - Fíjense en la forma de "Embudo" o trapecio invertido cerca del presente (Time = 0).
  - El Cuello: El punto más angosto indica el Efecto Fundador (pocas ratas llegaron).
  - La Base Ancha: La apertura hacia el presente indica la Expansión Explosiva.

