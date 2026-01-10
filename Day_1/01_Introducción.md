# Introducción a la línea de comandos y uso del HPC (NLHPC)

El objetivo de esta sesión es familiarizar a las y los participantes con el entorno de trabajo en sistemas Linux y en el clúster del NLHPC (Leftraru), utilizando la línea de comandos, Visual Studio Code y R/RStudio como herramientas integradas para reproducir análisis de genómica de poblaciones.

---

## 1. Presentación

- Presentación del curso y de los instructores.
- Por qué usamos HPC en genómica: volumen de datos, complejidad computacional y reproducibilidad.
- Breve repaso: ¿Qué es un lenguaje de programación?  
- Lenguajes que utilizaremos en el curso:
  - **bash**: automatización de flujos.
  - **R**: análisis estadístico y genómico.
- Entornos de trabajo: local vs remoto.

---

## 2. Qué es un HPC y cómo está estructurado el NLHPC

### 2.1 Conceptos básicos

- **High Performance Computing (HPC):** infraestructura de cómputo diseñada para procesar grandes volúmenes de datos o realizar cálculos intensivos.
- **Componentes principales:**
  - **Login node:** punto de acceso, en este nodo **no se deben ejecutar análisis**. Lo usaremos para acceder al clúster, organizar archivos, crear carpetas y solicitar recursos mediante SLURM.
  - **Compute nodes:** donde se ejecutan los trabajos enviados al planificador de trabajos (*scheduler*). En estos nodos solicitaremos recursos (CPUs y memoria) para ejecutar nuestros análisis. A diferencia del nodo de acceso (*login node*), están designados para correr análisis. Casi la totalidad de los recursos que dispone un clúster están divididos en estos nodos. Además, dependiendo del clúster, pueden definirse nodos especializados (GPU, walltime, etc).
  - **Job scheduler (SLURM):** es el software que gestiona la cola de tareas. Usando SLURM podremos solicitar recursos y enviar trabajos a los nodos de cómputo. 

### 2.2 Clúster del NLHPC (Guacolda-Leftraru Epu)

El **NLHPC (National Laboratory for High Performance Computing)** es el centro nacional de supercómputo de Chile. Su infraestructura principal es el clúster **Guacolda-Leftraru Epu**, compuesto por múltiples nodos con miles de CPUs disponibles para investigación científica.

