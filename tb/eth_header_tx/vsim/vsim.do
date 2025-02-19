# Enable transcript logging
transcript on

# Create the work library
vlib work

# Compile the design and testbench
vlog -sv rtl/eth_header_tx.sv
vlog -sv tb/tb.sv

# Simulate the testbench
vsim -t 1ns -L altera_mf_ver -voptargs="+acc" tb

# Add signals to the waveform window
add wave -radix binary          axil_spi_master_tb/axil_spi_master_inst/aresetn
add wave -radix binary          axil_spi_master_tb/axil_spi_master_inst/aclk


# Run the simulation for the specified time
run 10us

# Zoom out to show all waveform data
wave zoom full
