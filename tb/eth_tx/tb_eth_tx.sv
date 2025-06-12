`timescale 1ns / 1ps

module tb_eth_tx();

// Signals declaration
logic           aclk;
logic           aresetn;
logic   [31:0]  s_axis_tdata;
logic           s_axis_tvalid;
logic           s_axis_tlast;
logic           s_axis_tready;
logic   [7:0]   gmii_txd;
logic           gmii_tx_en;
logic           gmii_tx_er;
logic           gmii_tx_clk;
logic           gmii_tx_rstn;
logic           eth_header_arp_tx_start;
logic           arp_oper;
logic           arp_data_tx_done;
logic   [47:0]  mac_d_addr;
logic   [31:0]  ip_d_addr;
logic   [47:0]  mac_s_addr;
logic   [31:0]  ip_s_addr;
logic   [15:0]  port_s;
logic   [15:0]  port_d;
logic           icmp_request_done;
logic   [15:0]  icmp_id;
logic   [15:0]  icmp_seq_num;
logic           icmp_header_tx_done;


// DUT instantiation
eth_tx dut (.*);

task send_frame(int words);
    @(posedge aclk);
    s_axis_tdata = $random;
    s_axis_tvalid = 1;
    wait(s_axis_tready);
    
    repeat (words - 2) begin
        @(posedge aclk);
        s_axis_tdata = $random;
    end

    @(posedge aclk);
    s_axis_tdata = $random;
    s_axis_tlast = 1;
    @(posedge aclk);
    s_axis_tvalid = 0;
    s_axis_tlast = 0;
endtask

// Clock generation
initial begin
    aclk = 0;
    forever #5 aclk = ~aclk; // 100 MHz
end

initial begin
    gmii_tx_clk = 0;
    forever #4 gmii_tx_clk = ~gmii_tx_clk; // 125 MHz
end

// Reset generation
initial begin
    aresetn = 0;
    gmii_tx_rstn = 0;
    #100;
    aresetn = 1;
    gmii_tx_rstn = 1;
end

// Test scenario
initial begin
    // Initialize inputs
    s_axis_tdata = 0;
    s_axis_tvalid = 0;
    s_axis_tlast = 0;
    eth_header_arp_tx_start = 0;
    arp_oper = 0;
    mac_d_addr = 48'h001122334455;
    ip_d_addr = 32'hC0A80101;
    mac_s_addr = 48'hAABBCCDDEEFF;
    ip_s_addr = 32'hC0A80102;
    port_s = 16'h1234;
    port_d = 16'h5678;
    icmp_request_done = 0;
    icmp_id = 0;
    icmp_seq_num = 0;
end

initial begin
    #1000;

    repeat(10) begin
        send_frame(256);
        #10;
    end
end

endmodule