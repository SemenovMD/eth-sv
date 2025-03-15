module eth_udp_arp

#(
    parameter   MAC_SOURCE          =   {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00}, // PC
    parameter   MAC_DESTINATION     =   {8'h84, 8'hA0, 8'hDA, 8'hB8, 8'h31, 8'h42}, // FPGA
    parameter   IP_SOURCE           =   {8'd192, 8'd168, 8'd1, 8'd10},              // PC
    parameter   IP_DESTINATION      =   {8'd192, 8'd168, 8'd1, 8'd120},             // FPGA
    parameter   PORT_SOURCE         =   {8'h1F, 8'h90},                             // PC
    parameter   PORT_DESTINATION    =   {8'h1F, 8'h90}                              // FPGA
)

(
    input   logic           gmii_rstn,

    // PHY GMII RX
    input   logic   [7:0]   gmii_rxd,
    input   logic           gmii_rx_dv,
    input   logic           gmii_rx_er,
    input   logic           gmii_rx_clk,

    // PHY GMII TX
    output  logic   [7:0]   gmii_txd,
    output  logic           gmii_tx_dv,
    output  logic           gmii_tx_er,
    input   logic           gmii_tx_clk,

    // AXI-Stream Clock and Reset
    input   logic           aclk,
    input   logic           aresetn,

    // AXI-Stream RX
    output  logic   [31:0]  m_axis_tdata,
    output  logic           m_axis_tvalid,
    output  logic           m_axis_tlast,
    input   logic           m_axis_tready,

    // AXI-Stream TX
    input   logic   [31:0]  s_axis_tdata,
    input   logic           s_axis_tvalid,
    input   logic           s_axis_tlast,
    output  logic           s_axis_tready
);

    logic   [47:0]  mac_s_addr;
    logic   [47:0]  rq_mac_s_addr;

    logic           arp_data_valid;
    logic           arp_data_tx_done;
    logic           arp_tx_start;
    logic           arp_oper_rx;
    logic           arp_oper_tx;
    logic           arp_resp_start;
    logic           arp_rq_start;

    logic           crc_valid;
    logic           crc_error;

    eth_rx eth_rx_inst
    (
        .aclk(aclk),
        .aresetn(aresetn),
        .gmii_rstn(gmii_rstn),
        .gmii_rxd(gmii_rxd),
        .gmii_rx_dv(gmii_rx_dv),
        .gmii_rx_er(gmii_rx_er),
        .gmii_rx_clk(gmii_rx_clk),
        .mac_d_addr(MAC_DESTINATION),
        .ip_d_addr(IP_DESTINATION),
        .mac_s_addr(mac_s_addr),
        .ip_s_addr(IP_SOURCE),
        .port_d(PORT_DESTINATION),
        .rq_mac_s_addr(rq_mac_s_addr),
        .arp_oper(arp_oper_rx),
        .arp_data_valid(arp_data_valid),
        .crc_valid(crc_valid),
        .crc_error(crc_error),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );

    eth_tx eth_tx_inst
    (
        .aclk(aclk),
        .aresetn(aresetn),
        .gmii_tx_rstn(gmii_rstn),
        .gmii_txd(gmii_txd),
        .gmii_tx_en(gmii_tx_dv),
        .gmii_tx_er(gmii_tx_er),
        .gmii_tx_clk(gmii_tx_clk),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready),
        .eth_header_arp_tx_start(arp_tx_start),
        .arp_oper(arp_oper_tx),
        .arp_data_tx_done(arp_data_tx_done),
        .mac_d_addr(mac_s_addr),
        .ip_d_addr(IP_SOURCE),
        .mac_s_addr(MAC_DESTINATION),
        .ip_s_addr(IP_DESTINATION),
        .port_s(PORT_DESTINATION),
        .port_d(PORT_SOURCE)
    );

    arp_cache arp_cache_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(gmii_rstn),
        .mac_s_addr_in(rq_mac_s_addr),
        .mac_s_addr_out(mac_s_addr),
        .arp_oper(arp_oper_rx),
        .arp_data_done(arp_data_valid),
        .crc_valid(crc_valid),
        .arp_resp_start(arp_resp_start),
        .arp_resp_end(arp_data_tx_done),
        .arp_rq_start(arp_rq_start)
    );

    arb_arp_oper arb_arp_oper_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(gmii_rstn),
        .arp_resp_start(arp_resp_start),
        .arp_rq_start(arp_rq_start),
        .arp_data_tx_done(arp_data_tx_done),
        .arp_oper(arp_oper_tx),
        .arp_tx_start(arp_tx_start)
    );

endmodule