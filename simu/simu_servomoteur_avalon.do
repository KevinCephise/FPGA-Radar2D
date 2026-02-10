vlib work
vcom -93 ../src/servomoteur_avalon.vhd
vcom -93 tb_servomoteur_avalon.vhd
vsim -novopt tb_servomoteur_avalon
add wave *
run -a
