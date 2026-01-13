# Diversidad Genética

**- $\pi$ (Diversidad Nucleotídica):**
El promedio de diferencias por sitio entre dos secuencias.

**- $F_{IS}$ (Coeficiente de Endogamia):**
Para ver si hay exceso o déficit de heterocigotos (clave en peces de cuencas aisladas).

**- Heterocigosidad ($H_o$ y $H_e$):**
La base de la variación genética.

Si algunas poblaciones de *Orestias* vienen de vertientes o bofedales muy pequeños, se verán un $F_{IS}$ positivo alto y una Heterocigosidad muy baja en comparación con las poblaciones del Lago Chungará, por ejemplo. Esa es la "historia" biológica que el filtrado que hicimos permitirá ver con claridad


`vcftools` necesita saber qué individuos pertenecen a qué población.
Para ello tenemos los archivos: `Ascotan.txt`, `Carcote.txt`, `Chungara.txt` y `Lauca.txt`

---

## 1. Heterocigosidad y $F_{IS}$:

```bash
vcftools --vcf Orestias_only_SNPs.recode.vcf --het --out orestias_total
```

---

## 2. Calcular $\pi$ (Pi) para cada población

```bash
vcftools --vcf Orestias_only_SNPs.recode.vcf --keep Ascotan.txt --site-pi --out pi_Ascotan
vcftools --vcf Orestias_only_SNPs.recode.vcf --keep Carcote.txt --site-pi --out pi_Carcote
vcftools --vcf Orestias_only_SNPs.recode.vcf --keep Chungara.txt --site-pi --out pi_Chungara
vcftools --vcf Orestias_only_SNPs.recode.vcf --keep Lauca.txt --site-pi --out pi_Lauca
```

### $\pi$ (Pi), o Diversidad Nucleotídica
Es uno de los estadísticos más importantes y elegantes en genética de poblaciones. Si la heterocigosidad nos dice qué tan variables son los individuos, $\pi$ nos dice qué tan variable es la población completa a nivel de ADN.

#### 1. ¿Qué es $\pi$ exactamente?
Imagina que tomas dos secuencias de ADN al azar de la misma población (por ejemplo, de dos peces de Ascotan) y las comparas base por base.
$\pi$ es la probabilidad de que, en un sitio determinado, esas dos secuencias tengan nucleótidos diferentes.
En términos simples: es el promedio de diferencias por sitio entre todas las posibles parejas de individuos de una población.

#### 2. ¿Cómo se interpreta?
$\pi$ alto: Indica una población antigua, grande y estable. Ha tenido mucho tiempo para acumular mutaciones y mantenerlas.
$\pi$ bajo: Indica una población que probablemente pasó por un Cuello de Botella (reducción drástica de tamaño) o que es el resultado de un evento de colonización reciente por parte de pocos individuos (efecto fundador).

#### 3. ¿Por qué es clave para *Orestias*?
Estos peces viven en sistemas acuáticos con historias geológicas muy distintas:
- Ambientes grandes (Chungará/Lauca): Suelen tener valores de $\pi$ más altos porque son sistemas más estables y han mantenido poblaciones grandes por miles de años.
- Salares/Vertientes (Ascotan/Carcote): Aquí es donde se pone interesante. Si un salar se secó casi por completo en el pasado y luego se recuperó, el valor de $\pi$ debería ser muy bajo, porque todos los peces actuales descienden de unos pocos sobrevivientes.

#### 4. ¿Qué estamos calculando con VCFtools?
Cuando corres el comando `--site-pi`, VCFtools te da un valor para cada SNP. Pero para comparar poblaciones, lo que realmente nos sirve es el **Promedio de $\pi$**.


## Organización de Datos y Descarga de Resultados
Antes de pasar a RStudio, debemos organizar el espacio de trabajo local y traer los datos procesados desde el clúster.

Para mantener el orden, cada estudiante debe crear la carpeta donde residirán los datos.

```bash
mkdir -p /mnt/c/Users/pamel/Dropbox/CursoEnero2026/DataOrestias/CursoEnero2026_Orestias/div_gen_orestias
```

Entra a la carpeta:

```bash
cd /mnt/c/Users/pamel/Dropbox/CursoEnero2026/DataOrestias/CursoEnero2026_Orestias/div_gen_orestias
```

Ahora transfieran los archivos generados en el servidor a la carpeta que acaban de crear.  Los archivos necesarios son:

**- Heterocigosidad:** `orestias_total.het`

**- Diversidad Nucleotídica ($\pi$):**`pi_Ascotan.sites.pi`, `pi_Carcote.sites.pi`, `pi_Chungara.sites.pi`, y `pi_Lauca.sites.pi`

**- Metadatos:** El archivo `metadatos_orestias.csv`

Ahora, en RStudio, pueden correr el script `Diversidad_Genetica_Orestias.R`.
Como resultados, obtendrán los gráficos de **$H_o$**, **$F_{IS}$** y **$\pi$**.

