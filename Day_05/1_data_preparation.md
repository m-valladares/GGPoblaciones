Previa

cuenta

ssh -p 4603 student23@leftraru.nlhpc.cl

usuario student23

A42Me9ViYpVpkk

comandos clasicos

usoDisco (también puede usar df)
Este comando nos dira de cuanto espacio
de almacenamiento tenemos disponible, el
número de archivos de nuestro usuario y
cuánto hemos utilizado.

[dave@HAL]scp -P 4603 -r /local/path dbowman@leftraru.nlhpc.cl:~

[dave@HAL]rsync -avz /local/path/ -e 'ssh -p 4603' dbowman@leftraru.nlhpc.cl:~

descargar

# Día 5 - Taller


## Métodos de escaneo de genomas

En el siguiente modulo se realizarán 3 aproximaciones para evaluar señales de selección en el genoma, estas corresponden a:

- RAiSD
- H scan
- SweeFinder2

## Modelo de estudio
### Rattus rattus

Rattus rattus es un mamífero altamente invasivo con un notable registro de colonización a escala global. Nativa de Asia, la especie se ha establecido exitosamente en todos los continentes con excepción de la Antártica (Aplin et al. 2011; Conroy et al. 2013). Su comportamiento comensal y su asociación con asentamientos humanos y redes de comercio han sido factores clave en su éxito invasivo (Shiels et al. 2014; Abdelkrim et al. 2010).

La complejidad taxonómica del género Rattus incluye el llamado “Rattus rattus complex” (RrC), compuesto por diversas líneas profundamente divergentes. Entre ellas destaca R. tanezumi, especie hermana de R. rattus, con rangos superpuestos en Asia y evidencia de hibridación (Aplin et al. 2011; Yu et al. 2021; Tollenaere et al. 2010).

En Sudamérica, R. rattus probablemente llegó durante el siglo XVI a bordo de barcos europeos (Donaldson 1915, en Pennant 1781). Las poblaciones sudamericanas conocidas pertenecen exclusivamente al Linaje I (Aplin et al. 2011). Hasta ahora, R. tanezumi no ha sido reportada en el continente americano (Lack et al. 2012; 2013).

En Chile, los estudios existentes se enfocan en riesgos zoonóticos (Moreno et al. 2019; Salas et al. 2019), predación (Navarrete & Castilla 1993) e impactos en islas (Hahn & Römer 2002). A nivel genético poblacional, el conocimiento es aún limitado (Seguel et al. 2017). Datos preliminares indican que el Linaje I predomina en Chile, con mayor diversidad genética en la zona de Valdivia, posiblemente reflejando múltiples introducciones (González-Pinilla et al., en prep.).

## 3. Dataset del taller

1 cromosoma (dataset_taller_chr1.vcf.gz)

3–4 poblaciones (santiago.vcf.gz, P2, P3, P4)

Archivos entregados:

dataset_taller_chr1.vcf.gz

santiago.vcf.gz

Scripts base

Archivos SFS para SweepFinder2

Archivos preprocesados de haplotipos para H-scan

### 4. Métodos de escaneo genómico

## 4.1 RAiSD
Detecta señales de selección mediante la estadística μ, que integra:

- reducción de diversidad

- incremento de la frecuencia de haplotipos derivados

- patrones de LD característicos de barridos selectivos.

```
Codigos

```
srun --nodes=1 --cpus-per-task=8 --time=02:00:00 --mem=8G --pty bash



### 4.2 H-scan

Detecta "haplotype homozygosity tracts" para identificar selección reciente basada en haplotipos largos.


### 4.3 SweepFinder2

Basado en la razón de verosimilitud entre un modelo neutral (SFS) y un modelo con barrido selectivo.

`````

NC_046154.1	111003753	111061041	Map3k7	Stimulus
NC_046154.1	264675712	264820383	Lrrk2	Stimulus
NC_046155.1	2045437	2055534	Rela	Stimulus
NC_046155.1	25116904	25306570	Dock8	Immune
NC_046155.1	27230627	27262383	Vldlr	Stimulus
NC_046155.1	210969684	210982302	Arg1	Immune
NC_046156.1	177904329	177979537	Fgf10	Stimulus
NC_046157.1	36307209	36470454	Cblb	Immune
NC_046158.1	10588654	10634419	Notch1	Stimulus
NC_046164.1	74465840	74471293	Xbp1	Immune
NC_046166.1	4252297	4270528	Wnt5a	Immune
NC_046169.1	32634535	32694293	Ptpn11	Stimulus
NC_046171.1	28105199	28152044	Hk1	Stimulus
```

top1% RAISD

 4. Generar el archivo BED del Top 1%
grep -v 
sort -k2,2nr
head
awk