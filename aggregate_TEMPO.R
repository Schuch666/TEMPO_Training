library(terra)
# set forlders
input        <- 'G:/TEMPO/DATA/'                # folder with all input data
output       <- 'G:/TEMPO/processed/'           # folder to save the output

# set names for HCHO
name         <- '/product/vertical_column'      # name of the variable, use eva3dm::vars()
prefix       <- 'tempo_hourly_hcho_'            # prefix for output file name
file_pathern <- 'TEMPO_HCHO_L3'                 # unique pattern from TEMPO downloaded files

# set time period to process #### July 01
start        <- as.POSIXct('2024-07-01 00:00:00', tz = 'UTC')
end          <- as.POSIXlt('2024-07-01 23:00:00', tz = 'UTC')

files    <- dir(path = input,pattern = file_pathern,full.names = T) # list of all input files
dir.create(output,showWarnings = FALSE)

read_tempo <- function(file,var,remove_negative = TRUE, verbose = TRUE){
  
  if(verbose)
    cat('reading',var,'from',file,'...\n')
  
  r      <- rast(file, "weight")  # the file must have this variable
  x      <- suppressWarnings( rast(file, var) )
  ext(x) <- ext(r)
  crs(x) <- crs(x)
  x      <- flip(x, "v")
  
  if(remove_negative){
    if(verbose)
      cat('removing negative values\n')
    x[x < 0 ] = NA # Changed this line!!!!!
  }
  return(x)
}

day     = start
one_day = 24 * 60 * 60 

cat('generating a template...\n')

template <- read_tempo(file = files[1],var = name)
template <- c(template,template,template,template,template,template,
              template,template,template,template,template,template,
              template,template,template,template,template,template,
              template,template,template,template,template,template) # 24 layers

while(day <= end){
  cat('list of files for',format(day,format = '%Y-%m-%d'),':\n')
  files_day <- grep(format(day,format = '%Y%m%d'), files, value = T)
  print(files_day)
  
  for(i in 0:23){
    files_hour <- grep(paste0('T',formatC(i,width=2,format="d",flag="0")), 
                       x = files_day,value = T)
    n <- length(files_hour)
    cat('hour',paste0(formatC(i,width=2,format="d",flag="0"),':00:00 UTC'),n,'files\n')
    
    if(n == 0){
      cat('no observations, filling with NA ...\n')
      template[[i+1]][] = NA
    }
    if(n == 1){
      tempo <- read_tempo(file = files_hour,var = name)
      cat('time =',format(terra::time(tempo),format = '%Y-%m-%d %H:%M:%S'),'\n')
      template[[i+1]] = tempo
    }
    if(n > 1){
      tempo <- rast()
      for(f in files_hour){
        tempo <- c(tempo,read_tempo(file = f,var = name),warn=FALSE)
        cat('time =',format(terra::time(tempo),format = '%Y-%m-%d %H:%M:%S'),'\n')
      }
      tempo            <- mean(tempo, na.rm = TRUE)
      units(tempo)     <- units(template[[i+1]])
      names(tempo)     <- names(template[[i+1]])
      longnames(tempo) <- longnames(template[[i+1]])
      varnames(tempo)  <- varnames(template[[i+1]])
      template[[i+1]]  = tempo
    }
  }
  terra::time(template) <- seq(day,day + 23 * 60 * 60, by = 'hour')
  output_name           <- paste0(output,prefix,format(day,format = '%Y-%m-%d'),'.nc')
  
  cat('output file:',output_name,'\n')
  
  writeCDF(x = template, 
           filename = output_name,
           varname = varnames(template), 
           longname=terra::longnames(template),
           unit=terra::units(template),
           overwrite=TRUE)
  
  day = day + one_day
}