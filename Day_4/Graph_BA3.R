rm(list=ls())

## install.packages(c("circlize", "tidyverse"))

## Grafico BayesAss
## Los tildes fueron omitidos intencionalmente

## Cargar librerias
library(circlize)
library(tidyverse)

## Datos (matriz de BA3)
baysass = tibble(
  Region = c("Quellón", "Quillota", "Talca"),
  Pop01 = c(0.8972, 0.0260, 0.0254), 
  Pop02 = c(0.0257, 0.9221, 0.0253), 
  Pop03 = c(0.0771, 0.0519, 0.9492)
)

baysass.mat = as.matrix(baysass[, 2:4])
dimnames(baysass.mat) = list(source = baysass$Region, sink = baysass$Region)
cols = c("#d7191c", "#fdae61", "#ffffbf")

## Configuración
circos.clear()
circos.par(start.degree = 90, gap.degree = 10)

## Dibujar el Diagrama Base
chordDiagram(
  x = baysass.mat, 
  grid.col = cols, 
  grid.border = "black", 
  transparency = 0.3,
  order = baysass$Region, 
  directional = 1,
  direction.type = "arrows",
  self.link = 1,
  preAllocateTracks = list(track.height = 0.15), 
  annotationTrack = "grid", 
  annotationTrackHeight = c(0.08, 0.08),
  link.border = "grey30", 
  link.sort = TRUE, 
  link.decreasing = TRUE,
  link.arr.length = 0.15, 
  link.arr.lty = 1, 
  link.arr.col = "black", 
  link.largest.ontop = FALSE
)

## Agregar etiquetas de población y valor de AUTO-RECLUTAMIENTO
circos.trackPlotRegion(
  track.index = 1, 
  bg.border = NA, 
  panel.fun = function(x, y) {
    xlim = get.cell.meta.data("xlim")
    sector.index = get.cell.meta.data("sector.index")
    
    ## Valor de auto-reclutamiento
    val_self = baysass.mat[sector.index, sector.index]
    label_self = paste0(round(val_self * 100, 1), "%")
    
    theta = circlize(mean(xlim), 1)[1, 1] %% 360
    dd = ifelse(theta < 180 || theta > 360, "bending.inside", "bending.outside")
    
    ## Nombre de la poblacion
    circos.text(x = mean(xlim), y = 0.8, labels = sector.index, 
                facing = dd, niceFacing = TRUE, cex = 1.2, font = 2)
    
    ## Valor auto-reclutamiento (posicionado justo abajo)
    circos.text(x = mean(xlim), y = 0.2, labels = label_self, 
                facing = dd, niceFacing = TRUE, cex = 0.9)
  }
)
