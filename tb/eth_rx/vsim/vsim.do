# Enable transcript logging
transcript on

# Create the work library
vlib work

# Compile the design and testbench
vlog -sv    rtl/gmii_rx_to_valid.sv
vlog -sv    rtl/preamble_sfd_rx.sv
vlog -sv    rtl/eth_header_rx.sv
vlog -sv    rtl/arp_data_rx.sv
vlog -sv    rtl/ip_header_rx.sv
vlog -sv    rtl/udp_header_rx.sv
vlog -sv    rtl/conv_8_32.sv
vlog -sv    rtl/fifo_rx.sv
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
add wave -radix hexadecimal     tb_eth_rx/m_axis_tdata_asyn_fifo
add wave -radix hexadecimal     tb_eth_rx/m_axis_tvalid_asyn_fifo
add wave -radix hexadecimal     tb_eth_rx/m_axis_tlast_asyn_fifo
add wave -radix hexadecimal     tb_eth_rx/m_axis_tready_asyn_fifo

add wave -radix binary          tb_eth_rx/dut/preamble_sfd_rx_inst/preamble_sfd_valid

add wave -radix binary          tb_eth_rx/dut/ip_header_rx_inst/eth_type_ip_valid
add wave -radix binary          tb_eth_rx/dut/ip_header_rx_inst/ip_header_done
add wave -radix binary          tb_eth_rx/dut/ip_header_rx_inst/state_ip

add wave -radix binary          tb_eth_rx/dut/udp_header_rx_inst/udp_data_valid
add wave -radix binary          tb_eth_rx/dut/udp_header_rx_inst/udp_data_tlast
add wave -radix binary          tb_eth_rx/dut/udp_header_rx_inst/state
add wave -radix unsigned        tb_eth_rx/dut/udp_header_rx_inst/count

add wave -radix binary          tb_eth_rx/dut/conv_8_32_inst/state_wr
add wave -radix binary          tb_eth_rx/dut/conv_8_32_inst/flag
add wave -radix binary          tb_eth_rx/dut/conv_8_32_inst/flag_last
add wave -radix unsigned        tb_eth_rx/dut/udp_header_rx_inst/length

add wave -radix binary          tb_eth_rx/dut/fcs_rx_inst/crc_valid
add wave -radix binary          tb_eth_rx/dut/fcs_rx_inst/crc_error
add wave -radix hexadecimal     tb_eth_rx/dut/fcs_rx_inst/crc_calc_4

add wave -radix hexadecimal     tb_eth_rx/dut/fifo_rx_inst/s_axis_tdata
add wave -radix binary          tb_eth_rx/dut/fifo_rx_inst/s_axis_tvalid
add wave -radix binary          tb_eth_rx/dut/fifo_rx_inst/s_axis_tlast
add wave -radix binary          tb_eth_rx/dut/fifo_rx_inst/s_axis_tready

add wave -radix hexadecimal     tb_eth_rx/dut/fifo_rx_inst/m_axis_tdata
add wave -radix binary          tb_eth_rx/dut/fifo_rx_inst/m_axis_tvalid
add wave -radix binary          tb_eth_rx/dut/fifo_rx_inst/m_axis_tlast
add wave -radix binary          tb_eth_rx/dut/fifo_rx_inst/m_axis_tready
add wave -radix binary          tb_eth_rx/dut/fifo_rx_inst/state_wr
add wave -radix binary          tb_eth_rx/dut/fifo_rx_inst/state_rd
add wave -radix unsigned        tb_eth_rx/dut/fifo_rx_inst/index_wr
add wave -radix unsigned        tb_eth_rx/dut/fifo_rx_inst/index_rd
add wave -radix unsigned        tb_eth_rx/dut/fifo_rx_inst/index_frame_wr
add wave -radix unsigned        tb_eth_rx/dut/fifo_rx_inst/index_frame_rd

add wave -radix binary          tb_eth_rx/dut/asyn_fifo_rx_inst/state_wr
add wave -radix binary          tb_eth_rx/dut/asyn_fifo_rx_inst/state_rd
add wave -radix unsigned        tb_eth_rx/dut/asyn_fifo_rx_inst/index_wr
add wave -radix unsigned        tb_eth_rx/dut/asyn_fifo_rx_inst/index_rd
add wave -radix binary          tb_eth_rx/dut/asyn_fifo_rx_inst/flag_rd
add wave -radix binary          tb_eth_rx/dut/asyn_fifo_rx_inst/flag_wr
add wave -radix binary          tb_eth_rx/dut/asyn_fifo_rx_inst/flag_rd_sync_1
add wave -radix binary          tb_eth_rx/dut/asyn_fifo_rx_inst/flag_wr_sync_1

# Run the simulation for the specified time
run 1ms

# Zoom out to show all waveform data
wave zoom full
