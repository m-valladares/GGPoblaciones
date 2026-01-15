# Comparación de Métodos y Análisis Funcional 

Objetivo: Cruzar la información de RAiSD (estadística μ) y SweepFinder2 (CLR) para encontrar los candidatos más robustos y entender su función biológica.
Luego de esto tendremos 2 listas de genes, una que corresponde al 1% de los valores mas altos en RAiSD y otra al 1%de los valores mas altos en SweepFinder2.

Al final de esta sesión tendremos:

 - Gráficos de los barridos selectivos.
 - Una lista de genes "consensus" (apoyada por ambos métodos).
 - Una interpretación biológica de qué funciones están siendo seleccionadas.
 ---

## 1. Visualización: Manhattan Plots

Usaremos un script de R personalizado para visualizar los barridos selectivos a lo largo del cromosoma y ver si coinciden con nuestros genes de interés.

1.1 Preparar el Entorno R

Primero, cargamos R y conectamos con las librerías del curso (ggplot2, tidyverse) que usamos el dia anterior (Day04).

```bash
# 1. Cargar R
module load intel-compilers/2022.0.1 impi/2021.5.0 R/4.3.0

# 2. Conectar librerías
export R_LIBS=/home/courses/student23/Day05/bin_taller/R_libs_4.3
```

1.2 Graficar RAiSD y SweepFinder2

El script plot_manhattan.R toma dos argumentos:

- La herramienta (raisd o sf2).
- (Opcional) Un gen para resaltar.

```bash
# Graficar RAiSD
Rscript /home/courses/student23/Day05/bin_taller/plot_manhattan.R raisd

# Graficar SweepFinder2
Rscript /home/courses/student23/Day05/bin_taller/plot_manhattan.R sf2
```

Abran los archivos PNG generados (Manhattan_RAISD_.png y Manhattan_SF2_.png).

- ¿Ven peaks que superen la línea roja punteada (Top 1%)?
- ¿Coinciden los peaks entre ambos métodos?

1.3 "Highlight": ¿Cayó mi gen en un barrido?

Supongamos que nos interesa el gen Akirin2 (relacionado con sistema inmune). ¿Está bajo selección?

```bash
Rscript /home/courses/student23/Day05/bin_taller/plot_manhattan.R raisd Akirin2

```

Abran la imagen Manhattan_RAISD_Akirin2.png.

Si la franja verde (el gen) cae sobre un pico de puntos azules, ¡tenemos un candidato fuerte!

## 2. Intersección de Candidatos (Diagramas de Venn)

Un método puede dar falsos positivos. Si dos métodos distintos señalan el mismo gen, la evidencia es mucho más robusta.

En los scripts anteriores (SweepFinder2.md y RAiSD.md) generamos las listas de genes candidatos (Top 1%). No es necesario descargarlos; imprimiremos el contenido en pantalla para copiarlo.

Este listado es plano por lo que pueden mostrar en pantalla la lista.

```bash
# Imprimir lista de RAiSD
echo "--- LISTA RAiSD (Copiar abajo) ---"
cat genes_candidatos_SANTIAGO_raisd.txt

# Imprimir lista de SweepFinder2
echo -e "\n--- LISTA SF2 (Copiar abajo) ---"
cat genes_candidatos_SANTIAGO_sf2.txt
```

Estos listados lo ingresamos en la pagina web https://bioinformatics.psb.ugent.be/webtools/Venn/

Pregunta: ¿Cuántos genes están en la intersección (el centro)? Esos son sus genes candidatos con mayor respaldo.

En un trabajo completo deberiamos quedarnos con aquellos genes en la interseccion de ambos metodos, o mejor aun si agregamos un tercer metodo que esten en la intersección de 2 o mas metodos.

3. Análisis de Enriquecimiento (Gene Ontology)

Como estamos trabajando con un dataset reducido puede ser que no encontremos muchos genes en común pr lo que usaremos los 3 dataset, RAiSD, SF2 y comunes para hacer los analisis de enriquecimiento.

Tener una lista de nombres como "LOC100..." o "Akirin2" no nos dice qué función biológica está siendo seleccionada globalmente (¿Inmunidad? ¿Metabolismo? ¿Reproducción?). Hay muchas plataformas que realizan este tipo de analisis (G:profiler, Panther, entre otras) para este practico utilizaremos Metascape.org

IMPORTANTE (Input/Analysis Species):

Busquen y seleccionen "*Rattus norvegicus*".

¿Por qué? *Rattus rattus* tiene poca anotación funcional. Usamos a una especie cercana con historia similar como referencia para saber qué hacen los genes.

Hagan clic en Express Analysis.




