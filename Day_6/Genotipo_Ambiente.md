# Asociación Genotipo Ambiente (GEA)

En este taller exploraremos la intersección entre la genómica de paisajes y la conservación biológica utilizando como modelo de estudio a la mosca de los cuernos (*Haematobia irritans*).

*Haematobia irritans* es uno de los ectoparásitos más dañinos para la industria ganadera a nivel global. En Chile, su distribución abarca un gradiente latitudinal de más de 1000 km, exponiendo a diferentes poblaciones a condiciones ambientales drásticamente distintas: desde el clima mediterráneo de la zona central hasta las condiciones más frías y húmedas del sur.

El Genomic Offset (o desajuste genómico) es una métrica predictiva que estima qué tan "desadaptada" quedará una población ante el cambio climático. Al modelar la relación actual entre los SNPs candidatos y las variables ambientales (como las de [WorldClim](https://www.worldclim.org/data/index.html)), podemos proyectar cuánto debería cambiar la composición genética de una población para mantener su nivel de adecuación biológica (fitness) en el futuro.

Entender este fenómeno es crucial no solo desde una perspectiva biológica evolutiva, sino también para predecir la expansión de plagas y diseñar estrategias de manejo ante escenarios de cambio climático global.

### 1. Análisis de Redundancia (RDA)
#### 1.1 Preparación de los datos genómicos

Este taller lo haremos de forma local usando RStudio. Primero, descarguemos la carpeta con los datos a nuestros computadores desde este link: [**Day06**](https://www.dropbox.com/scl/fo/c6nkx7dguzxioixyqbjcz/AKeL6Sc8cvBNkZj_BANmoH4?rlkey=vqcr93xphwrgzrham056unbnx&dl=1).

Los análisis de ordenación como el RDA no puede leer archivos BEAGLE o verosimilitudes de ANGSD directamente. Requiere genotipos "duros", por ende, en ANGSD utilizamos:

1. `-doPost 1`: Este parámetro indica a ANGSD que calcule la Probabilidad Posterior de cada genotipo posible (homocigoto dominante, heterocigoto, homocigoto recesivo).
    - ¿Por qué es importante? En lugar de adivinar el genotipo basándose solo en las lecturas (que en lcWGS son pocas), este comando usa las frecuencias alélicas de la población como "información previa" (prior) para asignar una probabilidad más robusta a cada genotipo mediante el teorema de Bayes.

2. `-doGeno 4`: Este comando le pide a ANGSD que escriba o "llame" los genotipos basándose en las probabilidades calculadas anteriormente.

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

#### 1.2 Obtención de Datos Ambientales Presentes

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

El procedimiento es similar al usar las capas bioclimáticas proyectadas que se pueden descargar desde [WorldClim](https://www.worldclim.org/data/cmip6/cmip6_clim2.5m.html).


Todos los archivos necesarios fueron generados previamente y están en la carpeta descargada. Ahora trabajaremos en RStudio de forma local, primero revisemos el script `Genotipo-Ambiente.R`.

#### 1.3 Ejecución RDA y Selección de Candidatos

En este módulo, ejecutamos un Análisis de Redundancia (RDA) para identificar firmas de selección multivariada en *Haematobia irritans*. A diferencia de los métodos que analizan cada SNP por separado, el RDA nos permite observar cómo todo el conjunto genómico responde simultáneamente al gradiente ambiental.

1. ¿Qué hace el RDA?
El RDA es una técnica de ordenación restringida. Actúa como un híbrido: primero realiza una regresión lineal múltiple de nuestros 50,000 SNPs sobre las variables climáticas y, posteriormente, aplica un Análisis de Componentes Principales (PCA) sobre los valores predichos.

En términos biológicos: El RDA busca las combinaciones de SNPs que muestran la mayor correlación con el ambiente, permitiéndonos separar la variación genética "explicada" por el clima de la variación residual o neutra.

2. Manejo de la Colinealidad (VIF)

Antes de construir el modelo final, debemos filtrar las variables ambientales. En Chile, muchas variables de WorldClim están altamente correlacionadas (por ejemplo, la latitud correlaciona fuertemente con la temperatura).

¿Por qué eliminamos variables colineales? Si incluimos dos variables que dicen lo mismo, el modelo se vuelve inestable y no podemos saber cuál de ellas es la verdadera responsable de la selección. Utilizamos el Factor de Inflación de la Varianza (VIF):
- Un VIF > 10 indica que una variable es redundante.
- En el script, ejecutamos un bucle que elimina la variable con el VIF más alto hasta obtener un set de variables independientes. Esto asegura que cada vector ambiental en nuestro RDA aporte información única.

Análisis de las 4 variables finales
- Rango Diurno Medio: Clave para insectos, ya que determina si pueden estar activos o si deben buscar refugio por cambios bruscos de temperatura en un mismo día.
- Isotermalidad: Mide cuánto oscila la temperatura del día respecto a la del año.
- Temp_Trimestre_Humedo: Combina calor y humedad, factores vitales para el ciclo de vida de la mosca.
- Precip_Trimestre_Calido: En gran parte de Chile, esto representa las lluvias de verano o eventos esporádicos que afectan la humedad del suelo y el estiércol donde crían.

3. Construcción del Modelo Final

Ejecutamos el modelo principal con la instrucción: `hi.rda <- rda(gen.imp ~ ., data = pred, scale = TRUE)`

¿Qué construye este modelo?
- `gen.imp ~ .`: Indica que queremos explicar la matriz de genotipos en función de todas las variables climáticas filtradas.
- `scale = TRUE`: Es fundamental en genómica, ya que estandariza los SNPs (que tienen diferentes frecuencias alélicas) para que todos tengan el mismo peso en el análisis.

El valor de `RsquareAdj` nos indica qué porcentaje de la varianza genética total es explicada por las variables climáticas.
- En estudios genómicos, es común obtener valores entre el 5% y 15%. Aunque parezca bajo, es biológicamente significativo, ya que la mayor parte del genoma suele ser neutra o estar influenciada por procesos demográficos (deriva génica).

4. Test de Significancia (ANOVA)

Evaluamos la robustez del modelo mediante un test de permutaciones: `anova.cca(hi.rda)`.

¿Qué evalúa este ANOVA? Evalúa la hipótesis nula de que no existe relación entre los genotipos y el ambiente. Si el resultado no es significativo (p > 0.05), implica que la estructura observada podría explicarse por el azar o por otros procesos (como la estructura poblacional o aislamiento por distancia) que el modelo no capturó.

**Nota para el Taller**: En un estudio real, si el ANOVA no es significativo, deberíamos ser muy cautelosos al interpretar los resultados. Sin embargo, con fines pedagógicos, continuaremos el flujo para aprender a identificar los SNPs que muestran la mayor asociación teórica en este set de datos.

5. Extracción de Scores, Loadings y Outliers

Para identificar los SNPs bajo selección, analizamos los resultados del modelo:
- Scores y Loadings: Los scores posicionan a los individuos y variables en el espacio, mientras que los loadings (pesos) indican cuánto contribuye cada SNP a cada eje del RDA. Los SNPs con loadings altos son aquellos que más varían a lo largo del gradiente ambiental.
- SNPs Candidatos (Outliers): Definimos como candidatos a aquellos SNPs que se encuentran en los extremos de la distribución (fuera de +/- 3 desviaciones estándar).
- Estadísticamente, esto captura el 0.2% de los SNPs con la respuesta más extrema al clima. Estos son nuestros "candidatos a la adaptación local", que luego validaremos con LFMM y usaremos para el Genomic Offset.

6. ¿Cómo visualizar los resultados?

En el Triplot generado, observamos tres elementos:
- Puntos (SNPs): Los rojos son nuestros candidatos (outliers).
- Flechas (Vectores ambientales): Indican la dirección del cambio climático.
- Símbolos (Individuos): Agrupados por localidad para ver si la genética sigue un patrón geográfico.








#### 1.X Obtención de Datos Ambientales Futuros (2060)

Para calcular el Genomic Offset, no solo necesitamos conocer el ambiente actual, sino también predecir cómo cambiarán esas variables en las localidades de muestreo. Este proceso nos permite evaluar si las variantes genéticas actuales de *Haematobia irritans* serán aptas para las condiciones del mañana.

1. Selección del Escenario (SSP5-8.5)

En este taller, utilizamos los escenarios SSP (*Shared Socio-economic Pathways*) del CMIP6. Específicamente, seleccionamos el escenario SSP5-8.5:
- ¿Qué representa? Es el escenario de "desarrollo convencional" basado en combustibles fósiles, que representa el límite superior de las emisiones de gases de efecto invernadero.
- Justificación: Al ser el escenario más severo, nos permite identificar de manera robusta las áreas de mayor vulnerabilidad biológica (el peor escenario posible).

2. Elección del Modelo de Circulación Global (GCM)

Dado que el clima futuro es incierto, los científicos utilizan distintos modelos matemáticos (GCM). Nosotros descargamos proyecciones que promedian o seleccionan modelos climáticos globales (como el MIROC6 o CNRM-ESM2-1) disponibles a través de la plataforma WorldClim. Estos modelos simulan cómo responden la temperatura y la precipitación a los cambios en la composición atmosférica.

3. Flujo de Trabajo para Datos Futuros

Para construir nuestra matriz de predicción, seguimos este protocolo:
- Estandarización de Variables: Seleccionamos exactamente las mismas variables bioclimáticas (ej. BIO1 y BIO12) que resultaron significativas en el modelo del presente. No podemos predecir el offset basándonos en variables distintas a las que usamos para calibrar el modelo inicial.
- Extracción Espacial: Utilizando las coordenadas de nuestros 30 individuos, extrajimos de las capas raster del futuro (año 2060) los valores proyectados en esos mismos puntos geográficos.
- Cálculo de la Anomalía Climática: Observamos la diferencia entre el presente y el futuro. En el gradiente latitudinal de Chile, esto generalmente se traduce en un aumento de la temperatura hacia el norte y una disminución de las precipitaciones en la zona central y sur.
- Nota Pedagógica: Es fundamental entender que el Genomic Offset no es una medida de cuánto cambiará el clima, sino de cuánto "atrás" quedará el genotipo actual respecto a ese clima nuevo. Si una población de la zona central de Chile enfrenta en 2060 un clima que hoy es típico de una zona mucho más cálida, calculamos la distancia genética necesaria para alcanzar ese nuevo óptimo ambiental.

