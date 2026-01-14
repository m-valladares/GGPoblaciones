# Flujo Genético y Conectividad Poblacional

El flujo genético es la fuerza microevolutiva que mantiene la cohesión de las especies. A diferencia de la deriva genética, que promueve la divergencia, el intercambio de alelos entre poblaciones tiende a homogeneizar las frecuencias alélicas y a aumentar la diversidad genética local.

En este taller, pasaremos de la teoría de los modelos a la práctica con datos genómicos reales, explorando cómo el movimiento de individuos (o gametos) moldea la arquitectura genética de las poblaciones de estudio.

## 1.1 De la Teoría a los Datos Genómicos

En las sesiones teóricas previas, discutimos modelos clásicos como el modelo de islas de Wright y el modelo de *stepping-stone*. Vimos que, bajo ciertas condiciones, podemos estimar el número de migrantes por generación (**N<sub>e</sub>​M**) a partir del estadístico <b>F<sub>ST</sub></b>​. Sin embargo, en la era de la genómica, tenemos la oportunidad de ir más allá de estas simplificaciones:

- Más allá del equilibrio: Los modelos clásicos suelen asumir un equilibrio entre migración y deriva. Con las herramientas actuales, podemos detectar eventos de flujo genético recientes vs. históricos.
- Direccionalidad: No solo nos interesa saber cuánto flujo hay, sino hacia dónde va (fuentes y sumideros).
- El paisaje como barrera: El flujo genético no ocurre en el vacío; está limitado por la geografía, el ambiente y la ecología de la especie.

## 1.2 Una Aproximación Multi-Herramienta

En bioinformática, no existe una herramienta que sea útil en todos los escenarios para inferir el flujo genético. Cada software utiliza diferentes algoritmos y "sustratos" de información (algunos usan frecuencias alélicas, otros genotipos individuales o matrices de disimilitud).

Para este taller, hemos diseñado un flujo de trabajo que integra tres aproximaciones complementarias. El objetivo es que aprendan a triangular resultados: cuando diferentes métodos con distintas naturalezas de datos coinciden, nuestra hipótesis biológica se robustece.

