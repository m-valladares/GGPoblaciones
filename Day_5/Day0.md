Day0.md
CONEXION A ROSALIND

ssh -p 53497 lab3@138.219.57.220
_*qq7ZuhjarM17a

En este script son los pasos previos para preparar el practico

#paso -1, descargar bam de NAS a Rosalind ya que Margaret Falló

lftp -e 'set ftp:ssl-force true; set ftp:ssl-protect-data true; set ssl:verify-certificate no' -u Rosalind ftp://192.168.200.10

###Primer set

mget BT177-S01-002R0010.realign.bam* BT177-S01-002R0011.realign.bam* BT177-S01-002R0013.realign.bam* BT177-S01-002R0014.realign.bam* BT177-S01-002R0018.realign.bam* BT177-S01-002R0019.realign.bam* BT177-S01-002R0020.realign.bam* BT177-S01-002R0021.realign.bam* BT177-S01-002R0022.realign.bam* BT177-S01-002R0023.realign.bam* BT177-S01-002R0024.realign.bam* BT177-S01-002R0034.realign.bam*

#segundo set
cd ../bamSet2

mget BT177-S01-002R0047.realign.bam* BT177-S01-002R0048.realign.bam* BT177-S01-002R0049.realign.bam* BT177-S01-002R0050.realign.bam* BT177-S01-002R0051.realign.bam* BT177-S01-002R0052.realign.bam* BT177-S01-002R0053.realign.bam* BT177-S01-002R0054.realign.bam* BT177-S01-002R0038.realign.bam* BT177-S01-002R0039.realign.bam* BT177-S01-002R0040.realign.bam* BT177-S01-002R0041.realign.bam* BT177-S01-002R0042.realign.bam* BT177-S01-002R0043.realign.bam*

sacar chr1

Luego ademas sacar el archivo CDS_genes_Rra.bed de Rosalind o NAS

Bajar de NAS a Rosalind y de Rosalind a mi computador local y luego a student23



# 1. Definimos las variables clave
REF="/data2/lab3/paulo/ref/GCF_011064425.1/GCF_011064425.1_Rrattus_CSIRO_v1_genomic.fna"
CHROM="NC_046154.1"

# 2. Nos aseguramos de tener la lista de bams
cd /data2/lab3/paulo/bam
ls *.realign.bam > bams_taller.list

# 3. GENERAR EL VCF (Variant Calling)
# Esto tardará un poco (quizás 10-20 mins dependiendo del servidor)
echo "Iniciando Variant Calling en $CHROM..."

bcftools mpileup -f $REF \
  -b bams_taller.list \
  -r $CHROM \
  --min-MQ 20 \
  -a AD,DP,SP -Ou | \
bcftools call -mv -O z -o dataset_raw.vcf.gz

echo "Variant Calling terminado."

# 4. LIMPIEZA Y PREPARACIÓN (El paso mágico)
# Filtramos calidad > 30, eliminamos missing data excesiva
# Y convertimos '0/1' a '0|1' para engañar a H-scan (pseudo-faseo)

echo "Filtrando y formateando para el taller..."

# Paso A: Filtrar
bcftools view -i 'QUAL>30 && F_MISSING<0.1' -m2 -M2 -v snps dataset_raw.vcf.gz -O z -o dataset_filtered.vcf.gz

# Paso B: Truco de sed para fasear y comprimir final
zcat dataset_filtered.vcf.gz | sed 's/\([01]\)\/\([01]\)/\1\|\2/g' | bgzip > dataset_taller_chr1.vcf.gz

# Paso C: Indexar
bcftools index dataset_taller_chr1.vcf.gz

echo "¡Listo! Archivo final: dataset_taller_chr1.vcf.gz"





Necesitare 1 cromosoma de mi rattus rattus, puede ser de unas 4 poblaciones, Brazil, Argentina, Chile (Santiago) y Peru (Madre de Dios)

ETAPA 1: Preparación de Datos (En servidor "Margaret")

Estás en tu servidor habitual. Tu misión es generar el archivo dataset_taller.vcf.gz que contenga solo el Cromosoma X (el que elijas) y solo las 4 poblaciones (Brasil, Argentina, Chile, Perú).

1. Crear la lista de individuos (samples.txt) Primero, crea un archivo de texto con los IDs de los individuos que quieres mantener (uno por línea).

samples.txt
    
    BT177-S01-002R0047 brasil
    BT177-S01-002R0048 brasil
    BT177-S01-002R0049 brasil
    BT177-S01-002R0050 brasil
    BT177-S01-002R0051 brasil
    BT177-S01-002R0052 brasil
    BT177-S01-002R0053 brasil
    BT177-S01-002R0010 argentina
    BT177-S01-002R0011 argentina
    BT177-S01-002R0013 argentina
    BT177-S01-002R0014 argentina 
    BT177-S01-002R0054 argentina
    BT177-S01-002R0018 madrededios
    BT177-S01-002R0019 madrededios
    BT177-S01-002R0020 madrededios
    BT177-S01-002R0021 madrededios
    BT177-S01-002R0022 madrededios
    BT177-S01-002R0023 madrededios
    BT177-S01-002R0024 madrededios
    BT177-S01-002R0038 santiago
    BT177-S01-002R0039 santiago
    BT177-S01-002R0040 santiago
    BT177-S01-002R0041 santiago
    BT177-S01-002R0042 santiago
    BT177-S01-002R0043 santiago
    BT177-S01-002R0034 santiago



