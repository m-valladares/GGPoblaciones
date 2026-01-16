# Taller Práctico: Detección de Señales de Selección en Especies Invasoras

Modelo de Estudio: *Rattus rattus* (Población Santiago) Objetivo: Identificar loci outliers y genes candidatos bajo selección utilizando dos aproximaciones (RAiSD y SweepFinder2).

 ---

Trabajarán con datos de *Rattus rattus* (rata negra), una de las especies invasoras más exitosas del mundo. El genoma completo de este roedor es enorme (~2.8 Gb). Para que este práctico sea viable en tiempo real, nos centraremos en el Cromosoma 1, donde buscaremos "huellas" de adaptación reciente al ambiente urbano y periurbano de Santiago.

## 📂 Estructura de Trabajo

Para optimizar el tiempo, trabajaremos simulando un flujo real pero con "redes de seguridad".


~/Day05/Data: Aquí se encuentran los archivos crudos y copias de seguridad (backups) de todos los resultados. Si un análisis tarda mucho o falla, podrás copiar el archivo desde aquí.

~/Day05/Resultados_Estudiante: Esta será tu carpeta de trabajo. Aquí ejecutarás los códigos y guardarás tus salidas.


## 0. Inicio de sesión y recursos

Antes de empezar, debemos salir del nodo de acceso (login) y pedir un nodo de cómputo real para no saturar el servidor.

1. Solicitar nodo de cómputo: Ejecuta esto y espera a que el nombre de tu terminal cambie (ej. de [usuario@leftraru] a [usuario@cn045]).

```bash

srun -p labs --pty --mem=2G -n 1 -c 1 --time=01:00:00 /bin/bash

```

## 1. Configuración del Entorno

Una vez dentro del nodo de cómputo, necesitamos cargar las dependencias básicas y conectar los programas específicos del taller.


### 1.1 Cargar módulos necesarios

```bash

# A. Cargar dependencias
module load gsl
module load Anaconda3/2020.02
module load bcftools

# B. Conectar las herramientas del curso
export PATH=$PATH:/home/courses/student23/Day05/bin_taller

```

### 1.2 Crear tu espacio de trabajo y traer los datos

Vamos a crear tu carpeta y traer solo los datos necesarios (el VCF del cromosoma 1 y el archivo de genes).

```bash

# A. Crear tu carpeta de trabajo
mkdir -p ~/Day05/Resultados_Estudiante

# B. Crear el enlace directo a los datos del taller
# Esto crea un atajo llamado 'Data' que apunta a los archivos originales
ln -s /home/courses/student23/Day05/Data ~/Day05/Data

# C. Entrar a tu carpeta y copiar los inputs
cd ~/Day05/Resultados_Estudiante
cp ../Data/santiago.vcf.gz .
cp ../Data/CDS_genes_Rra.bed .

```

## Parte 1: Método RAiSD 

**¿Qué hace este programa?**

A diferencia de otros métodos que buscan una sola señal, RAiSD calcula un estadístico compuesto (llamado μ) que busca la "tormenta perfecta" de una barrida selectiva (Selective Sweep):

 1. Reducción de variabilidad: Como todos descienden del mismo cromosoma "ganador", la diversidad baja drásticamente (Valle de diversidad) ¿Todos los individuos se parecen mucho en esta zona?
 2. Desviación del SFS: Aparecen muchas mutaciones nuevas y raras (exceso de singletons) recuperándose del barrido. ¿Hay un exceso de variantes raras (muchos singletons)?
 3. Desequilibrio de Ligamiento (LD): Se forman bloques largos de variantes que se heredan juntas más de lo esperado.




### 1.1 Preparación y Ejecución

RAiSD es muy rápido, pero requiere que el archivo VCF esté descomprimido (texto plano).

```bash

# 1. Descomprimir VCF (RAiSD requiere texto plano)
gunzip -c santiago.vcf.gz > santiago.vcf

# 2. Ejecutar RAiSD
# -n: Nombre de la salida (RUN_SANTIAGO)
# -I: Input
# -f: Forzar sobreescritura
RAiSD -n RUN_SANTIAGO -I santiago.vcf -f


```

⏳ Atención: Si el análisis tarda más de 5 minutos, presiona Ctrl + C para detenerlo y copia el resultado listo

```bash

#cp ../Data/RAiSD_Report.RUN_SANTIAGO .

```
Este comando se encuentra con # para evitar se ejecute por error.

### 1.2. Procesamiento de Resultados (Filtrado Top 1%)

RAiSD le asigna un puntaje (μ) a cada SNP. Mientras más alto el puntaje, más probable es que esté bajo selección. Como no tenemos un modelo demográfico neutral para comparar (simulaciones), usaremos un enfoque empírico: asumiremos que el 1% de los sitios con el puntaje más alto son nuestros candidatos a selección.

Este bloque de código hace tres cosas:

 1. Limpia el reporte desordenado de RAiSD.
 2. Ordena los SNPs de mayor a menor puntaje.
 3. Calcula matemáticamente cuántos SNPs corresponden al 1% superior y los guarda en un archivo .bed.

