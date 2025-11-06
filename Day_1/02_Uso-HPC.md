# Introducción a la línea de comandos y uso del HPC (NLHPC)

El objetivo de esta sesión es familiarizar a las y los participantes con el entorno de trabajo en sistemas Linux y en el clúster del NLHPC (Leftraru), utilizando la línea de comandos, Visual Studio Code y R/RStudio como herramientas integradas para reproducir análisis de genómica de poblaciones.

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

