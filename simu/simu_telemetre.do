vlib work
vcom -93 ../src/telemetre.vhd
vcom -93 tb_telemetre.vhd
vsim -novopt tb_telemetre
add wave *
run -a
