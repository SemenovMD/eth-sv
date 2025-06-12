# Enable transcript logging
transcript on

# Create the work library
vlib work

# Compile the design and testbench
vlog -sv    rtl/gmii_rx_to_valid.sv
vlog -sv    rtl/preamble_sfd_rx.sv
vlog -sv    rtl/eth_header_rx.sv
vlog -sv    rtl/icmp_rx.sv
vlog -sv    rtl/arp_data_rx.sv
vlog -sv    rtl/ip_header_rx.sv
vlog -sv    rtl/udp_header_rx.sv
vlog -sv    rtl/conv_8_32.sv
vlog -sv    rtl/asyn_fifo_rx.sv
vlog -sv    rtl/fcs_rx.sv

vlog -sv    rtl/eth_rx.sv

vlog -sv    tb/eth_rx/tb_eth_rx.sv

# Simulate the testbench
vsim -t 1ns -L altera_mf_ver -voptargs="+acc" tb_eth_rx

# Add signals to the waveform window
add wave -radix binary          tb_eth_rx/gmii_rstn
add wave -radix binary          tb_eth_rx/gmii_rx_clk
add wave -radix hexadecimal     tb_eth_rx/gmii_rxd
add wave -radix binary          tb_eth_rx/gmii_rx_dv
add wave -radix binary          tb_eth_rx/gmii_rx_er

add wave -radix binary          tb_eth_rx/aresetn
add wave -radix binary          tb_eth_rx/aclk
add wave -radix hexadecimal     tb_eth_rx/m_axis_tdata
add wave -radix hexadecimal     tb_eth_rx/m_axis_tvalid
add wave -radix hexadecimal     tb_eth_rx/m_axis_tlast
add wave -radix hexadecimal     tb_eth_rx/m_axis_tready

# Run the simulation for the specified time
run 1ms

# Zoom out to show all waveform data
wave zoom full
