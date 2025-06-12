# Enable transcript logging
transcript on

# Create the work library
vlib work

# Compile the design and testbench
vlog -sv    rtl/gmii_tx_to_valid.sv
vlog -sv    rtl/preamble_sfd_tx.sv
vlog -sv    rtl/eth_header_tx.sv
vlog -sv    rtl/arp_data_tx.sv
vlog -sv    rtl/ip_header_tx.sv
vlog -sv    rtl/udp_header_tx.sv
vlog -sv    rtl/icmp_tx.sv
vlog -sv    rtl/conv_32_8.sv
vlog -sv    rtl/asyn_fifo_tx.sv
vlog -sv    rtl/fcs_tx.sv
vlog -sv    rtl/mux_tx.sv

vlog -sv    rtl/eth_tx.sv

vlog -sv    tb/eth_tx/tb_eth_tx.sv

# Simulate the testbench
vsim -t 1ns -L altera_mf_ver -voptargs="+acc" tb_eth_tx

# Add signals to the waveform window
add wave -radix binary          tb_eth_tx/gmii_tx_rstn
add wave -radix binary          tb_eth_tx/gmii_tx_clk
add wave -radix hexadecimal     tb_eth_tx/gmii_txd
add wave -radix binary          tb_eth_tx/gmii_tx_en
add wave -radix binary          tb_eth_tx/gmii_tx_er

add wave -radix binary          tb_eth_tx/aresetn
add wave -radix binary          tb_eth_tx/aclk
add wave -radix hexadecimal     tb_eth_tx/s_axis_tdata
add wave -radix hexadecimal     tb_eth_tx/s_axis_tvalid
add wave -radix hexadecimal     tb_eth_tx/s_axis_tlast
add wave -radix hexadecimal     tb_eth_tx/s_axis_tready

# Run the simulation for the specified time
run 1ms

# Zoom out to show all waveform data
wave zoom full
