# Enable transcript logging
transcript on

# Create the work library
vlib work

# Compile the design and testbench
vlog -sv rtl/preamble_sfd_tx.sv
vlog -sv tb/preamble_sfd_tx/tb_preamble_sfd_tx.sv

# Simulate the testbench
vsim -t 1ns -L altera_mf_ver -voptargs="+acc" tb_preamble_sfd_tx

# Add signals to the waveform window
add wave -radix binary          tb_preamble_sfd_tx/dut/aclk
add wave -radix binary          tb_preamble_sfd_tx/dut/aresetn
add wave -radix binary          tb_preamble_sfd_tx/dut/preamble_sfd_tx_start
add wave -radix hexadecimal    	tb_preamble_sfd_tx/dut/data_out
add wave -radix binary          tb_preamble_sfd_tx/dut/preamble_sfd_tx_done



# Run the simulation for the specified time
run 10us

# Zoom out to show all waveform data
wave zoom full
