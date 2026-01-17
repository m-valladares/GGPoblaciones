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


### 2. Validación con Modelos Mixtos de Factores Latentes (LFMM)

Una vez identificadas las señales de selección con RDA, utilizamos LFMM (Latent Factor Mixed Models) para validar estas asociaciones. Mientras que el RDA es excelente para detectar señales poligénicas (muchos SNPs con efectos pequeños), el LFMM es más riguroso al evaluar la asociación de cada SNP individualmente, controlando por la estructura poblacional.

1. ¿Qué hace el LFMM?

El LFMM es un modelo estadístico diseñado para detectar asociaciones entre variables ambientales y variaciones genéticas, mientras corrige simultáneamente por la estructura de la población (causada por la demografía o la historia evolutiva).

En términos biológicos: Actúa como una prueba de asociación donde los "Factores Latentes" (K) representan la estructura poblacional no observada. Al incluir estos factores, nos aseguramos de que la asociación entre un SNP y el clima sea real y no un artefacto derivado de que los individuos simplemente se parecen porque viven cerca (Aislamiento por Distancia).

2. Definición del Valor K

Para este análisis, establecemos **K=3**.

Justificación: Este valor refleja nuestras 3 localidades de muestreo (Quellón, Quillota y Talca). Al usar K=3, le pedimos al modelo que "aprenda" la estructura de estos tres grupos y la use como una corrección de fondo antes de buscar asociaciones con el clima.

3. Calibración y el Factor de Inflación Genómica (GIF)

Ejecutamos el test con la opción calibrate = "gif".

¿Qué es el GIF? El Genomic Inflation Factor (GIF) mide cuánto se desvían nuestros valores p observados de lo que esperaríamos por puro azar.
- Un GIF cercano a 1.0 indica que el modelo está bien calibrado y que la estructura poblacional ha sido corregida correctamente.
- Si el GIF es muy alto (>2.0), los valores p están "inflados", lo que generaría demasiados falsos positivos. La calibración ajusta estos valores para que el test sea estadísticamente confiable.

4. De *P*-values a Q-values (FDR)

En genómica, al realizar 50,000 pruebas estadísticas (una por cada SNP), la probabilidad de encontrar algo por azar es muy alta. Para solucionar esto, no usamos el valor *p* estándar, sino el valor *q* (*q*-value).

**FDR** (False Discovery Rate): Al establecer un umbral de FDR < 0.1, aceptamos que un 10% de los SNPs detectados podrían ser falsos positivos. Es un equilibrio común en estudios de adaptación local para no perder señales biológicas importantes.

5. Intersección de Candidatos:

El paso final del script es cruzar los resultados: `candidatos_finales <- intersect(nombres_candidatos, snps_lfmm)`

¿Por qué hacemos esto? Cada método tiene sus debilidades:
- El RDA puede detectar falsas asociaciones si hay una estructura poblacional muy fuerte que coincide con el gradiente ambiental.
- El LFMM puede perder señales sutiles al ser un test individual SNP-a-SNP.

Los SNPs que aparecen en ambos análisis son nuestros candidatos más robustos. Representan variantes genéticas que no solo tienen un peso importante en la arquitectura multivariada de la adaptación (RDA), sino que también superan un estricto control de estructura poblacional (LFMM). Estos son los SNPs que utilizaremos para los análisis de vulnerabilidad climática.

### 3. Risk of non Adaptedness

#### 3.1 Instalación de pyRONA

