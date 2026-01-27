setwd('E:/Globus/TEMPO Training files/')

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

# png(filename = 'tempo_hcho_2024-07.png',
#     width = 1000,
#     height = 700,
#     pointsize = 22)

plot_rast(tempo, main = "TEMPO 1e-16 HCHO (2024-07)", color = new_color(100),range = c(0,10))
terra::lines(US, col = 'white')
terra::lines(coast, col = 'black')
terra::add_box()

# dev.off()

files_form <- dir(path = 'WRF/column/', pattern = 'column_form', full.names = TRUE)
files_form <- grep('2024-01', files_form, value = TRUE)
files_form <- grep('12h|13h|14h|15h|16h|17h|18h|19h|20h|21h|22h|23h',files_form, value = TRUE) # for JAN

model_d01 <- rast(grep('d01',files_form, value = TRUE))
model_d01 <- scale * mean(model_d01, na.rm = TRUE)

coast_d01   <- project(coast, model_d01) # diff for each domain
US_d01      <- project(US,model_d01)     # diff for each domain

fig_unit  = paste0(scale,'\nmolecules\ncm-2')

# png(filename = 'WRF-Chem-GHG_hcho-2024-07-01.png',
#     width = 1000,
#     height = 1000,
#     pointsize = 22)

plot_rast(model_d01,
          main = paste0('HCHO - WRF-Chem-GHG d01 (avarage for 2024-07-01)'),unit = fig_unit,plg = list(tic = "none", shrink = 0.97),
          grid = T,grid_col = 'black', color = new_color(100),range = c(0,2))
terra::lines(US_d01, col = 'white')
terra::lines(coast_d01, col = 'white')
legend_range(model_d01,show.mean = F)

# dev.off()

# for statistical metrics
table1 <- sat(mo = model_d01, ob = tempo,rname = 'hcho_statistic')
print(table1)

# for metrics for categorical evaluation
table2 <- sat(mo = model_d01, ob = tempo,rname = 'hcho_categoric',eval_function = cate,threshold = 0.15, verbose = F)
print(table2)

# to save in a .csv
write_stat(stat = table1, file = 'table1.csv')
write_stat(stat = table2, file = 'table2.csv')