vlib work
vcom -93 ../src/servomoteur.vhd
vcom -93 tb_servomoteur.vhd
vsim -novopt tb_servomoteur
add wave *
run -a