2. Filtrar el VCF (Subsetting) Usaremos bcftools para filtrar por lista de individuos (-S) y por región (-r).

# -S: Archivo con la lista de muestras a mantener
# -r: Región (ej: chr1 o el cromosoma que veas con más diversidad)
# --force-samples: Para evitar errores si algún nombre no calza perfecto
# -O z: Salida comprimida

bcftools view -S samples.txt -r NC_046157.1 --force-samples mis_datos_rattus.vcf.gz -O z -o dataset_taller.vcf.gz

# IMPORTANTE: Indexar el archivo resultante
bcftools index dataset_taller.vcf.gz

Cromosoma 4 esta bueno para usar NC_046157.1
ssh -p 53497 lab3@138.219.57.220
_*qq7ZuhjarM17a

Entonces me quede con los cromosomas 1 y 9:

(handsonVCF) lab3@rosalind:/data2/lab3/paulo/bam$ ls -lh dataset_taller_*.vcf.gz
-rw-rw-r-- 1 lab3 lab3 342M Dec 22 21:44 dataset_taller_chr1.vcf.gz
-rw-rw-r-- 1 lab3 lab3 124M Dec 22 18:54 dataset_taller_chr9.vcf.gz

scp -P 53497 lab3@138.219.57.220:/data2/lab3/paulo/bam/popmap.txt /Users/paulozepeda/Desktop/curso_ggpob/


Ahora estoy en nhlp

mover
/home/courses/student23/Day05/Data
mv /home/courses/student23/Day05/popmap.txt /home/courses/student23/Day05/Data

subir hscan a leftraru

➜  desktop ls H-scan.cpp
H-scan.cpp
scp -P 4603 /Users/paulozepeda/desktop/H-scan.cpp student23@leftraru.nlhpc.cl:/home/courses/student23/Day05/bin_taller
/Users/paulozepeda/desktop

Luego separar Santiago 

para cargar bcftool
module load bcftools

santiago_ids.txt dataset_taller_chr1.vcf.gz --force-samples -O z -o santiago.vcf.gz

demoro como 2 minutos


/home/courses/student23/Day05/bin_taller/bcftools view -S santiago_ids.txt dataset_taller_chr1.vcf.gz --force-samples -O z -o santiago.vcf.gz

RAISD

Aa cmo se instalo




luego para correro tuve que descomprimir el vcf.gz y correr
y se demoro Total execution time 25.33186 seconds

TALLER

usar RAiSD

Preparar el ambiente:

module load gsl
module load bcftools
cd ~/Day05/Data

Luego descomprimir el .vcf.gz

gunzip -c santiago.vcf.gz > santiago.vcf

luego ejecturar el analisis:

../bin_taller/RAiSD -n RUN_SANTIAGO -I santiago.vcf -f

NOTA: en este practico nos centramos en 1 solo cromosoma, en sus datos deben primero dividir el vcf por población y luego cada uno de esos VCF dividirlos por cromosoma, ademas de considerar si quieren incluir la mitocondria, cloroplastos y cromosomas sexuales.

Este es el codigo que utilice:

bcftools view -S samples.txt -r NC_046157.1 --force-samples mis_datos_rattus.vcf.gz -O z -o dataset_taller.vcf.gz

# IMPORTANTE: Indexar el archivo resultante
bcftools index dataset_taller.vcf.gz

Nota: En el el archivo samples.txt divido las muestras de interes, las que pueden ser una población y con -r se indico que cromosoma incluir.

# SF2

es muy quisquilloso
lo primero es transformar el vcf a un archivo tipo input para SF2
el cual no tiene espacio si no tabulaciones

vcf2sf2.sh

#!/bin/bash
# Script: vcf2sf2.sh (Versión Estricta con Tabs)
# Convierte VCF a formato SweepFinder2 usando Tabulaciones

INPUT_VCF=$1
OUTPUT_SF2=$2

if [ -z "$OUTPUT_SF2" ]; then
    echo "Error. Uso correcto: vcf2sf2.sh <input.vcf> <output.sf2>"
    exit 1
fi

echo "--- Convirtiendo VCF a formato SF2 (Forzando Tabs) ---"

# 1. Encabezado con TABULACIONES (\t)
# SweepFinder2 a veces falla si encuentra espacios normales.
printf "position\tx\tn\tfolded\n" > "$OUTPUT_SF2"

# 2. Cuerpo del archivo
bcftools +fill-tags "$INPUT_VCF" -Ou -- -t AC,AN | \
bcftools query -f '%POS\t%AC\t%AN\n' | \
awk 'BEGIN {OFS="\t"} {
    pos = $1
    ac_raw = $2
    an = $3

    # Limpiar conteos (por si hay múltiples alelos)
    split(ac_raw, a, ",")
    ac = a[1]

    # Calcular alelo menor
    ref = an - ac
    if (ac < ref) { x = ac } else { x = ref }

    # Imprimir solo si es válido
    if (x > 0 && an > 0) {
        print pos, x, an, "1"
    }
}' >> "$OUTPUT_SF2"

echo "¡Listo! Archivo creado: $OUTPUT_SF2"
# Mostramos las primeras líneas para verificar
head -n 5 "$OUTPUT_SF2"

