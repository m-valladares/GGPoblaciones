# Introducción a la línea de comandos y uso del HPC (NLHPC)

El objetivo de esta sesión es familiarizar a las y los participantes con el entorno de trabajo en sistemas Linux y en el clúster del NLHPC (Leftraru), utilizando la línea de comandos, Visual Studio Code y R/RStudio como herramientas integradas para reproducir análisis de genómica de poblaciones.

---

## 4. Scripts y automatización

Ahora que ya aprendimos a correr comandos básicos como `squeue`, `grep` o `nano`, podemos unirlos secuencialmente o que interactúen entre sí mediante un **script**. Un script es un archivo de texto que contiene una secuencia de comandos o instrucciones diseñadas para ser ejecutadas por otro programa (usualmente un intérprete, en nuestro caso **Bash**). Podemos pensar en un script como una receta o una lista de tareas que el computador seguirá paso a paso, de principio a fin, sin intervención nuestra una vez que se inicia (i.e. no es interactivo).

¿Qué nos permiten los scripts?
- Automatización: su propósito principal es automatizar tareas repetitivas. En lugar de escribir 20 comandos manualmente en la terminal, los podemos incluir todos en un script y ejecutar el script una sola vez.
- Secuencia lógica: los scripts pueden incluir lógica básica (si esto sucede, haz A; si no, haz B), lo que les otorga más poder que una simple lista de comandos.

¿Qué es un script Bash?
Un script Bash es un tipo específico de script diseñado para ser ejecutado por el intérprete de comandos Bash (*Bourne Again Shell*), que es el programa (*shell*) estándar en la mayoría de los sistemas Linux, macOS y entornos como WSL en Windows. En entornos HPC, los scripts Bash son fundamentales, ya que son el medio principal para interactuar con el gestor de recursos (**SLURM**) mediante comandos como `sbatch`, `srun`, y para orquestar las tareas de cómputo complejas.

Características clave de un script Bash:
- Extensión: suelen tener la extensión `.sh` (aunque no es estrictamente obligatoria).
- Línea *shebang*: casi siempre comienzan con una línea especial llamada *shebang*: `#!/bin/bash`. Esta línea le indica al sistema operativo qué programa debe usar para interpretar los comandos del archivo. En este caso le indicamos que use el programa Bash.
- Comandos estándar: contienen los mismos comandos que se usan en la terminal y que ya vimos (`ls`, `grep`, `cp`, `mv`, `echo`, etc.), pero organizados en un archivo.
- Variables y lógica: utilizan variables (`$USER`, `$PATH`) y estructuras de control (bucles `for`, condicionales `if/else`).

### 4.1 Estructura básica de un script Bash

Como se mencionó en la sección anterior, los scripts son archivos de texto, por lo que debemos crearlo usando `nano` y guardarlo en algún directorio de nuestra cuenta. Primero revisemos si estamos en el directorio correcto y ejecutemos el editor `nano`.
```bash
# Primero nos aseguramos de encontrarnos en el directorio day_1
# Reemplacen student21 por su nombre de usuario
cd /home/courses/student21/day_1

# Ahora ejecutamos nano y crearemos el script que llamaremos test.sh
nano test.sh
```

Al lanzar `nano`, se abre el editor de texto y podemos escribir nuestro script. A continuación se muestra un script básico que usa las funciones que ya vimos `echo` y `ls`, podemos copiar todo el texto y pegarlo en `nano`. Recuerden que una vez copiado el script, usando `Ctrl + O` pueden guardar los cambios y con `Ctrl + X` cierran el editor.
```bash
#!/bin/bash
echo "Hola, este es mi script de prueba."
ls -lh 
echo "Fin del script."
```

En el script de arriba, la primera línea `#!/bin/bash` es la línea *shebang* que le dice al sistema operativo que use el intérprete `bash` para ejecutar los comandos del archivo (es estándar en casi todos los scripts Bash); la segunda línea `echo "Hola, este es mi script de prueba."` mostrará en la terminal la frase entre comillas cuando se ejecute el script; la tercera línea `ls -lh` correrá la función `ls` para listar los elementos en la carpeta donde se encuentra el script; y la cuarta línea `echo "Fin del script."` mostrará el texto entre comillas en la terminal. Cada uno de estos pasos se correrá de forma secuencial de acuerdo al orden de las líneas en el script.

Para correr el script usaremos el comando `bash`
```bash
bash test.sh
```

**Permisos de ejecución:** si el script no corre, usualmente se debe a que necesita permiso de ejecución. Esto usualmente sucede cuando se intenta correr un script desde otra carpeta usando la ruta completa (no es nuestro caso). Entonces, antes de intentar correr un script, nos debemos asegurar de que tu usuario tiene permiso para ejecutarlo. Si no lo tiene, se usa el comando `chmod`:
```bash
chmod +x test.sh
```

Un script un poco más complejo se puede construir usando bucles mediante el comando `for` (análogo a los *loops* en `R`). Antes de ver el script, recuerden crearlo usando `nano`, lo llamaremos `test2.sh`.
```bash
#!/bin/bash
echo "Ejemplo de un loop en bash"
for i in {1..5}; do
  echo "Iteración $i"
done
```

En la siguiente tabla se muestra la explicación de cada línea del script anterior:

| Línea | Código | Explicación |
|:------|:-------|:------------|
| 1 | `#!/usr/bin/env bash` | *Shebang*: esta es la línea que le dice al sistema operativo que use el intérprete bash para ejecutar los comandos del archivo. |
| 2 | `echo "Ejemplo de un loop en bash"` | Muestra el texto "Ejemplo de un loop en bash" en la terminal cuando se ejecute el script. |
| 3 | `for i in {1..5}; do` | Inicio del bucle `for`: inicia un loop que iterará cinco veces. Define una variable temporal llamada `i` que tomará secuencialmente los valores 1, 2, 3, 4 y 5. La palabra clave `do` indica el inicio de las acciones que se repetirán en cada iteración. |
| 4 | `echo "Iteración $i"` | Acción del bucle: en cada repetición, este comando `echo` mostrará en pantalla la palabra "Iteración" seguida del valor actual de la variable `i` (que se accede usando `$i`). |
| 5 | `done` | Fin del bucle `for`: indica que el bucle ha terminado y que el script debe continuar después de esta línea, o finalizar si no hay más comandos. |


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