- Sitio oficial: [https://www.nlhpc.cl/](https://www.nlhpc.cl/)
- Wiki general del NLHPC (información técnica, manuales, tutoriales): [https://wiki.nlhpc.cl/P%C3%A1gina_principal](https://wiki.nlhpc.cl/P%C3%A1gina_principal)
- <a id="leftraru"></a>Tutorial específico de acceso a Leftraru (SSH): [https://wiki.nlhpc.cl/Tutorial_de_acceso_a_Leftraru_via_SSH](https://wiki.nlhpc.cl/Tutorial_de_acceso_a_Leftraru_via_SSH)

**Arquitectura general del sistema:**
```
Usuario local (student21) ──▶ Nodo de acceso (login) ──▶ SLURM scheduler ──▶ Nodos de cómputo
```

### 2.3 Cuentas personales para el curso

El NLHPC nos ha facilitado cuentas para todas/os los estudiantes del curso, a continuación se indica la asignación de usuarios. Antes del comienzo del curso les enviaremos por correo las contraseñas para que puedan acceder al clúster. La mayoría de los datos y entornos de trabajo ya han sido instalados en sus cuentas, de esta forma agilizaremos el trabajo. Estas cuentas son personales e intransferibles, además son temporales y serán desactivadas una vez que termine el curso.

| Nombre Estudiante | Usuario asignado |
|:---------------:|:---------------:|
| Moisés V.  | student21  |
| Pamela M.  | student22  |
| Paulo Z.   | student23  |
| ...  | studentXX  |
| ...  | studentXX  |
| ...  | studentXX  |

Para acceder al clúster con sus cuentas personales, no olviden revisar el [**Tutorial de acceso a Leftraru**](#leftraru) indicado más arriba.

---

## 3. Primeros pasos en la línea de comandos

Una vez que se conectan por primera vez al servidor, el contenido de su directorio de usuario (studentXX) se encuentra en blanco. Por lo tanto, lo primero que haremos será crear un directorio de trabajo. Al nombrar directorios o archivos no es recomendable usar caracteres especiales, como tildes o la letra ñ. Una buena práctica es usar nombres simples y, preferentemente, en inglés.

Comenzaremos creando un directorio llamado Day01. Para esto usamos el comando mkdir:

```bash
mkdir Day01
```

Este comando crea el directorio `Day01` en la ruta donde nos encontramos actualmente. Para saber en qué ruta del sistema estamos trabajando, usamos el comando:

```bash
pwd
```

Para listar el contenido del directorio actual, usamos:

```bash
ls
```

Si todo salió bien, deberíamos ver el directorio `Day01` listado. Ahora entraremos al directorio que acabamos de crear usando el comando *change directory* (`cd`):

```bash
cd Day01
```

Volvemos a listar su contenido usando `ls`. Como podemos ver, el directorio está vacío. El siguiente paso es copiar un archivo de ejemplo para comenzar a trabajar durante el taller. En este caso, y también lo haremos en los otros días del curso, copiaremos un archivo que se encuentra en el directorio de otro usuario.

```bash
# Muy importante: cambien studentXX por el nombre real de su cuenta.
cp /home/courses/student21/Day01/documento.txt /home/courses/studentXX/Day01/
```

Este comando copia el archivo `documento.txt` desde la carpeta `Day01` del usuario **student21** hacia la carpeta `Day01` de **su propia cuenta**.

Finalmente, verificamos que el archivo fue copiado correctamente usando `ls`. Ahora ya disponen de un directorio de trabajo y de un archivo para continuar con el taller.

### 3.1 Navegación y manejo de archivos

A continuación se muestran los comandos necesarios para movernos dentro del árbol de directorios o carpetas, además se muestran los comandos más usados para visualizar, crear o eliminar archivos.

```bash
whoami                # muetra el usuario logeado
ls                    # listar archivos y carpetas
ls -lh                # listar archivos con detalles
pwd                   # mostrar ruta actual (de la carpeta en que estamos)
cd                    # cambiar de directorio al home
cd /ruta              # cambiar de directorio a la ruta que indicamos
cd ..                 # "subir" de directorio
mkdir nombre_carpeta  # crear carpeta
rm nombre_archivo     # eliminar archivo (usar con precaución)
rmdir nombre_carpeta  # eliminar carpetas vacías (usar con precaución)
rm -r nombre_carpeta  # eliminar carpetas con archivos (usar con precaución)
```

Otros comandos de uso común pueden encontrarse en internet si buscan **referencias de comandos UNIX**, o comúnmente llamadas __UNIX *cheat sheets*__.

A continuación se muestran algunos comandos clásicos para renombrar o copiar elementos. Para usarlos es necesario tener un elemento, objeto o documento de interés. En la carpeta `Day01` ahora cuentan con un archivo de prueba llamado `documento.txt` para probar estos comandos.

```bash
head documento.txt      # muestra las primeras 10 líneas del archivo
tail documento.txt      # muestra las últimas 10 líneas del archivo
cat documento.txt       # muestra el contenido completo del archivo
wc documento.txt        # muestra la cantidad de líneas, palabras y bytes del archivo
wc -l documento.txt     # muestra solo la cantidad de líneas del archivo
```

---

### 3.2 Comandos `cp` y `mv`

Para copiar un archivo en el mismo u otro directorio, usamos el comando `cp`. Este comando necesita al menos dos argumentos: el origen (lo que quieres copiar) y el destino (dónde quieres poner la copia y con qué nombre).

- Para copiar y pegar el archivo en el mismo directorio con otro nombre (i.e. duplicar el archivo):
```bash
cp documento.txt copia_de_documento.txt
```

Antes de continuar usando `cp`, creamos un directorio llamado `prueba` hacia donde copiaremos nuestro `documento.txt`.
```bash
# Primero nos aseguramos de encontrarnos en el directorio Day01
# Reemplacen student21 por su nombre de usuario
cd /home/courses/student21/Day01

# Nos aseguramos de la ruta en la que estamos usando:
pwd

# Ahora crearemos el directorio dentro de Day01 (será una subcarpeta)
mkdir prueba

# Confirmamos que creamos la carpeta usando:
ls
```

- Ahora veremos cómo copiar el documento y pegarlo en otro directorio **manteniendo** el nombre. En este caso lo pegaremos en el directorio que creamos en el paso anterior.
```bash
# Reemplacen student21 por su nombre de usuario
cp documento.txt /home/courses/student21/Day01/prueba/
```
- En cambio, para copiar el documento y pegarlo en otro directorio **cambiando** el nombre usamos:
```bash
# Reemplacen student21 por su nombre de usuario
cp documento.txt /home/courses/student21/Day01/prueba/copia_de_documento_otro_directorio.txt
```

Si prestaron atención, se habrán dado cuenta que estos últimos pasos los hicimos estando en el directorio `Day01`, pero enviando los archivos al directorio `prueba`. Para confirmarlo veamos en qué directorio estamos y luego (si es necesario) ingresemos al directorio `prueba`:

```bash
pwd
# Si están en Day01, ahora ingresemos a prueba:
cd prueba
```

Podemos ver los archivos que copiamos usando `ls`. Ahora volvamos al directorio `Day01`, recuerden primero revisar en qué directorio están usando `pwd` y luego cambien de directorio usando `cd`. En este caso como queremos *volver* un directorio, podemos usar `cd ..`:

```bash
pwd
# Si estamos en el directorio prueba, podemos volver a Day01 usando:
cd ..
```

El comando `cd ..` se utiliza en la línea de comandos para moverse un **nivel hacia arriba** en la estructura de directorios. En sistemas tipo Linux, los directorios están organizados de forma jerárquica (como un árbol), y `..` representa siempre el directorio superior del directorio actual. Por ejemplo, si estamos ubicados en `/home/courses/student21/Day01/prueba`, al ejecutar `cd ..` pasaremos a `/home/courses/student21/Day01`. Este comando es fundamental para navegar por el sistema de archivos de manera rápida y eficiente sin necesidad de escribir rutas largas.

- Extra al usar el comando copiar: opción recursiva `-r` o `-R`: esta opción es obligatoria si queremos copiar un directorio completo (carpetas, subcarpetas y todo su contenido).
```bash
# Por ahora no correremos este comando
# Reemplacen student21 por su nombre de usuario
# cp -r /home/courses/student21/Day01/ /home/courses/student21/Day02/
```

---

Para mover y renombrar archivos, usamos el comando `mv`. Este comando también necesita al menos dos argumentos.

- La función principal de `mv` es trasladar un archivo o directorio de una ubicación a otra. El archivo original desaparece de su ubicación anterior y aparece en la nueva.
```bash
mv copia_de_documento.txt /home/courses/student21/Day01/prueba/
```

También podemos usar `mv` para renombrar archivos o directorios. Si el destino especificado es un nuevo nombre dentro del mismo directorio, el comando funciona como un renombrador. En sistemas Linux/Unix, renombrar un archivo es conceptualmente lo mismo que "moverlo" a un nombre de archivo diferente en la misma ubicación.
```bash
# Haremos estos cambios en los documentos de la carpeta prueba, así que asegurémonos de estar en ese directorio
cd /home/courses/student21/Day01/prueba

# Veamos los contenidos de la carpeta:
ls

# Renombraremos el archivo copia_de_documento.txt a copia_de_documento_renombrado.txt
mv copia_de_documento.txt copia_de_documento_renombrado.txt

# Podemos ver el resultado con:
ls
```

---

### 3.2 Comandos `grep`, `echo`, `awk` y `nano`

Ahora veremos unos comandos más avanzados para trabajar con variables y realizar búsquedas en archivos. El comando `grep` es fundamental en sistemas Unix/Linux que significa *Global Regular Expression Print* (Impresión Global de Expresiones Regulares). Su función principal es buscar líneas de texto que coincidan con un patrón específico dentro de uno o varios archivos. Es muy útil para encontrar información específica rápidamente dentro de archivos de registro largos, código fuente o cualquier tipo de texto plano. La sintaxis básica del comando es:

```bash
grep [flags] palabra_que_buscamos nombre_del_archivo
```

En el la línea anterior se muestra el uso de las *flags*, que son distintas opciones o argumentos que contienen instrucciones de cómo (o con qué restricciones) queremos ejecutar el comando. 

Ahora veamos cómo usar `grep` sin *flags* y luego iremos complejizando el comando. Como ya notaron, el `documento.txt` es el libreto de Pulp Fiction (1994) escrito por Quentin Tarantino y Roger Avary, así que ahora usaremos `grep` para buscar dentro del archivo. Intentaremos encontrar las existencias de la palabra **Ezekiel**, que corresponde al inicio de la frase popularizada por Samuel L. Jackson.

```bash
# Primero nos aseguramos de encontrarnos en el directorio Day01
# Reemplacen student21 por su nombre de usuario
cd /home/courses/student21/Day01

# Ahora usemos el comando grep:
grep Ezekiel documento.txt
```

El resultado nos muestra todas las ocurrencias de la palabra `Ezekiel` a lo largo del texto. Además, nos muestra el contenido de toda la línea donde encontró a la palabra de interés. Como se indicó, el comando `grep` se puede complejizar agregando *flags*, ahora veremos cómo podemos buscar la palabra `Ezekiel` y que también nos muestre en qué líneas la encontró:

```bash
grep -n Ezekiel documento.txt
```

También podemos usar otra opciones (o combinaciones de ellas) para obtener más información o información más filtrada a partir del documento.

```bash
# Si queremos que nos muestre todos los match con el número de línea y también las siguientes 4 líneas:
grep -n -A 4 Ezekiel documento.txt

# Si queremos que nos muestre solo el primer match y también las siguientes 4 líneas:
grep -m 1 -A 4 Ezekiel documento.txt 
```

Otra utilidad muy importante de `grep` es que nos permite guardar el resultados de una búsqueda en una **variable** para luego usarla en otro comando (o en otra función), o también guardar el resultado en un archivo. Las variables son un concepto fundamental en programación y en los sistemas operativos. Se pueden visualizar como "cajas" o "contenedores" con nombre, diseñados para almacenar temporalmente un dato o un valor. Ahora veremos como guardar la frase de Samuel L. Jackson (y las siguientes 9 líneas) en una variable que llamaremos `ezekiel`.

```bash
ezekiel=$(grep -m 1 -A 9 Ezekiel documento.txt)
```

---

Si bien ya creamos la variable `ezekiel` con el fragmento del libreto, para poder visualizarla tenemos que usar el comando `echo`. Su función principal es mostrar una línea de texto que se le pasa como argumento en la pantalla (la salida estándar, o *stdout*). En términos sencillos, es el equivalente en la terminal a la función `print()` en la mayoría de los lenguajes de programación. En su forma más simple, solo "imprimirá" en pantalla lo que indiquemos:

```bash
echo "Genética y Genómica de Poblaciones 2026"
```

También podemos usar `echo` para mostrar el valor de variables de entorno. Se usa frecuentemente con el signo de peso (`$`) para mostrar el contenido de variables del sistema o definidas por el usuario. El signo `$` tiene un rol fundamental en la terminal Bash (y otros shells de Linux), y su nombre formal es operador de expansión de variable (*variable expansion operator*). Su función principal es decirle al intérprete de comandos: "No trates esto como texto literal, sino como el nombre de una variable cuyo valor quiero usar".

```bash
echo $USER
echo $HOME
```

Como ya creamos la variable `ezekiel` con el fragmento de la película, ahora podemos verla en pantalla usando `echo`:
```bash
echo $ezekiel
```

Otra utilidad de `echo` es que nos permite escribir texto en un archivo. Usando el operador de redirección (`>`) podemos enviar la salida de `echo` a un archivo, creando el archivo si no existe o sobrescribiéndolo si ya existe.
```bash
echo $ezekiel > ezekiel.txt

# Veamos el resultado usando cat:
cat ezekiel.txt
```

También podemos añadir texto al final de un archivo (*append*) usando el operador de redirección doble (>>). Esto añadirá la línea al final de un archivo existente sin borrar el contenido anterior.
```bash
echo Samuel L. Jackson >> ezekiel.txt

# Veamos el resultado usando cat:
cat ezekiel.txt
```

---
`awk` es una herramienta clásica de Unix/Linux diseñada para el procesamiento de texto estructurado, especialmente archivos organizados en filas y columnas. Su nombre proviene de las iniciales de sus creadores: Alfred Aho, Peter Weinberger y Brian Kernighan, quienes lo desarrollaron en los Bell Labs a fines de los años 70.

Conceptualmente, `awk` funciona leyendo un archivo línea por línea, separando cada línea en campos (por defecto, usando espacios o tabulaciones) y ejecutando acciones sobre esos campos cuando se cumplen ciertas condiciones. Por esta razón, se lo suele describir como un pequeño lenguaje de programación orientado al análisis de texto.

En la práctica, `awk` se utiliza para:
- Extraer columnas específicas de archivos tabulares
- Filtrar líneas según condiciones numéricas o textuales
- Resumir información (conteos, sumas, promedios)
- Reformatear archivos de texto

En genómica y bioinformática, `awk` es especialmente útil porque muchos formatos de datos (VCF, BED, GTF, TSV, outputs de herramientas como samtools) están organizados por columnas. Con `awk` es posible, por ejemplo:
- Contar SNPs o variantes
- Filtrar sitios por cobertura o calidad
- Extraer coordenadas genómicas
- Transformar rápidamente archivos grandes sin necesidad de abrir R o Python

Una de las grandes fortalezas de `awk` es que es rápido, liviano y está disponible prácticamente en cualquier sistema HPC, lo que lo convierte en una herramienta fundamental para flujos de trabajo reproducibles.

Usemos `awk` en el archivo `ezekiel.txt` que creamos en el paso anterior. Sabemos que el texto termina con la línea **Samuel L. Jackson**, así que queremos leer esa última línea, separar sus palabras por espacios y volver a *imprimirla* usando guiones como separador. Podemos hacerlo con el siguiente comando:

```bash
awk 'END { gsub(/ /,"-"); print }' ~/ezekiel.txt
```

En el comando anterior, la función de cada argumento es:

- `awk`: es el programa que ejecuta el intérprete de `awk`. Le indica al sistema que queremos procesar un archivo de texto usando este lenguaje.
- `'END { ... }'`: corresponde al bloque de instrucciones que `awk` debe ejecutar. La palabra clave `END` indica que las instrucciones que están dentro de las llaves se ejecutarán una sola vez, **al final de la lectura del archivo**, es decir, cuando `awk` ya haya procesado todas las líneas. En este ejemplo, esto es lo que nos permite trabajar exclusivamente con la última línea del archivo.
- `{ ... }`: las llaves delimitan las acciones que `awk` debe realizar cuando se cumple la condición asociada (en este caso, llegar al final del archivo).
- `gsub(/ /,"-")`: es una función interna de `awk` que significa *global substitution*. Su función es reemplazar todas las ocurrencias de un patrón por otro dentro de la línea actual. En este caso, todos los espacios de la línea se reemplazan por guiones.
  - `/ /`: indica el patrón a buscar (un espacio en blanco)
  - `"-"`: indica el texto de reemplazo (un guión)
- `print`: imprime en pantalla el contenido de la línea actual, después de haber aplicado la sustitución.
- `~/ezekiel.txt`: es la ruta al archivo de texto que awk va a leer.

En caso que queramos aplicar el mismo flujo, pero en la línea 3 del texto usaríamos:

```bash
awk 'NR==4 { gsub(/ /,"-"); print }' ~/ezekiel.txt
```

Resumen conceptual:
- `awk` lee todo el archivo
- Al llegar a la última línea ejecuta el bloque `END`
- Reemplaza los espacios por guiones
- Imprime el resultado en pantalla

Este patrón (leer → transformar → imprimir) es la base del uso de `awk` en análisis de texto y, por extensión, en flujos de trabajo genómicos.

---
Ya hemos creado un archivo de texto usando `grep` y `echo`, ahora veremos una opción para editarlo usando `nano`. A diferencia de editores gráficos como Visual Studio Code, Sublime Text o el Bloc de notas, `nano` se ejecuta directamente en la terminal, lo cual es esencial en entornos de servidores, sistemas remotos vía SSH o clústeres HPC, donde a menudo no hay una interfaz gráfica disponible. Mediante `nano` podemos crear y editar archivos de texto plano directamente dentro de tu ventana de terminal, navegar por el texto usando las teclas de flecha, guardar cambios en el archivo (`Ctrl + O`), buscar texto en el archivo (`Ctrl + W`), etc. Es popular por su facilidad de uso. A diferencia de editores más potentes pero complejos, `nano` muestra los comandos básicos que puedes usar con `Ctrl + [letra]` en la parte inferior de la pantalla, haciendo que la curva de aprendizaje sea muy baja. Editemos el archivo que creamos:
```bash
nano ezekiel.txt
```

Una vez editado el archivo de texto con `nano`, usando `Ctrl + O` pueden guardar los cambios y con `Ctrl + X` cierran el editor.


También podemos usar `nano` para crear archivos, por lo cual es una herramienta fundamental para crear scripts. La sintaxis es la misma que la anterior, pero debemos indicar el nombre del archivo que queremos crear:
```bash
nano creando_archivos.txt
```

---