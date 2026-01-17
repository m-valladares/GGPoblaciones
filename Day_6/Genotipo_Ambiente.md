# Asociación Genotipo Ambiente (GEA)

En este taller exploraremos la intersección entre la genómica de paisajes y la conservación biológica utilizando como modelo de estudio a la mosca de los cuernos (*Haematobia irritans*).

*Haematobia irritans* es uno de los ectoparásitos más dañinos para la industria ganadera a nivel global. En Chile, su distribución abarca un gradiente latitudinal de más de 1000 km, exponiendo a diferentes poblaciones a condiciones ambientales drásticamente distintas: desde el clima mediterráneo de la zona central hasta las condiciones más frías y húmedas del sur.

El Genomic Offset (o desajuste genómico) es una métrica predictiva que estima qué tan "desadaptada" quedará una población ante el cambio climático. Al modelar la relación actual entre los SNPs candidatos y las variables ambientales (como las de [WorldClim](https://www.worldclim.org/data/index.html)), podemos proyectar cuánto debería cambiar la composición genética de una población para mantener su nivel de adecuación biológica (fitness) en el futuro.

Entender este fenómeno es crucial no solo desde una perspectiva biológica evolutiva, sino también para predecir la expansión de plagas y diseñar estrategias de manejo ante escenarios de cambio climático global.

### 1. Análisis de Redundancia (RDA)
#### 1.1 Preparación de los datos genómicos

Primero copiemos los datos que usaremos durante esta sesión
```bash
cp -r /home/courses/student21/Day06 \
  /home/courses/${USER}/
```

Los análisis de ordenación como el RDA no puede leer archivos BEAGLE o verosimilitudes de ANGSD directamente. Requiere genotipos "duros", por ende, en ANGSD utilizamos:

1. `-doPost 1`: Este parámetro indica a ANGSD que calcule la Probabilidad Posterior de cada genotipo posible (homocigoto dominante, heterocigoto, homocigoto recesivo).
    - ¿Por qué es importante? En lugar de adivinar el genotipo basándose solo en las lecturas (que en lcWGS son pocas), este comando usa las frecuencias alélicas de la población como "información previa" (prior) para asignar una probabilidad más robusta a cada genotipo mediante el teorema de Bayes.

2. `-doGeno 4`: Este comando le pide a ANGSD que escriba o "llame" los genotipos basándose en las probabilidades calculadas anteriormente.
    - El valor 4: Indica el formato de salida. Específicamente, genera un archivo donde los genotipos se representan en un formato compatible con PLINK que tendremos que usar más adelante.

Además, para los análisis necesitaremos matrices de datos completas (sin valores NA). En este taller, utilizamos una aproximación de imputación por la media. Esto, y los siguientes pasos del taller, lo haremos en R:

```R
# Imputar por la media de la columna
genotypes_imputed <- apply(genotypes, 2, function(x) {
  x[is.na(x)] <- mean(x, na.rm = TRUE)
  return(x)
})
```

En el comando anterior:
- `apply(genotypes, 2, ...)`: Recorre la matriz de genotipos columna por columna (cada columna representa un SNP).
- `is.na(x)`: Identifica qué individuos tienen datos faltantes para ese SNP específico.
- `mean(x, na.rm = TRUE)`: Calcula la frecuencia alélica promedio del SNP basándose en los individuos que sí tienen datos.
- Sustitución: Reemplaza el vacío (`NA`) con ese valor promedio.

**Importante:** Aunque este método es computacionalmente eficiente y estándar para RDA, es ideal cuando la tasa de datos faltantes es baja. En nuestro caso, al trabajar con lcWGS y haber filtrado previamente, nos permite mantener la estructura de la matriz sin sesgar significativamente las frecuencias alélicas globales.

Antes de continuar es necesario que comprendamos cómo funciona el análisis.

1. ¿Qué hace el RDA con los genotipos?

El Análisis de Redundancia (RDA) es una técnica de ordenación restringida. Imaginemos que es un híbrido entre un PCA (Análisis de Componentes Principales) y una Regresión Lineal Múltiple.
- La parte de la Regresión: El RDA intenta explicar la variación de una matriz de respuesta (miles de SNPs) usando una matriz de variables explicativas (datos de WorldClim).
- La parte de la Ordenación (PCA): Busca combinaciones lineales de los SNPs que estén máximamente correlacionadas con las variables ambientales.

¿Cómo usa los genotipos? El RDA trata a los genotipos (0, 1, 2) como variables numéricas continuas. No los ve como "A/A" o "A/T", sino como valores en un espacio euclidiano. Para que el algoritmo pueda calcular las varianzas y covarianzas necesarias para "ordenar" a los individuos en un gráfico, la matriz debe estar completa. Un solo valor NA en una fila invalida toda la operación matemática de esa fila.

2. ¿Por qué se imputa por la media de la columna?

Cuando imputamos por la media de la columna (que en genética de poblaciones equivale a la frecuencia alélica promedio de ese SNP en tu muestra), estamos aplicando un principio de "neutralidad estadística":
- Mantiene el centro de gravedad: Al insertar la media, no desplazas el promedio de esa variable. En términos de distancias euclidianas, ese individuo "faltante" se sitúa justo en el centro de la distribución de ese SNP.
- No inventa señales: Es la opción más conservadora. Si le asignáramos un 0 o un 2 (homocigotos) arbitrariamente, podrías estar creando una "falsa adaptación" al ambiente. Al poner la media (ej. 1.2), le dices al algoritmo: "No sé qué tiene este individuo, así que dale el valor más común/neutro para no sesgar el análisis".

3. ¿Cómo afecta esto al cálculo del RDA?

Aunque es el método estándar, tiene efectos que los estudiantes deben conocer:
- Reducción de la Varianza: Al rellenar NA con la media, la varianza de ese SNP disminuye ligeramente (porque estamos agregando valores que no se desvían del promedio).
- Subestimación de la Diferenciación: Si un individuo del "Cluster Norte" tiene un NA, y le ponemos la media de toda la población (incluyendo los del Sur), estamos "suavizando" un poco las diferencias geográficas.
- Impacto en SNPs de baja frecuencia: Si un SNP tiene mucha variación y muchos NA, la imputación por la media podría diluir la señal de selección.

#### 1.2 Obtención y Procesamiento de Datos Ambientales

En esta etapa del flujo de trabajo, extraemos la información climática necesaria para evaluar la adaptación local de *H. irritans*. Dado que trabajamos con un gradiente latitudinal de más de 1000 km, necesitamos variables que capturen las diferencias térmicas y de precipitación a lo largo de Chile.

1. Extracción de Variables Bioclimáticas

Para caracterizar el ambiente de cada punto de muestreo, utilizamos la base de datos WorldClim. Estas variables (BIO1-BIO19) representan tendencias anuales, estacionalidad y factores extremos de temperatura y precipitación.
- Presente: Utilizamos datos históricos promediados (1970-2000).
- Futuro: Seleccionamos proyecciones para el año 2060 bajo el escenario SSP5-8.5 (el escenario de emisiones más altas), lo que nos permite modelar el peor escenario posible para la especie. **Este segundo set de datos lo usaremos más adelante**.

2. Procedimiento en R

Para obtener esta información a partir de nuestras coordenadas de muestreo, seguimos estos pasos:
- Carga de coordenadas: Importamos un archivo con las latitudes y longitudes de los 30 individuos. Cabe mencionar que para el ejemplo usaremos las coordenadas con un factor de difusión (las que usamos en EEMS).
- Consulta de `geodata`: Usamos el paquete `geodata` para descargar las capas raster de WorldClim a una resolución de 2.5 minutos de arco (~4.5 km²).
- Extracción puntual: Mediante la función `extract()`, vinculamos cada coordenada geográfica con el valor exacto de las 19 variables bioclimáticas.

```R
library(geodata)
library(terra)

## Cargar coordenadas
coords <- read.table("hi_chr1_EEMS.txt", header = TRUE)

## Convertir a un objeto espacial (SpatVector) para la extracción
puntos <- vect(coords, geom = c("lon", "lat"), crs = "EPSG:4326")

## Descargar las variables bioclimáticas (resolución de 2.5 minutos)
bio_pres <- worldclim_global(var = "bio", res = 2.5, path = "data/")

## Extraer los valores para los 30 individuos del archivo de coordenadas
env_present <- terra::extract(bio_pres, puntos)

## Unir con las coordenadas originales
env_present <- cbind(coords, env_present)
```



