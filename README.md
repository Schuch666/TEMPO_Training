# TEMPO Training (2025-01-29)
Wellcome to the TEMPO training, this is the suport document.

## Before start this training you need:

a. Install the R-packgage **eva3dm** (https://github.com/Schuch666/eva3dm?tab=readme-ov-file#instalation)
b. Download the **TEMPO** data (https://search.earthdata.nasa.gov/search?fi=TEMPO&fl=3%2B-%2BGridded%2BObservations)
c. Run the **WRF-Chem** (or get a wrfout file)

## If the content of this training or the **eva3dm** R-Package is used in any conference of any kind of publication, pleace cite the following paper:

**[1]** _Schuch, D., (2025). “eva3dm: A R-package for model evaluation of 3D weather and air quality models.” **Journal of Open Source Software**, 10(108), 7797, [doi:10.21105/joss.07797](https://doi.org/10.21105/joss.07797)_

## 1. Opening and visualizating TEMPO data

There is a example of download script (`download_hchoc_2024-07-01.sh`) and pre-processing script (`aggregate_TEMPO.R`) that can be used as reference. The download script can be obtained in TEMPO download site (https://search.earthdata.nasa.gov/search?fi=TEMPO&fl=3%2B-%2BGridded%2BObservations) and will ask the user credencials and `aggregate_TEMPO.R` read data and agregate in hourly data and the follogins session need to be changed to the correct folder, name of the variables and time period to be processed.

```r # set forlders
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

## 2. Post-processing and visualization of WRF-Chem

Under contruction ...

## 3. Model evaluation

Under construction ...
 
## More information:
**eva3dm** online documentation (https://schuch666.github.io/eva3dm/)

TEMPO site (https://tempo.si.edu/)

WRF-Chem github (https://github.com/wrf-model/WRF)
