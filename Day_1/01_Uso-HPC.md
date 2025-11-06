# Introducción a la línea de comandos y uso del HPC (NLHPC)

El objetivo de esta sesión es familiarizar a las y los participantes con el entorno de trabajo en sistemas Linux y en el clúster del NLHPC (Leftraru), utilizando la línea de comandos, Visual Studio Code y R/RStudio como herramientas integradas para reproducir análisis de genómica de poblaciones.

---

## 1. Presentación

- Presentación del curso y de los instructores.
- Por qué usamos HPC en genómica: volumen de datos, complejidad computacional y reproducibilidad.
- Breve repaso: ¿Qué es un lenguaje de programación?  
  Ejemplos: **bash**, **Python**, **R**.
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
- Tutorial específico de acceso a Leftraru (SSH): [https://wiki.nlhpc.cl/Tutorial_de_acceso_a_Leftraru_via_SSH](https://wiki.nlhpc.cl/Tutorial_de_acceso_a_Leftraru_via_SSH)

**Arquitectura general del sistema:**
```
Usuario local (student21) ──▶ Nodo de acceso (login) ──▶ SLURM scheduler ──▶ Nodos de cómputo
```

### 2.3 Cuentas personales para el curso

El NLHPC nos ha facilitado cuentas para todas/os los estudiantes del curso, a continuación se indica la asignación de usuarios. Antes del comienzo del curso les enviaremos por correo las contraseñas para que puedan acceder al clúster. La mayoría de los datos y entornos de trabajo ya han sido instalados en sus cuentas, de esta forma agilizaremos el trabajo. Estas cuentas son personales e intransferibles, además son temporales y serán desactivadas una vez que termine el curso.

| Nombre Estudiante | Usuario asignado |
|:---------------:|:---------------:|
| Moisés V.  | student01  |
| Pamela M.  | student02  |
| Paulo Z.   | student03  |
| ...  | student04  |
| ...  | student05  |
| ...  | student06  |

---

## 3. Primeros pasos en la línea de comandos

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

A continuación se muestran algunos comandos clásicos para renombrar o copiar elementos. Para usarlos es necesario tener un elemento, objeto o documento de interés. En la carpeta `day01` incluimos un archivo de prueba llamado `documento.txt` para probar estos comandos.

```bash
head documento.txt      # muestra las primeras 10 líneas del archivo
tail documento.txt      # muestra las últimas 10 líneas del archivo
cat documento.txt       # muestra el contenido completo del archivo
wc documento.txt        # muestra la cantidad de líneas, palabras y bytes del archivo
wc -l documento.txt     # muestra solo la cantidad de líneas del archivo
```

---

### 3.2 Comandos `cp` y `mv`

Para copiar en el mismo u otro directorio un archivo, usamos el comando `cp`. Este comando necesita al menos dos argumentos: el origen (lo que quieres copiar) y el destino (dónde quieres poner la copia y con qué nombre).

- Para copiar y pegar el archivo en el mismo directorio con otro nombre (i.e. duplicar el archivo):
```bash
cp documento.txt copia_de_documento.txt
```

Antes de continuar usando `cp`, creamos un directorio llamado `prueba` donde copiaremos y moveremos nuestro `documento.txt`.
```bash
# Primero nos aseguramos de encontrarnos en el directorio day_1
# Reemplacen student21 por su nombre de usuario
cd /home/courses/student21/day_1

# Nos aseguramos de la ruta en la que estamos usando:
pwd

# Ahora crearemos el directorio dentro de day_1 (será una subcarpeta)
mkdir prueba

# Confirmamos que creamos la carpeta usando:
ls
```

- Para copiar el documento y pegarlo en otro directorio manteniendo el nombre. En este caso lo pegaremos en el directorio que creamos en el paso anterior.
```bash
# Reemplacen student21 por su nombre de usuario
cp documento.txt /home/courses/student21/day_1/prueba/
```
- Para copiar el documento y pegarlo en otro directorio **cambiando** el nombre.
```bash
# Reemplacen student21 por su nombre de usuario
cp documento.txt /home/courses/student21/day_1/prueba/copia_de_documento_otro_directorio.txt
```
- Opción recursiva `-r` o `-R`: esta opción es obligatoria si queremos copiar un directorio completo (carpetas y todo su contenido).
```bash
# Por ahora no correremos este comando
# Reemplacen student21 por su nombre de usuario
# cp -r /home/courses/student21/day01/ /home/courses/student21/day02/
```

Para mover y renombrar archivos, usamos el comando `mv`. Este comando también necesita al menos dos argumentos.

- La función principal de `mv` es trasladar un archivo o directorio de una ubicación a otra. El archivo original desaparece de su ubicación anterior y aparece en la nueva.
```bash
mv copia_de_documento.txt /home/courses/student21/day_1/prueba/
```

También podemos usar `mv` para renombrar archivos o directorios. Si el destino especificado es un nuevo nombre dentro del mismo directorio, el comando funciona como un renombrador. En sistemas Linux/Unix, renombrar un archivo es conceptualmente lo mismo que "moverlo" a un nombre de archivo diferente en la misma ubicación.
```bash
# Haremos estos cambios en los documentos de la carpeta prueba, así que asegurémonos de estar en ese directorio
cd /home/courses/student21/day_1/prueba

# Veamos los contenidos de la carpeta:
ls

# Renombraremos el archivo copia_de_documento.txt a copia_de_documento_renombrado.txt
mv copia_de_documento.txt copia_de_documento_renombrado.txt

# Podemos ver el resultado con:
ls
```

---

### 3.2 Comandos `grep`, `echo` y `nano`

grep -m 1 -A 4 Ezekiel Archivo.txt 
grep -n -A 4 Ezekiel Archivo.txt

echo

nano

### 3.2 Compresión y permisos
```bash
tar -czf datos.tar.gz carpeta/   # comprimir
chmod +x script.sh               # dar permiso de ejecución
```

### 3.3 Redirecciones y ejecución en background
```bash
comando > salida.txt     # guardar salida
comando >> salida.txt    # agregar al final
comando &                # ejecutar en segundo plano
```

---

## 4. Scripts y automatización

### 4.1 Estructura básica de un script Bash
```bash
#!/usr/bin/env bash
echo "Ejemplo de script en bash"
for i in {1..3}; do
  echo "Iteración $i"
done
```

### 4.2 Mini-ejercicio
- Crear un script que liste archivos `.fastq.gz` dentro de `RAW/` y los copie a `CLEAN/`.

---

## 5. Introducción a Visual Studio Code (VSC)

### 5.1 Por qué usar VSC en el curso
- Editor multiplataforma y liviano con soporte para **bash**, **R**, **Python**, **Markdown** y **Git**.
- Permite trabajar remotamente mediante **SSH** y editar código directamente en el HPC.
- Terminal integrada que facilita el uso de la línea de comandos.

### 5.2 Pasos básicos de configuración
1. Instalar [Visual Studio Code](https://code.visualstudio.com/).
2. Instalar la extensión **Remote - SSH**.
3. Conectarse al NLHPC:  
   Ejemplo de conexión:
   ```bash
   ssh -p 4603 student21@leftraru.nlhpc.cl
   ```
4. (Opcional) Configurar el archivo `~/.ssh/config` para evitar escribir la contraseña:
   ```bash
   Host leftraru
       HostName leftraru.nlhpc.cl
       Port 4603
       User student21
   ```
5. Abrir carpetas remotas y usar el terminal integrado para ejecutar comandos.

---

## 6. Introducción a SLURM

### 6.1 Comandos básicos
```bash
squeue          # ver trabajos en cola
sinfo           # ver particiones
sbatch script.sbatch   # enviar trabajo
scancel JOBID   # cancelar trabajo
sacct           # ver historial de jobs
```

### 6.2 Ejemplo de script SLURM
```bash
#!/usr/bin/env bash
#SBATCH -J test_job
#SBATCH -c 2
#SBATCH --mem=2G
#SBATCH -t 00:05:00
#SBATCH -o test_%j.out
#SBATCH -e test_%j.err

echo "Ejecutando en $(hostname)"
sleep 60
echo "Job completado"
```

### 6.3 Mini-ejercicio
- Enviar el script anterior y revisar el estado con `squeue`.
- Leer los archivos `test_XXXX.out` y `test_XXXX.err`.

---

## 7. R y RStudio en el HPC

### 7.1 Por qué usamos R
- Lenguaje principal para análisis estadístico, genómico y visualización.
- Durante el curso se usará para PCA, FST, SFS y análisis poblacionales.

### 7.2 Opciones de uso en el HPC
1. **R en terminal:**
   ```bash
   module load R/4.3.1
   R
   ```
2. **Ejecución de scripts:**
   ```bash
   Rscript analisis.R
   ```
3. **Ejemplo SLURM + R:**
   ```bash
   #!/usr/bin/env bash
   #SBATCH -J r_test
   #SBATCH -c 4
   #SBATCH --mem=8G
   #SBATCH -t 00:10:00
   module load R/4.3.1
   Rscript test_script.R
   ```
4. **RStudio Server o VSC:** si está disponible, permite editar y correr código R gráficamente.

### 7.3 Ejemplo simple de script R
```r
# test_script.R
x <- 1:10
y <- x^2
pdf("plot.pdf")
plot(x, y, type="b", col="blue", pch=19, main="Prueba en HPC")
dev.off()
```

---

## 8. Ejercicios prácticos sugeridos
1. Crear una carpeta de proyecto con subdirectorios: `RAW`, `CLEAN`, `MAP`, `SCRIPTS`, `LOGS`.
2. Crear un script bash que copie archivos de un directorio a otro.
3. Enviar un trabajo de prueba con SLURM y verificar la salida.
4. Ejecutar un script de R en el clúster.

---

## 9. Recursos adicionales
- Wiki NLHPC: [https://wiki.nlhpc.cl/P%C3%A1gina_principal](https://wiki.nlhpc.cl/P%C3%A1gina_principal)
- Tutorial de acceso SSH: [https://wiki.nlhpc.cl/Tutorial_de_acceso_a_Leftraru_via_SSH](https://wiki.nlhpc.cl/Tutorial_de_acceso_a_Leftraru_via_SSH)
- Guía rápida de SLURM: [https://slurm.schedmd.com/quickstart.html](https://slurm.schedmd.com/quickstart.html)
- Cheatsheet de Bash: [https://devhints.io/bash](https://devhints.io/bash)

---

**Tarea para el Día 2:**
- Verificar acceso al clúster.
- Crear su carpeta de trabajo.
- Probar un script bash y un job SLURM.
- Confirmar ejecución exitosa de un script R en el HPC.