```bash
# A. Formatear la salida de RAiSD ("Arreglar columnas")
awk '/^\/\// {CHR=$2; next} {print CHR, $1, $1, $2}' RAiSD_Report.RUN_SANTIAGO > raisd_formateado.txt

# B. Ordenar por Score (Mayor a menor)
sort -k4,4gr raisd_formateado.txt > raisd_ordenado.txt

# C. Calcular dinámicamente el Top 1%
# Contamos el total de líneas y calculamos el 1% matemático
TOTAL_SNPS=$(wc -l < raisd_ordenado.txt)
UMBRAL=$(( TOTAL_SNPS / 100 ))

echo "Analizando $TOTAL_SNPS SNPs. Seleccionando el Top 1% ($UMBRAL variantes)..."

# D. Crear el archivo BED con los candidatos
# Usamos el $UMBRAL calculado. Restamos 1 a la posición para formato BED.
head -n $UMBRAL raisd_ordenado.txt | awk -v OFS='\t' '{print $1, int($2)-1, int($2), $4}' > top_raisd.bed

```
**¿Qué significa "Calcular dinámicamente el Top 1%"?**

En biología no existe un "número mágico" de SNPs bajo selección. En lugar de decir "tomaremos los 100 mejores", usamos un enfoque porcentual.

- Si nuestro archivo tiene 1,000 SNPs, el Top 1% son 10.
- Si tiene 1 millón de SNPs, el Top 1% son 10,000.

El script hace esto automáticamente ("dinámicamente") contando cuántas líneas tiene tu resultado (wc -l) y dividiendo por 100. Así, el código funciona igual para *Rattus*, *Orestias* o *Nothofagus*, sin importar cuántos datos tengas.

**Nota Técnica: El Formato .bed**

Para cruzar datos genómicos, usamos el estándar universal BED. Es un archivo de texto simple con 3 columnas obligatorias:

 - Cromosoma (ej. NC_0123.1)
 - Inicio (Start)
 - Fin (End)

⚠️ Ojo con las coordenadas: El formato BED es "0-based" (cuenta desde 0), mientras que los VCF suelen ser "1-based" (cuentan desde 1). Por eso en el código verán una resta (int($2)-1) para ajustar la posición.

### 1.3: Anotación Funcional (cruce con genes)

Tener una lista de coordenadas no nos dice mucho biológicamente. Necesitamos saber si esos sitios bajo selección "cayeron" dentro de un gen. 

Para eso usaremos *bedtools intersect*, que actúa como un mapa digital superponiendo nuestra lista de candidatos (Top 1%) con el archivo de anotación de genes (CDS_genes_Rra.bed).

**¿De dónde salió el archivo CDS_genes_Rra.bed?**

Para saber "qué gen es qué", dependemos de que exista un Genoma de Referencia Anotado.

 1. En especies modelo (*Rattus*, humanos, *Arabidopsis*): Los científicos publican un archivo .GFF o .GFF3 (General Feature Format) que contiene las coordenadas de todos los genes, exones y CDS. Nosotros descargamos ese GFF de NCBI y lo convertimos a .bed para este taller.
 2. En especies NO modelo: Si trabajan con organismos que solo tienen genomas a nivel de Scaffold y sin anotación oficial:

- Tendrán que anotar su genoma usando herramientas como MAKER o Augustus.
- O bien, mapear sus lecturas contra el genoma de una especie cercana que sí esté anotada (ej. usar el genoma de *Rattus norvegicus* para estudiar ratones silvestres menos estudiados).

```bash

# E. Cruzar con genes (Anotación)
# -a: Nuestro archivo de variantes candidatas
# -b: El archivo con la ubicación de los genes
# -wb: Write Block (si hay coincidencia, escribe también la información del gen)
bedtools intersect -a top_raisd.bed -b CDS_genes_Rra.bed -wb > raisd_hits.txt

# F. Generar lista limpia de genes únicos
# Cortamos la columna 8 (nombre del gen), ordenamos y quitamos duplicados
cut -f 8 raisd_hits.txt | sort | uniq > genes_candidatos_SANTIAGO_raisd.txt
```

Resultados Finales

```bash

echo "------------------------------------------------"
echo "Número de genes candidatos detectados por RAiSD:"
wc -l genes_candidatos_SANTIAGO_raisd.txt
echo "------------------------------------------------"

echo "Primeros 10 genes candidatos:"
head genes_candidatos_SANTIAGO_raisd.txt

```
Desafío rápido: Copia uno de los nombres de los genes que aparecieron (ej. LOC100... o el nombre que salga) y búscalo en Google o NCBI. ¿Tiene alguna función relacionada con el metabolismo, inmunidad o comportamiento? (Recuerda que estamos viendo ratas urbanas).

**¿Qué son estos genes LOC100...?**

Es muy probable que en su lista de candidatos encuentren nombres como LOC108348163.

¿Qué significa? Son genes predichos automáticamente por algoritmos (NCBI Gnomon) basados en secuencias similares, pero que aún no tienen un nombre funcional confirmado (como P53 o MC1R).

¿Qué hago si me sale uno?

- No se frustren si no aparece nada en Google.
- Tip: Busquen el ID del gen en la base de datos de NCBI Gene. A menudo, en la descripción dirá "ortholog of..." refiriéndose a un gen de ratón (Mus musculus) o humano. La función de ese ortólogo es su mejor pista sobre qué está haciendo ese gen en su especie.