# Inferencia Demográfica

En esta etapa del curso, nos enfocaremos en la historia temporal de las poblaciones. El objetivo de la inferencia demográfica es reconstruir los cambios en el Tamaño Efectivo Poblacional (**N<sub>e</sub>​**) a lo largo del tiempo, permitiéndonos identificar eventos históricos como cuellos de botella, expansiones poblacionales o declives causados por cambios ambientales o antrópicos.

Para obtener una visión robusta y contrastada, utilizaremos dos aproximaciones de naturaleza distinta:
1. [**Stairway Plot 2**](https://doi.org/10.1186/s13059-020-02196-9) (Basado en el SFS): Este método utiliza la *Site Frequency Spectrum* (SFS) o Espectro de Frecuencia de Sitios.
    - Naturaleza: Es un método no paramétrico que no requiere una secuencia de referencia de alta calidad, lo que lo hace ideal para datos de genómica de poblaciones de baja cobertura.
    - Fortaleza: Es particularmente potente para detectar cambios demográficos en el pasado profundo (hace miles o decenas de miles de años).
    - Entrada: Utilizaremos el archivo SFS generado previamente con ANGSD.

2. [**GONE**](https://doi.org/10.1093/molbev/msaa169) (Basado en Desequilibrio de Ligamiento): Este método estima el N<sub>e</sub>​ reciente utilizando el Desequilibrio de Ligamiento (Linkage Disequilibrium, LD).
    - Naturaleza: Se basa en cómo se rompen las combinaciones de alelos a través de las generaciones debido a la recombinación.
    - Fortaleza: Es extremadamente sensible y preciso para la historia reciente (desde hace unas pocas generaciones hasta hace unos pocos cientos de años). Es ideal para detectar impactos humanos recientes o cambios climáticos post-glaciares inmediatos.
    - Entrada: Utilizaremos archivos en formato PLINK (.ped/.map).

### 1.1 ¿Por qué usar ambos?

La demografía es compleja y ningún software puede capturar toda la historia por sí solo. Al combinar Stairway Plot 2 y GONE, aplicamos un enfoque de "multimensajero":
- El flujo genético es la fuerza microevolutiva que mantiene la cohesión de las especies. A diferencia de la deriva genética, que promueve la divergencia, el intercambio de alelos entre poblaciones tiende a homogeneizar las frecuencias alélicas y a aumentar la diversidad genética local.

En este taller, pasaremos de la teoría de los modelos a la práctica con datos genómicos reales, explorando cómo el movimiento de individuos (o gametos) moldea la arquitectura genética de las poblaciones de estudio.

### 2. Eventos demográficos antiguos

Stairway Plot 2 es una herramienta de inferencia demográfica no paramétrica que nos permite estimar las variaciones del tamaño efectivo poblacional (N<sub>e</sub>) a lo largo del tiempo. A diferencia de otros métodos que asumen un modelo predefinido (como un cuello de botella específico), Stairway Plot "deja que los datos hablen", ajustando una serie de pasos (como una escalera) para representar la historia demográfica.

### 2.1 ¿Cómo funciona y qué información utiliza?

El "sustrato" de esta herramienta es el SFS (Site Frequency Spectrum). El SFS es un resumen de cómo se distribuyen las frecuencias de las variantes genéticas en nuestra muestra.
- La señal en los datos: Las variantes raras (presentes en un solo individuo) suelen ser recientes y nos informan sobre la historia más cercana, mientras que las variantes comunes son más antiguas. Stairway Plot analiza la forma del SFS para deducir si la población ha crecido (acumulando muchas variantes raras) o se ha contraído (perdiendo variantes raras por deriva).
- Resiliencia a la baja cobertura: Al basarse en el SFS calculado desde verosimilitudes de genotipos (como las que generamos en ANGSD), es una herramienta extremadamente robusta para datos lcWGS (~6x como los de nuestra mosca), donde el llamado de genotipos individuales sería poco confiable.
- Sin necesidad de Outgroup: Utilizaremos un Folded SFS (SFS plegado), lo que significa que no necesitamos saber cuál es el alelo ancestral para realizar la inferencia.

### 2.2 Preparación de los datos y el Blueprint

Para esta sesión, utilizaremos el SFS global calculado para el Cromosoma NC_134397.1 de *Haematobia irritans*. Para evaluar eventos demográficos en "toda la especie", analizaremos la información genómica de todos los individuos disponibles (3 localidades, 10 individuos por localidad). El SFS global fue construido usando ANGSD para el llamado de variantes sobre el primer cromosoma de *H. irritans*, para esto es necesario incluir el argumento `-doSaf 1` (*site allele frequency likelihood*) durante el variant calling. Y luego, estimando el (multi) SFS usando la opción `realSFS`.

Stairway Plot requiere un archivo de configuración llamado **blueprint** que contiene tanto los datos genéticos como los parámetros biológicos de la especie.

Parámetros biológicos clave: Para convertir los resultados de unidades genéticas a tiempo real y número de individuos, debemos definir:
- L (Longitud efectiva): El número total de sitios analizados (sitios polimórficos + monomórficos). En nuestro case es el largo total del cromosoma.
- μ (Tasa de mutación): Usaremos 2.8×10−9 (referencia para dípteros).
- Tiempo de generación: Para la mosca de los cuernos, estimamos ~12 generaciones por año (0.08 años/generación).

### 2.2 Ejecución de Stairway Plot 2

El flujo de trabajo consiste en tres pasos: generar los scripts de ejecución (esto fue hecho previamente por nosotros), correr las estimaciones (incluyendo bootstrapping para intervalos de confianza) y visualizar los resultados.

Cada estudiante tiene asignada una carpeta de trabajo con los archivos de entrada necesarios y se encuentra en:

```bash
cd /home/courses/$USER/Day04/StairwayPlot/stairway_plot_v2.1.3
ls
```

Para realizar el análisis, seguiremos estos pasos

1. Si es que no están en un nodo de cómputo, tendrán que solicitar recursos a SLURM.
```bash
srun -p labs -n 1 -c 8 --mem-per-cpu=1000 --pty bash
```

**Nota:** guarden el número de este *job* porque será necesario para más adelante cancelar el trabajo.

2. Preparación del entorno: Antes de correr el software, debemos cargar las librerías necesarias para que el binario pueda "llamar" a las funciones matemáticas de Boost y Eigen:
```bash
module purge
ml Java/17.0.4
```

Luego, mediante el siguiente comando, el programa automáticamente creará el script bash que será necesario para correr el análisis:
```bash
java -cp stairway_plot_es Stairbuilder hirritans_fold.blueprint
```

Si revisamos nuevamente el contenido de la carpeta con `ls`, veremos que ahora tenemos un nuevo directorio llamado `hirritans-global_fold` donde se guardarán los resultados, y un objeto llamado `hirritans_fold.blueprint.sh` que ahora ejecutaremos para correr el análisis.

```bash
bash hirritans_fold.blueprint.sh
```

Stairway Plot realiza cientos de iteraciones (bootstraps) para calcular los intervalos de confianza. En el taller, utilizaremos `n_boots=200` para asegurar que nuestra curva de N<sub>e</sub> sea estadísticamente sólida, aunque en un estudio real este valor podría ser mucho mayor.

Para entender qué está pasando en la "caja negra" de Stairway Plot 2, hay que entender que el programa no busca una única solución, sino que intenta encontrar un consenso mediante muchas piezas.
1. ¿Qué son las `nrand`?: se refiere a los puntos de ruptura (break points) o "escalones" que el programa puede usar para modelar la historia.
- Por qué son 4 valores: En el blueprint pusimos nrand: 7 15 22 28. Esto significa que Stairway Plot realizará el análisis cuatro veces por separado (o en cuatro conjuntos de hilos).
    - Primero intentará ajustar la historia usando solo 7 escalones (un modelo simple).
    - Luego con 15, luego con 22 y finalmente con 28 escalones (un modelo muy complejo).
    - La lógica: Al final, el programa promedia los resultados de estas 4 configuraciones. Esto evita el sobreajuste (overfitting): si solo usáramos 28, la curva sería demasiado ruidosa; si solo dejamos en 7, sería demasiado plana. Al usar varios valores, el resultado final es una curva suavizada y más realista.

2. ¿Qué es el proceso `addTheta`?: 
- En genética de poblaciones, θ (Theta) se define como θ=4Ne​μ.
    - Como la tasa de mutación (μ) suele ser constante, θ es un reflejo directo del tamaño efectivo (Ne​).
    - El paso addTheta: Es cuando el programa toma una de las sub-estimaciones (ya sea de un bootstrap o de una configuración `nrand`) y calcula el valor de Ne​ para un punto específico en el tiempo.
    - Básicamente, "añadir un Theta" es como poner un ladrillo en la construcción de la escalera demográfica.

### 2.3 Ejecución y Gestión de Tiempos

Debido a que Stairway Plot 2 realiza cientos de evaluaciones de máxima verosimilitud (combinando los bootstraps con las diferentes configuraciones de `nrand`), el análisis completo es computacionalmente intensivo y puede tardar varias horas en completarse, dependiendo de la carga del clúster.

En un escenario real, dejaríamos que el trabajo terminara en el clúster. Sin embargo, para fines de este taller, lanzamos el proceso para entender la mecánica y luego lo cancelaremos para trabajar con resultados pre-calculados.

Si necesitan detener el proceso, deben hacerlo desde una terminal distinta a la que está ejecutando el programa. Para identificar el Job ID (si no lo anotaron), pueden consultarlo con:

```bash
# Cambien XX por su número de cuenta
squeue -p labs -u studentXX

# Luego, pueden cancelar el trabajo usando
scancel XXXXX
```

Para poder proceder con la interpretación biológica, copiaremos una corrida completa que hemos preparado previamente:

```bash
cp -r /home/courses/student21/Day04_Backup/StairwayPlot_OK/* \
  /home/courses/${USER}/Day04/StairwayPlot_OK/
```

### 2.4 Visualización de la "Escalera" en R

Una vez terminada la fase de cómputo en el clúster, el archivo más importante es el que tiene la extensión `.final.summary`. Este archivo contiene la mediana y los intervalos de confianza del N<sub>e</sub> escalados por el tiempo.

Flujo de trabajo local:
- Descarga de datos: Utilizando Visual Studio Code (o mediante la terminal), descarguen la carpeta StairwayPlot_OK completa a sus computadores.
- Script de Visualización: Descarga desde este repositorio el script `Graph_StairwayPlot.R` y colócalo dentro de la misma carpeta.
- Generación del Gráfico: Abre el script en RStudio. El código leerá el archivo de resumen y transformará los ciclos de Theta y tiempo genético en una curva demográfica de fácil interpretación.

**Nota Técnica:** El script utiliza la tasa de mutación (μ) y el tiempo de generación que definimos en el blueprint para convertir el eje X a "Años antes del presente" y el eje Y a "Tamaño Efectivo Poblacional (Ne​)".


### 3. Eventos demográficos recientes

Para que GONE pueda estimar el Desequilibrio de Ligamiento (LD), no basta con conocer las frecuencias alélicas globales; necesitamos conocer la configuración de alelos en cada individuo (genotipos).

Aunque trabajamos con datos de baja cobertura (lcWGS), utilizamos ANGSD para realizar un "llamado de genotipos" basado en un enfoque bayesiano. A continuación, explicamos los parámetros críticos que nos permitieron pasar de probabilidades a los archivos que GONE puede leer:

### 3.1 Parámetros de Generación de Genotipos en ANGSD

1. `-doPost 1`: Este parámetro indica a ANGSD que calcule la Probabilidad Posterior de cada genotipo posible (homocigoto dominante, heterocigoto, homocigoto recesivo).
    - ¿Por qué es importante? En lugar de adivinar el genotipo basándose solo en las lecturas (que en lcWGS son pocas), este comando usa las frecuencias alélicas de la población como "información previa" (prior) para asignar una probabilidad más robusta a cada genotipo mediante el teorema de Bayes.

2. `-doGeno 4`: Este comando le pide a ANGSD que escriba o "llame" los genotipos basándose en las probabilidades calculadas anteriormente.
    - El valor 4: Indica el formato de salida. Específicamente, genera un archivo donde los genotipos se representan en un formato compatible con PLINK que tendremos que usar más adelante.

3. `-doBcf 1`: Este parámetro ordena la creación de un archivo en formato VCF (Variant Call Format).
    - Utilidad: Este archivo VCF es el puente que nos permite usar herramientas externas como bcftools para filtrar o PLINK para convertir los datos al formato final de GONE.

### 3.2 Filtros y formato

Dado que el genoma de *Haematobia* es extenso y el análisis de Desequilibrio de Ligamiento (LD) es computacionalmente demandante, realizamos un paso de submuestreo y conversión de formatos para asegurar que el ejercicio sea fluido.

1. Filtrado de Variantes con bcftools: En lugar de procesar millones de SNPs, seleccionamos únicamente los primeros 15,000 sitios del archivo VCF original.
    - Utilizamos bcftools por su eficiencia para manejar archivos comprimidos:
        - ¿Por qué 15,000?: Este volumen de datos es suficiente para capturar la señal demográfica del cromosoma seleccionado sin saturar la memoria RAM de los equipos, permitiendo que el software GONE termine el análisis en pocos minutos.
        - Integridad de datos: Al extraer el bloque inicial (incluyendo el header), mantenemos la relación espacial de los SNPs, lo cual es fundamental para calcular el LD decaído en función de la distancia.

2. Conversión a Formato PLINK con PLINK2: El software GONE no lee archivos VCF directamente; requiere el formato clásico de PLINK (archivos .ped y .map). Para esta transformación utilizamos PLINK2:
    - Archivo `.map` (Mapa genético): Contiene la información de las variantes (cromosoma, ID del SNP y posición física en pares de bases). Es el archivo que le dice a GONE "dónde" está cada marcador.
    - Archivo `.ped`: Contiene la información de los individuos y sus respectivos genotipos para cada uno de los 15,000 SNPs.

3. Normalización Final: Para garantizar la compatibilidad total con los binarios de GONE (programados en Fortran/C++), aplicamos un script de limpieza para:
    - Renombrar los cromosomas a valores numéricos simples.
    - Renombrar los SNPs a un formato correlativo (SNP1, SNP2, ...).
    - Asegurar que los nombres de los individuos no contengan rutas de archivos o caracteres especiales.

### 3.3 Ejecución de GONE y Análisis Demográfico

GONE es un software potente para estimar la historia del tamaño efectivo poblacional (N<sub>e</sub>) a partir de datos de Desequilibrio de Ligamiento (LD). El análisis es "simple" y se ejecuta usando un script que se descarga del [GitHub](https://github.com/esrud/GONE?tab=readme-ov-file) del equipo desarrollador del algoritmo.

1. Configuración de Parámetros: El comportamiento de GONE se controla a través del archivo `INPUT_PARAMETERS_FILE`. Para este ejercicio, utilizaremos los valores por defecto, los cuales están optimizados para manejar datos de genotipos de fase desconocida y una tasa de recombinación estándar.

2. Permisos de Ejecución (`chmod`): Antes de correr el software, debemos asegurarnos de que el sistema operativo del clúster tenga permiso para ejecutar los scripts y los binarios. Para ello usamos el comando `chmod` (abreviatura de Change Mode), que se utiliza para cambiar los permisos de acceso de archivos y directorios. En la instrucción que usaremos, el flag `+x` otorga permisos de ejecución, permitiendo que los scripts se activen como programas.

```bash
# Dar permiso al script principal
chmod +x script_GONE.sh

# Dar permiso a todos los binarios internos necesarios
chmod +x PROGRAMMES/*
```
Como el cálculo de LD es intensivo, no debemos ejecutarlo en el nodo de acceso (login node). Pediremos una sesión interactiva en un nodo de cómputo con el  comando que hemos usado durante el curso:

```bash
srun -p labs -n 1 -c 8 --mem-per-cpu=1000 --pty bash
```

Una vez dentro del nodo, nos cabiamos al directorio de trabajo y ejecutamos el análisis:

```bash
cd /home/courses/$USER/Day03/GONE

bash script_GONE.sh popA
```

Desglose del comando:
- `bash`: El intérprete que ejecuta el script.
- `script_GONE.sh`: El script principal que coordina todas las fases del análisis (división por cromosomas, cálculo de LD y estimación de N<sub>e</sub>).
- `popA`: Es el prefijo de los archivos de entrada. El script buscará automáticamente los archivos `popA.map` y `popA.ped`.

### 3.4 Revisión de Resultados

Si el clúster presenta alta demanda o el análisis demora más de lo previsto, hemos preparado una corrida previa con éxito. Puedes copiar estos resultados a tu directorio personal para continuar con la práctica:

