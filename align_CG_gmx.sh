#!/bin/bash

### SETUP - VARIABLES ###

md_name="u-he-CC-m2-"
replica_inicial=1
replica_final=100


#####################################


mkdir -p trajins trajins_align min-eq-md_files

mv "$md_name"* trajins 

rm ogmx*
rm egmx*


mv npt* min-eq-md_files
mv nvt* min-eq-md_files
mv *.edr min-eq-md_files
mv *.gro min-eq-md_files
mv *.tpr min-eq-md_files
mv *.trr min-eq-md_files
mv *.itp min-eq-md_files 
mv *.mdp min-eq-md_files
mv *.top min-eq-md_files
rm -f \#*

cd trajins

for (( i=$replica_inicial; i<=$replica_final; i++ ))
do
    echo "Procesando archivo $i ..."

    # Definir nombres de archivos
    trj_file="${md_name}${i}.xtc"
    tpr_file="${md_name}${i}.tpr"
    trj_whole="${md_name}${i}_whole.xtc"
    trj_nojump="${md_name}${i}_nojump.xtc"
    trj_center="${md_name}${i}_center.xtc"
    trj_compact="${md_name}${i}_compact.xtc"
    trj_fit="${md_name}${i}_fit.xtc"

    # Paso 1: Aplicar pbc whole
    echo '0' | gmx trjconv -f "$trj_file" -s "$tpr_file" -pbc whole -o "$trj_whole"

    # Paso 2: Eliminar saltos
    echo '0' | gmx trjconv -s "$tpr_file" -f "$trj_whole" -o "$trj_nojump" -pbc nojump

    # Paso 3: Centrar trayectoria
    echo '1 0' | gmx trjconv -s "$tpr_file" -f "$trj_nojump" -o "$trj_center" -center

    # Paso 4: Compactar caja
    echo '1 0' | gmx trjconv -s "$tpr_file" -f "$trj_center" -o "$trj_compact" -ur compact -center -pbc mol

    # Paso 5: Ajustar trayectoria
    echo '1 1 1' | gmx trjconv -s "$tpr_file" -f "$trj_compact" -o "$trj_fit" -fit rot+trans -center

    echo "Replica $i alineada." >> lista
done

gmx convert-tpr -s "$md_name".tpr -o "$md_name"dry.tpr

rm -r *_whole.xtc
rm -r *_nojump.xtc
rm -r *_center.xtc
rm -r *_compact.xtc

mv *fit* ../trajins_align
mv "$md_name"dry.tpr ../trajins_align

cd ../trajins_align

sed -i '/W/d' npt_dry.gro
sed -i '/CL/d' npt_dry.gro
sed -i '/NA/d' npt_dry.gro

echo "Alineamiento completo."

