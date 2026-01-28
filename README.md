# TEMPO Training (2025-01-29) <img src="FIG/logo_eva3dm.gif" align="right" width="140"/>
Welcome to the TEMPO training, this is the support document for the training.

In this tutorial you will learn:

**i.**  Where to **download TEMPO** data using bash

**ii.** How to **pre-process** TEMPO data using the R-package **terra**

**iii.** How to **post-process** WRF-CHem outputs to performa **satelitte evaluation**

**iv.**  How to **Evaluate** a 3d-air quality model against satellite (or any regular grid data) using **eva3dm**

# If this trainig or **eva3dm** is used in any conference or publication, pleace CITE:

_Schuch, D., (2025). “eva3dm: A R-package for model evaluation of 3D weather and air quality models.” **Journal of Open Source Software**, 10(108), 7797, [doi:10.21105/joss.07797](https://doi.org/10.21105/joss.07797)_

## Before start you need:

**a.** Install the R-packgage **eva3dm** (https://github.com/Schuch666/eva3dm?tab=readme-ov-file#instalation)

**b.** Download the **TEMPO** data from EARTHDATA Search website (https://search.earthdata.nasa.gov/search?fi=TEMPO&fl=3%2B-%2BGridded%2BObservations), it must be L3 data or additional steps (not covered in this totorial) are needed to make L3

**c.** Run the **WRF-Chem** (or get wrfout files)

## 1. Downloading, Pre-Processing, Opening and Visualizating TEMPO data

There is a example of download script (`download_hchoc_2024-07-01.sh`) and pre-processing script (`aggregate_TEMPO.R`) that can be used as reference. The download script can be obtained from EARTHDATA Search website (https://search.earthdata.nasa.gov/search?fi=TEMPO&fl=3%2B-%2BGridded%2BObservations) and will ask the user credencials (to create an account use this link https://urs.earthdata.nasa.gov/users/new) and `aggregate_TEMPO.R` read data and agregate in hourly data. Six lines need to be updated: folder names, name of the variables and time period to be processed (will take a few hours to process for one month of TEMPO L3 data).

```r
# set folders
input        <- 'G:/TEMPO/DATA/'                # folder with all input data
output       <- 'G:/TEMPO/processed/'           # folder to save the output

# set names for HCHO
name         <- '/product/vertical_column'      # name of the variable, use eva3dm::vars()
prefix       <- 'tempo_hourly_hcho_'            # prefix for output file name
file_pathern <- 'TEMPO_HCHO_L3'                 # unique pattern from TEMPO downloaded files

# set time period to process #### July 01
start        <- as.POSIXct('2024-07-01 00:00:00', tz = 'UTC')
end          <- as.POSIXlt('2024-07-01 23:00:00', tz = 'UTC')
```

The output from `aggregate_TEMPO.R`  are hourly data, and it can be avaraged monthly using the `ncea` command:
```sh
ncea tempo_hourly_hcho_2024-07-* tempo_monthly_hcho_2024-07.nc
```

To start to work with the TEMPO processed files


```r
library(terra)
library(eva3dm)

tempo     <- rast('processed/tempo_monthly_hcho_2024-07.nc')
scale     <- 1e-16  # scale
tempo     <- tempo[[c(13:24)]]  # select only the times with observation, is faster!
tempo     <- scale * mean(tempo, na.rm = TRUE)

coast       <- terra::vect(paste0(system.file("extdata",package="eva3dm"),"/coast.shp"))
US          <- terra::vect(paste0(system.file("extdata",package="eva3dm"),"/US.shp"))

new_color  <- colorRampPalette(c(
  "#00ffff",  # Cyan
  "#04befe",  # Light blue
  "#68f096",  # Greenish
  "#f3fe02",  # Yellow
  "#ff9a00",  # Orange
  "#ff4f00",  # Orange-red
  "#c61a00",  # Dark red
  "#a00000",  # Deeper red
  "#600000"   # Very dark red
))

plot_rast(tempo, main = "TEMPO 1e-16 HCHO (2024-07)", color = new_color(100),range = c(0,10))
terra::lines(US, col = 'white')
terra::lines(coast, col = 'black')
terra::add_box()

```
![*Figure 1* - TEMPO HCHO for 2023-07.](https://raw.githubusercontent.com/schuch666/TEMPO_training/master/FIG/tempo_hcho_2024-07.png)

## 2. Post-Processing and Visualization of WRF-Chem

The post-processing of WRF outputs are done using R, there is a submission script (`submit_column.sh`) and a source script (`process_form_column.R`).

In the source script this lines need to be changed for the variable name, domains and output folder:
```r 
var           <- 'form'
domains       = c('d01','d02','d03')
output_folder <- '/scratch/schuch/WRF-Chem-GHG/WRF/column'
```
This script uses the `calculate_column()` function from eva3dm R-package to integrate vertically the column concentrations from WRF output for each hour of WRF-Chem output (https://schuch666.github.io/eva3dm/reference/calculate_column.html).

The output can be visualized using `terra::plot()` or `eva3dm::plot_rast()`

```r
# to catch the file names
files_form <- dir(path = 'WRF/column/', pattern = 'column_form', full.names = TRUE)
files_form <- grep('2024-01', files_form, value = TRUE)
files_form <- grep('12h|13h|14h|15h|16h|17h|18h|19h|20h|21h|22h|23h',files_form, value = TRUE)

# open all d01 files
model_d01 <- rast(grep('d01',files_form, value = TRUE))
# avarage and use the same scale number used for TEMPO
model_d01 <- scale * mean(model_d01, na.rm = TRUE)

# to plot maps the lines must be in the same coordinade system
coast_d01   <- project(coast, model_d01)    # this is diff. for each domain
US_d01      <- project(US,model_d01)        # this is diff. for each domain

fig_unit  = paste0(scale,'\nmolecules\ncm-2')

plot_rast(model_d01,
          main = paste0('HCHO - WRF-Chem-GHG d01 (avarage for 2024-07-01)'),unit = fig_unit,plg = list(tic = "none", shrink = 0.97),
          grid = T,grid_col = 'black', color = new_color(100),range = c(0,2))
terra::lines(US_d01, col = 'white')
terra::lines(coast_d01, col = 'white')
legend_range(model_d01,show.mean = F)

```

![*Figure 2* - TEMPO HCHO for 2023-07.](https://raw.githubusercontent.com/schuch666/TEMPO_training/master/FIG/WRF-Chem-GHG_hcho-2024-07-01.png)


## 3. Model Evaluation using Satellite data from TEMPO

The evaluation itself is very simple, but require the code and outputs from previsous steps, the function `sat()` is used to evaluate two `SpatRaster` (obeject from the `terra` R-package) and include:
- remove 6 points close to the model lateral boundary
- reproject and interpolate the observations to the model projection and resolution
- pairing of the data of each layer (the arguments *mo* and *ob* should have the same number of time-steps, or `SpatRaster` layers) and perform the calculation of metrics (from `eva3dm::stat()`, `eva3dm::cate()`, or any other function).
- other options can be explored using the function arguments: n, min, max, scale, method, eval_function, mask and skip_inter. See https://schuch666.github.io/eva3dm/reference/sat.html.

```r
# for statistical metrics
table1 <- sat(mo = model_d01, ob = tempo,rname = 'hcho_statistic')
print(table1)

# for categorical metrics
table2 <- sat(mo = model_d01, ob = tempo,rname = 'hcho_categoric',eval_function = cate,threshold = 0.15,verbose = FALSE)
print(table2)

# to save in a .csv
write_stat(stat = table1, file = 'table1.csv')
write_stat(stat = table2, file = 'table2.csv')
```
The output:
```r
removing 6 points for the model (mo) lateral boundaryes ...
interpolating obsservation (ob) to model grid (mo) ...

                   n      Obs       Sim          r       IOA          FA2     RMSE        MB       ME   NMB (%)  NME (%)
hcho_statistic 39380 1.505612 0.2083641 0.08193024 0.2941764 0.0003047232 1.987868 -1.297248 1.297248 -86.16084 86.16084

                   n      Obs       Sim  thr        A      CSI      POD        B FAR HSS PSS
hcho_categoric 39380 1.505612 0.2083641 0.15 79.21788 79.21788 79.21788 79.21788   0   0   0
```
Note that this results are not meaninful but ilustrate each of the steps needed to use **eva3dm** to evaluate **WRF-Chem model** against **TEMPO data**. 

Also, there is a good amount of choices in each evaluation: for example, the **time interval** that will be averaged, selection of the **specific hours**, there is a need to **select the region** or even **new metrics** need to be applied.

**Have fun!**

## More information:
**eva3dm** online documentation (https://schuch666.github.io/eva3dm/)

TEMPO site (https://tempo.si.edu/)

WRF-Chem github (https://github.com/wrf-model/WRF)
