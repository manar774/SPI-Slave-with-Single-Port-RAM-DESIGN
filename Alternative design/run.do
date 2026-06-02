vlib work
vlog RAM.V SPI_Slave.v SPI_Wrapper.v Wrapper_tb.v
vsim -voptargs=+acc  work.Wrapper_tb
add wave *
run -all
#quit -sim