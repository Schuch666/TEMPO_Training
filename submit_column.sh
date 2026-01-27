#!/bin/bash --login
#SBATCH -J column
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=12:00:00
#SBATCH --mem=0
#SBATCH --exclusive

date

cd /scratch/schuch/WRF-Chem-GHG/WRF

conda activate rspatial

date

Rscript process_form_column.R

date
