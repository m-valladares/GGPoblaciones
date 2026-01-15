rm(list=ls())

## install.packages(c("sp", "raster", "Rcpp", "RcppEigen", "devtools", "rworldmap","rworldxtra"))
## devtools::install_github("dipetkov/eems/plotting/rEEMSplots", ref = "master")

## Grafico EEMS
## Los tildes fueron omitidos intencionalmente

## Cargar librerias
library(rEEMSplots)

## Cambiar de directorio de trabajo a la carpeta con los resultados

## Leer los datos
mcmcpath <- getwd()
plotpath <- "./mapas_eems"
coord_proj <- "+proj=longlat +datum=WGS84"

## Crear grafico
eems.plots(mcmcpath, plotpath, 
           longlat = TRUE, 
           add.map = TRUE, 
           projection.in = coord_proj,
           projection.out = coord_proj)
