#!/bin/bash --login
#SBATCH -J Post
#SBATCH -N 1
#SBATCH -n 24
#SBATCH --time=12:00:00
#SBATCH --mem=0
#SBATCH --exclusive

cd /scratch/schuch/WRF-Chem-GHG

year=2024            # year to be processed
month=07             # month to be processed
output="WRF"         # folder to save the post processing

mkdir -p ${output}

for domain in d01 d02 d03; do

   input=${output}/wrf_${domain}

   echo "processing WRF-Chem output for "${year}-${month}" for "${domain}

   for species in o3 no2 form CLDFRA; do
     for hour in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23; do
       ncea -v Times,XLAT,XLONG,${species} ${input}/wrfout_d01_${year}-${month}-??_${hour}:00:00 ${output}/WRF.monthly.${hour}z.${domain}.${species}.${year}-${month}.nc &
     done
     wait
     ncrcat ${output}/WRF.monthly.*${domain}.${species}* ${output}/../WRF.monthly.24hours.${domain}.${species}.${year}-${month}.nc
   done
done

echo "done!"