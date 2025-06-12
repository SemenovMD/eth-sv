module eth_udp_arp_wrapper #(
    parameter MAC_SOURCE = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00},      // PC
    parameter MAC_DESTINATION = {8'h84, 8'hA0, 8'hDA, 8'hB8, 8'h31, 8'h42}, // FPGA
    parameter IP_SOURCE = {8'd192, 8'd168, 8'd1, 8'd10},                    // PC
    parameter IP_DESTINATION = {8'd192, 8'd168, 8'd1, 8'd120},              // FPGA
    parameter PORT_SOURCE = {8'h1F, 8'h90},                                 // PC
    parameter PORT_DESTINATION = {8'h1F, 8'h90}                             // FPGA
) (
    input wire gmii_rstn,
    input wire [7:0] gmii_rxd,
    input wire gmii_rx_dv,
    input wire gmii_rx_er,
    input wire gmii_rx_clk,
    output wire [7:0] gmii_txd,
    output wire gmii_tx_dv,
    output wire gmii_tx_er,
    input wire gmii_tx_clk,
    input wire aclk,
    input wire aresetn,
    output wire [31:0] m_axis_tdata,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    input wire m_axis_tready,
    input wire [31:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    output wire s_axis_tready
);

    eth_udp_arp #(
        .MAC_SOURCE(MAC_SOURCE),
        .MAC_DESTINATION(MAC_DESTINATION),
        .IP_SOURCE(IP_SOURCE),
        .IP_DESTINATION(IP_DESTINATION),
        .PORT_SOURCE(PORT_SOURCE),
        .PORT_DESTINATION(PORT_DESTINATION)
    ) u_eth_udp_arp (
        .gmii_rstn(gmii_rstn),
        .gmii_rxd(gmii_rxd),
        .gmii_rx_dv(gmii_rx_dv),
        .gmii_rx_er(gmii_rx_er),
        .gmii_rx_clk(gmii_rx_clk),
        .gmii_txd(gmii_txd),
        .gmii_tx_dv(gmii_tx_dv),
        .gmii_tx_er(gmii_tx_er),
        .gmii_tx_clk(gmii_tx_clk),
        .aclk(aclk),
        .aresetn(aresetn),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready)
    );
endmodule