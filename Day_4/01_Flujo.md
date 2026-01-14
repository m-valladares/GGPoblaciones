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

Para este taller, hemos diseñado un flujo de trabajo que integra tres aproximaciones complementarias. El objetivo es que aprendan a triangular resultados: cuando diferentes métodos con distintas naturalezas de datos coinciden, nuestra hipótesis biológica se robustece.









### Eventos demográficos recientes

Para que GONE pueda estimar el Desequilibrio de Ligamiento (LD), no basta con conocer las frecuencias alélicas globales; necesitamos conocer la configuración de alelos en cada individuo (genotipos).

Aunque trabajamos con datos de baja cobertura (lcWGS), utilizamos ANGSD para realizar un "llamado de genotipos" basado en un enfoque bayesiano. A continuación, explicamos los parámetros críticos que nos permitieron pasar de probabilidades a los archivos que GONE puede leer:

#### Parámetros de Generación de Genotipos en ANGSD

1. `-doPost 1`: Este parámetro indica a ANGSD que calcule la Probabilidad Posterior de cada genotipo posible (homocigoto dominante, heterocigoto, homocigoto recesivo).
    - ¿Por qué es importante? En lugar de adivinar el genotipo basándose solo en las lecturas (que en lcWGS son pocas), este comando usa las frecuencias alélicas de la población como "información previa" (prior) para asignar una probabilidad más robusta a cada genotipo mediante el teorema de Bayes.

2. `-doGeno 4`: Este comando le pide a ANGSD que escriba o "llame" los genotipos basándose en las probabilidades calculadas anteriormente.
    - El valor 4: Indica el formato de salida. Específicamente, genera un archivo donde los genotipos se representan en un formato compatible con PLINK que tendremos que usar más adelante.

3. `-doBcf 1`: Este parámetro ordena la creación de un archivo en formato VCF (Variant Call Format).
    - Utilidad: Este archivo VCF es el puente que nos permite usar herramientas externas como bcftools para filtrar o PLINK para convertir los datos al formato final de GONE.

#### Filtros y formato

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

#### Ejecución de GONE y Análisis Demográfico

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

#### Revisión de Resultados

Si el clúster presenta alta demanda o el análisis demora más de lo previsto, hemos preparado una corrida previa con éxito. Puedes copiar estos resultados a tu directorio personal para continuar con la práctica:

