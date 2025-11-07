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

El uso exclusivo de la terminal (*Command-Line Interface*, CLI) puede ser un obstáculo para los estudiantes que están iniciando análisis genómicos. Trabajar directamente con `bash` requiere memorización de comandos, manejo de permisos, y una curva de aprendizaje pronunciada para tareas básicas como la navegación de archivos (`cd`, `ls`) y la edición de texto (`nano`). Es una experiencia similar a usar el lenguaje de programación `R` puro frente a **RStudio**. RStudio proporciona una interfaz gráfica integrada (*Integrated Development Environment*, IDE) que facilita la gestión de proyectos, visualización de datos, autocompletado de código y depuración, haciendo que la entrada al análisis estadístico sea mucho más amigable. Mientras que el uso de `R` en línea de comandos es potente pero menos intuitivo para el aprendizaje inicial. 

Es por lo anterior que en curso usaremos **Visual Studio Code**, ya que proporciona un puente GUI (*Graphical User Interface*) que suaviza la transición al entorno de servidor de HPC. Visual Studio Code (VSC o VS Code) es un editor de código fuente gratuito, ligero y multiplataforma desarrollado por Microsoft. Entre las características de VSC destacan:

- Editor multiplataforma y liviano con soporte para **bash**, **R**, **Python**, **Markdown** y **Git**.
- Permite trabajar remotamente mediante **SSH** y editar código directamente en el HPC.
- Terminal integrada que facilita el uso de la línea de comandos.

**Comentario 1:** usar VSC no reemplaza la necesidad de **entender los comandos de Linux** (`grep`, `nano`, `sbatch`), pero sí que minimiza las barreras de entrada al proporcionar un entorno visual familiar y centralizado.

**Comentario 2:** un inconveniente de VSC es que crea múltiples directorios y archivos que utilizan recursos y memoria (**7 - 10 GB**) del usuario, lo que disminuye el almacenamiento disponible para datos.

### 5.1 Opciones a Visual Studio Code

Como se indicó, VSC puede utilizar varios GB de almacenamiento en sus cuentas solo para funcionar. Así que recomendamos otras aplicaciones que funcionan de forma similar a VSC. Cabe mencionar que son aplicaciones más ligeras, lo que es favorable, sin embargo, no tienen todas las prestaciones que dispone VSC. De todos modos, para los objetivos del curso, las siguientes opciones funcionarían sin mayores problemas.

1. [**MobaXterm**](https://mobaxterm.mobatek.net/)
- Sistema operativo: solo para Windows.
- Descripción: MobaXterm combina en una sola herramienta una terminal UNIX, un cliente SSH y un entorno gráfico remoto (X11), ideal para conectarse a servidores HPC.
- Ventajas:
   - Incluye soporte nativo para SSH, SFTP y X11 (interfaz gráfica remota).
   - Permite **ver y transferir archivos** del servidor en una ventana lateral.
   - No requiere instalación de software adicional.
- Desventajas:
   - Solo disponible en Windows (aunque puede ejecutarse en macOS/Linux mediante emuladores).
   - La versión gratuita tiene algunas limitaciones (ninguna que afecte el desarrollo del curso).

2. [**Termius**](https://termius.com/)
- Sistema operativo: multiplataforma (Windows, macOS, Linux, Android, iOS).
- Descripción: Cliente SSH moderno y limpio, enfocado en la conexión y gestión de servidores remotos. Cuenta con versiones móviles que permiten cargar una terminal.
- Ventajas:
   - Permite **ver y transferir archivos** del servidor.
   - Sincroniza conexiones entre dispositivos (opcional).
   - Permite guardar credenciales y claves SSH de forma segura.
- Desventajas:
   - No incluye un editor de texto integrado tan completo como VSC.
   - Algunas funciones avanzadas (sincronización, snippets, grupos) requieren la versión de pago.

3. [**FileZilla**](https://filezilla-project.org/)
- Sistema operativo: multiplataforma (Windows, macOS, Linux).
- Descripción: Cliente FTP/SFTP ampliamente usado para transferir archivos entre el computador local y el servidor. FileZilla no contiene un cliente SSH, es decir, no se puede acceder mediante terminal integrada al clúster. Esta aplicación está enfocada en la transferencia de archivos.
- Ventajas:
   - Ideal para subir y descargar archivos grandes entre el equipo y el HPC.
   - Interfaz simple, *drag-and-drop*, sin necesidad de comandos.
   - Gratuito y de código abierto.
- Desventajas:
   - Solo gestiona archivos (no permite ejecutar comandos ni editar scripts directamente).
   - No incluye terminal ni integración con entornos de desarrollo.

4. [**PuTTY**](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)
- Sistema operativo: principalmente Windows (disponible también para Linux/macOS).
- Descripción: Uno de los clientes SSH más antiguos y confiables, permite conectarse a servidores remotos de forma segura. El NLHPC recomienda usar PuTTy para conectarse al clúster Leftraru-Guacolda Epu.
- Ventajas:
   - Ligero, rápido y muy estable.
   - Ideal para conexiones rápidas o para quienes prefieren una terminal simple.
   - Permite guardar sesiones y usar claves SSH.
- Desventajas:
   - Interfaz muy básica (sin autocompletado ni gestión de archivos).
   - No incluye editor de texto ni herramientas integradas (como VSC o MobaXterm).

### 5.2 Pasos básicos de configuración de VSC

1. Instalar [Visual Studio Code](https://code.visualstudio.com/) acorde al sistema operativo.

2. Abrir VSC e instalar la extensión **Remote - SSH**, que permitirá conectarse al servidor. SSH significa "Secure Shell" (Shell Seguro). Es un protocolo de red criptográfico que permite a los usuarios acceder y controlar un servidor o computadora remota de forma segura a través de una red insegura (como Internet). La función principal de SSH es establecer una conexión cifrada entre dos máquinas: una computadora local (el cliente SSH) y la máquina remota (el servidor SSH). 

3. Conectarse al NLHPC: en caso que ya hayan modificado el archivo `~/.ssh/config` para conectarse al clúster siguiendo las instrucciones de la [Wiki del NLHPC](https://wiki.nlhpc.cl/Tutorial_de_acceso_a_Leftraru_via_SSH), VSC reconocerá la cuenta como un host conocido (opción `Connect to host`).
   - Si no lo han hecho deben seguir las instruciones detallas en la página de [VSC](https://code.visualstudio.com/docs/remote/ssh).
   - A continuación se muestra la opción para conectarse a través de la terminal integrada en VSC:
   ```bash
   # Reemplacen student21 por su nombre de usuario
   ssh -p 4603 student21@leftraru.nlhpc.cl
   ```

4. (Opcional) Configurar el archivo `~/.ssh/config` para evitar escribir la contraseña:
   ```bash
   Host leftraru
       HostName leftraru.nlhpc.cl
       Port 4603
       User student21
   ```

5. Si realizaron exitosamente la instalación de VSC y el acceso mediante SSH al clúster del NLHPC, podrán abrir carpetas remotas y usar el terminal integrado para ejecutar comandos.

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
- Verificar acceso al clúster: el resto de los días del curso correremos continuamente análisis en el clúster del NLHPC, así que que les solicitamos que se cercioren que tiene acceso. El uso de VSC no es obligatorio, pero sí es recomendable para agilizar el desarrollo de los talleres. Por ende, si no pudieron vincularlo al clúster de todos modos podrán realizar los talleres, pero es recomendable que lo instalen.

