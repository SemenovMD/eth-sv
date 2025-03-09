module eth_rx

(
    input   logic           gmii_rstn,

    input   logic   [7:0]   gmii_rxd,
    input   logic           gmii_rx_dv,
    input   logic           gmii_rx_er,
    input   logic           gmii_rx_clk,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [31:0]  ip_d_addr,
    input   logic   [47:0]  mac_s_addr,
    input   logic   [31:0]  ip_s_addr,

    input   logic   [15:0]  port_s,
    input   logic   [15:0]  port_d,

    output  logic   [47:0]  rq_mac_s_addr,
    output  logic           arp_data_valid,
    output  logic           crc_valid,
    output  logic           crc_error,

    input   logic           aclk,
    input   logic           aresetn,

    output  logic   [31:0]  m_axis_tdata,
    output  logic           m_axis_tvalid,
    output  logic           m_axis_tlast,
    input   logic           m_axis_tready
);

    logic   [7:0]   data_out;
    logic           data_valid;

    logic           preamble_sfd_valid;

    logic           eth_type_arp_valid;
    logic           eth_type_ip_valid;

    logic           ip_header_done;
    logic           ip_header_valid;

    logic           udp_data_valid;
    logic           udp_data_tlast;

    logic   [31:0]  s_axis_tdata;
    logic           s_axis_tvalid;
    logic           s_axis_tlast;
    logic           s_axis_tready;

    gmii_rx_to_valid gmii_rx_to_valid_inst
    (
        .gmii_rxd(gmii_rxd),
        .gmii_rx_dv(gmii_rx_dv),
        .gmii_rx_er(gmii_rx_er),
        .data_out(data_out),
        .data_valid(data_valid)
    );

    preamble_sfd_rx preamble_sfd_rx_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(gmii_rstn),
        .data_in(data_out),
        .data_valid(data_valid),
        .preamble_sfd_valid(preamble_sfd_valid)
    );

    eth_header_rx eth_header_rx_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(gmii_rstn),
        .data_in(data_out),
        .data_valid(data_valid),
        .mac_d_addr(mac_d_addr),
        .mac_s_addr(mac_s_addr),
        .preamble_sfd_valid(preamble_sfd_valid),
        .eth_type_arp_valid(eth_type_arp_valid),
        .eth_type_ip_valid(eth_type_ip_valid)
    );

    arp_data_rx arp_data_rx_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(gmii_rstn),
        .data_in(data_out),
        .data_valid(data_valid),
        .mac_s_addr(rq_mac_s_addr),
        .ip_s_addr(ip_s_addr),
        .mac_d_addr(mac_d_addr),
        .ip_d_addr(ip_d_addr),
        .eth_type_arp_valid(eth_type_arp_valid),
        .arp_data_valid(arp_data_valid)
    );

    ip_header_rx ip_header_rx_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(gmii_rstn),
        .data_in(data_out),
        .data_valid(data_valid),
        .ip_s_addr(ip_s_addr),
        .ip_d_addr(ip_d_addr),
        .eth_type_ip_valid(eth_type_ip_valid),
        .ip_header_done(ip_header_done)
    );

    udp_header_rx udp_header_rx_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(gmii_rstn),
        .data_in(data_out),
        .data_valid(data_valid),
        .port_s(port_s),
        .port_d(port_d),
        .ip_header_done(ip_header_done),
        .udp_data_valid(udp_data_valid),
        .udp_data_tlast(udp_data_tlast)
    );

    conv_8_32 conv_8_32_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(gmii_rstn),
        .data_in(data_out),
        .data_valid(data_valid),
        .udp_data_valid(udp_data_valid),
        .udp_data_tlast(udp_data_tlast),
        .m_axis_tdata(s_axis_tdata),
        .m_axis_tlast(s_axis_tlast),
        .m_axis_tvalid(s_axis_tvalid),
        .m_axis_tready(s_axis_tready)
    );

    asyn_fifo_rx asyn_fifo_rx_inst
    (
        .aclk_wr(gmii_rx_clk),
        .aresetn_wr(gmii_rstn),
        .aclk_rd(aclk),
        .aresetn_rd(aresetn),
        .data_valid(data_valid),
        .crc_valid(crc_valid),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready)
    );

    fcs_rx fcs_rx_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(gmii_rstn),
        .data_in(data_out),
        .data_valid(data_valid),
        .preamble_sfd_valid(preamble_sfd_valid),
        .crc_valid(crc_valid),
        .crc_error(crc_error)
    );

endmodule