Antes de proceder con los cálculos de vulnerabilidad, debemos asegurarnos de contar con las herramientas necesarias. pyRONA es una suite de Python diseñada para el cálculo del Genomic Offset, y su documentación oficial puede consultarse en este [link](https://pyrona.readthedocs.io/en/latest/).

1. Verificación de Requisitos

Para utilizar este programa de forma local en nuestros computadores, primero comprobamos si tenemos instalada la versión correcta de Python mediante el siguiente comando en la terminal:

```bash
python3 --version
```

2. Gestión de Entornos (Recomendado)

Instalar programas de Python directamente en el sistema debe hacerse con cautela. Una instalación descuidada puede generar conflictos entre diferentes versiones de Python que otros programas del sistema utilicen.

Para un manejo profesional y seguro, recomendamos el uso de Miniconda o Anaconda. Estas herramientas nos permiten crear "ambientes virtuales" (aislados del resto del sistema), donde podemos instalar versiones específicas de Python y sus librerías sin riesgo de incompatibilidades.

3. Instalación

Una vez confirmado el entorno, instalamos pyRONA utilizando el gestor de paquetes pip:

```bash
pip3 install pyRONA
```

**Nota para el taller:** Si estamos trabajando en un sistema local, podemos vincular Visual Studio Code directamente a nuestra terminal. Esto nos permite mantener un flujo de trabajo fluido, similar al que hemos utilizado en el clúster HPC, facilitando la edición de scripts y la ejecución de comandos en una sola interfaz.


#### 3.2 Obtención de Datos Ambientales Futuros (2060)

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


#### 3.3 Cálculo del Genomic Offset con pyRONA

En esta etapa final, estimamos el Risk of Non-Adaptation (RONA) o riesgo de desadaptación. Esta métrica cuantifica la magnitud del cambio en las frecuencias alélicas necesario en una población para seguir el ritmo del cambio climático proyectado al año 2060.

1. Preparación de Archivos para pyRONA

pyRONA es una herramienta basada en Python que requiere formatos específicos. Dado que en los módulos anteriores identificamos que solo un SNP coincidía estrictamente entre RDA y LFMM, para fines pedagógicos en este taller utilizaremos los 156 SNPs identificados por LFMM. Esto nos permite trabajar con un set de datos más robusto y observar patrones de vulnerabilidad más claros.

- Exportación desde R

Debemos generar archivos de texto plano sin encabezados, asegurando que el orden de los individuos sea idéntico en todos los archivos:
- Genotipos: Formato .lfmm (espacios, sin nombres de filas/columnas).
- Ambiente: Archivos .env para el presente y futuro.
- P-values: Un archivo por cada variable climática, asociando la significancia estadística calculada previamente.

**Nota Técnica**: Si un SNP tiene un valor NA en sus p-values, lo reemplazamos por 1.0. Esto le indica al software que no hay asociación significativa para ese sitio, evitando errores en el procesamiento de la matriz.

2. Ejecución usando Línea de Comandos

Tenemos que abrir una terminal en la cual definamos el directorio de trabajo que contenga los datos para pyRONA. Esto lo podemos hacer de forma local usando Visual Studio Code. Luego, ejecutamos pyRONA para cada variable ambiental. La lógica del comando es la siguiente:

```bash
# Para Rango Diurno Medio
pyRONA lfmm -pc clima_presente_final.env -fc clima_futuro_final.env -geno genotypes_lfmm.txt -assoc pvalues_Rango_Diurno_Medio.txt -covar_names covar_names.txt -P 0.1 -out rona_Rango_Diurno.csv

# Para Isotermalidad
pyRONA lfmm -pc clima_presente_final.env -fc clima_futuro_final.env -geno genotypes_lfmm.txt -assoc pvalues_Isotermalidad.txt -covar_names covar_names.txt -P 0.1 -out rona_Isotermalidad.csv

# Para Temperatura del Trimestre más Húmedo
pyRONA lfmm -pc clima_presente_final.env -fc clima_futuro_final.env -geno genotypes_lfmm.txt -assoc pvalues_Temp_Trimestre_Humedo.txt -covar_names covar_names.txt -P 0.1 -out rona_TempHumeda.csv

# Para Precipitación del Trimestre más Cálido
pyRONA lfmm -pc clima_presente_final.env -fc clima_futuro_final.env -geno genotypes_lfmm.txt -assoc pvalues_Precip_Trimestre_Calido.txt -covar_names covar_names.txt -P 0.1 -out rona_PrecipCalida.csv
```

¿Qué estamos calculando aquí? El software ajusta una regresión lineal entre las frecuencias alélicas actuales y las variables del presente. Luego, proyecta esa regresión hacia el valor climático del futuro (2060). El RONA Score es la diferencia teórica entre la frecuencia alélica actual y la necesaria para el futuro.

3. Visualización de la Vulnerabilidad Genómica

Tras obtener los resultados, regresamos a R para graficar el Mean RONA (promedio de todas las variables) y el desajuste por factor climático.
- RONA Promedio por Localidad: Este gráfico resume la vulnerabilidad global de cada población frente al escenario SSP5-8.5.
- Riesgo Genómico por Variable Ambiental: No todas las variables climáticas ejercen la misma presión de selección. Al desglosar el RONA por variable, podemos identificar qué factor (ej. temperatura o precipitación) es el principal motor de la desadaptación en cada zona de Chile.

4. Interpretación de Resultados

Al observar los gráficos, analizamos:
- ¿Qué población presenta el mayor RONA? Una puntuación más alta indica que la población actual de *Haematobia irritans* en esa localidad está genéticamente más alejada de lo que requerirá para sobrevivir óptimamente en 2060.
- Gradiente Latitudinal: Observamos si el riesgo aumenta hacia el norte o hacia el sur. En general, las poblaciones que enfrentan cambios más drásticos en sus variables críticas (como el Rango Diurno o la Temperatura del Trimestre más Húmedo) mostrarán una mayor vulnerabilidad.
- Implicancias Biológicas: Un RONA elevado sugiere que, para no extinguirse localmente o ver reducido su fitness, la población debe:
  - Evolucionar rápidamente (cambio en frecuencias alélicas).
  - Migrar hacia condiciones más favorables.
  - Depender de la plasticidad fenotípica.
