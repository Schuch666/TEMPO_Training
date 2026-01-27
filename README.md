# TEMPO Training (2025-01-29)
Wellcome to the TEMPO training, this is the suport document.

## Before start this training you need:

a. Install the R-packgage **eva3dm** (https://github.com/Schuch666/eva3dm?tab=readme-ov-file#instalation)

b. Download the **TEMPO** data from EARTHDATA Search website (https://search.earthdata.nasa.gov/search?fi=TEMPO&fl=3%2B-%2BGridded%2BObservations)

c. Run the **WRF-Chem** (or get wrfout files)

## If the content of this training or the **eva3dm** R-Package is used in any conference of any kind of publication, pleace cite the following paper:

**[1]** _Schuch, D., (2025). “eva3dm: A R-package for model evaluation of 3D weather and air quality models.” **Journal of Open Source Software**, 10(108), 7797, [doi:10.21105/joss.07797](https://doi.org/10.21105/joss.07797)_


## 1. Opening and visualizating TEMPO data

There is a example of download script (`download_hchoc_2024-07-01.sh`) and pre-processing script (`aggregate_TEMPO.R`) that can be used as reference. The download script can be obtained from EARTHDATA Search website (https://search.earthdata.nasa.gov/search?fi=TEMPO&fl=3%2B-%2BGridded%2BObservations) and will ask the user credencials (to create an account use this link https://urs.earthdata.nasa.gov/users/new) and `aggregate_TEMPO.R` read data and agregate in hourly data. Six lines need to be changed: correct folder names, name of the variables and time period to be processed (this process will take a few hours for one month).

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

## 2. Post-processing and visualization of WRF-Chem

The post-processing of WRF outputs are done using R, there is a submission script (submit_column.sh) and a source script (process_form_column.R).

in the source script this lines need to be changed for the variable name, domains and output folder:
```r 
var           <- 'form'
domains       = c('d01','d02','d03')
output_folder <- '/scratch/schuch/WRF-Chem-GHG/WRF/column'
```

## 3. Model evaluation

Under construction ...
 
## More information:
**eva3dm** online documentation (https://schuch666.github.io/eva3dm/)

TEMPO site (https://tempo.si.edu/)

WRF-Chem github (https://github.com/wrf-model/WRF)
