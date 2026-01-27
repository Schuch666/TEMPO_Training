library(eva3dm)
library(terra)

var           <- 'form'
domains       = c('d01','d02','d03')
output_folder <- '/scratch/schuch/WRF-Chem-GHG/WRF/column'
dir.create(output_folder,showWarnings = F)
use_du        = ifelse(var == 'o3',TRUE,FALSE)

for(domain in domains){
  input_folder <- paste0('/scratch/schuch/WRF-Chem-GHG/WRF/wrf_',domain)
  input_files  <- dir(path = input_folder, pattern = 'wrfout')

  for(input_file in input_files){
    column_con  <- calculate_column(paste0(input_folder,'/',input_file),var, DU = use_du,flip_v = T,flip_h = T)

    output_file <- paste0( 'column_',var,'_',domain,'_',substr(input_file,start = 12, stop = 24),'h.nc')
    cat('output:',paste0(output_folder,'/',output_file),'\n')
    writeCDF(column_con,
             paste0(output_folder,'/',output_file),
             unit=units(column_con),
             varname=names(column_con),
             longname=paste0('column concentration of ',var),
             overwrite=TRUE)
    cat('\n')
  }
}
