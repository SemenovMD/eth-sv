module eth_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [31:0]  s_axis_tdata,
    input   logic           s_axis_tvalid,
    input   logic           s_axis_tlast,
    output  logic           s_axis_tready,

    output  logic   [7:0]   gmii_txd,
    output  logic           gmii_tx_en,
    output  logic           gmii_tx_er,
    input   logic           gmii_tx_clk,
    input   logic           gmii_tx_rstn,

    input   logic           eth_header_arp_tx_start,
    input   logic           arp_oper,
    output  logic           arp_data_tx_done,

    input   logic           icmp_request_done,
    input   logic   [15:0]  icmp_id,
    input   logic   [15:0]  icmp_seq_num,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [31:0]  ip_d_addr,
    input   logic   [47:0]  mac_s_addr,
    input   logic   [31:0]  ip_s_addr,

    input   logic   [15:0]  port_s,
    input   logic   [15:0]  port_d,
    
    output  logic           icmp_header_tx_done
);

    logic           preamble_sfd_tx_done;
    logic   [7:0]   preamble_sfd_tx_data;

    logic           eth_header_ip_udp_tx_start;
    logic           eth_header_ip_icmp_tx_start;
    logic           eth_header_ip_tx_start;
    logic           eth_header_arp_tx_done;
    logic           eth_header_ip_tx_done;
    logic   [7:0]   eth_header_tx_data;

    logic           ip_header_tx_udp_done;
    logic           ip_header_tx_icmp_done;
    logic   [7:0]   ip_header_tx_data;

    // logic           icmp_header_tx_done;
    logic   [7:0]   icmp_header_tx_data;

    logic           udp_header_tx_done_0;
    logic           udp_header_tx_done_1;
    logic   [7:0]   udp_header_tx_data;

    logic           udp_data_tx_done;
    logic   [7:0]   udp_data_tx_data;
    logic   [15:0]  udp_len;

    logic   [7:0]   arp_data_tx;

    logic           fcs_tx_done;
    logic   [7:0]   fcs_tx_data;

    logic           tx_frame_start;
    logic           data_valid;
    logic   [7:0]   data_out;
    logic           tx_frame_done;

    logic   [31:0]  m_axis_tdata;
    logic           m_axis_tvalid;
    logic           m_axis_tlast;
    logic           m_axis_tready;

    assign eth_header_ip_tx_start = eth_header_ip_udp_tx_start || eth_header_ip_icmp_tx_start;
    assign tx_frame_start = eth_header_ip_tx_start || eth_header_arp_tx_start;

    gmii_tx_to_valid gmii_tx_to_valid_inst
    (
        .data_in(data_out),
        .data_valid(data_valid),
        .gmii_txd(gmii_txd),
        .gmii_tx_en(gmii_tx_en),
        .gmii_tx_er(gmii_tx_er)
    );

    preamble_sfd_tx preamble_sfd_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(gmii_tx_rstn),
        .preamble_sfd_tx_start(tx_frame_start),
        .preamble_sfd_tx_done(preamble_sfd_tx_done),
        .data_out(preamble_sfd_tx_data),
        .tx_frame_done(tx_frame_done)
    );

    eth_header_tx eth_header_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(gmii_tx_rstn),
        .mac_d_addr(mac_d_addr),
        .mac_s_addr(mac_s_addr),
        .preamble_sfd_tx_done(preamble_sfd_tx_done),
        .arp_oper(arp_oper),
        .eth_header_arp_tx_start(eth_header_arp_tx_start),
        .eth_header_ip_tx_start(eth_header_ip_tx_start),
        .data_out(eth_header_tx_data),
        .eth_header_arp_tx_done(eth_header_arp_tx_done),
        .eth_header_ip_tx_done(eth_header_ip_tx_done)
    );

    ip_header_tx ip_header_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(gmii_tx_rstn),
        .eth_header_ip_tx_done(eth_header_ip_tx_done),
        .eth_header_ip_icmp_tx_start(eth_header_ip_icmp_tx_start),
        .ip_s_addr(ip_s_addr),
        .ip_d_addr(ip_d_addr),
        .udp_len(udp_len),
        .data_out(ip_header_tx_data),
        .ip_header_tx_udp_done(ip_header_tx_udp_done),
        .ip_header_tx_icmp_done(ip_header_tx_icmp_done)
    );

    icmp_tx icmp_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(gmii_tx_rstn),
        .ip_header_tx_done(ip_header_tx_icmp_done),
        .icmp_request_done(icmp_request_done),
        .icmp_id(icmp_id),
        .icmp_seq_num(icmp_seq_num),
        .eth_header_ip_icmp_tx_start(eth_header_ip_icmp_tx_start),
        .data_out(icmp_header_tx_data),
        .icmp_header_tx_done(icmp_header_tx_done)
    );

    udp_header_tx udp_header_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(gmii_tx_rstn),
        .ip_header_tx_done(ip_header_tx_udp_done),
        .udp_len(udp_len),
        .port_s(port_s),
        .port_d(port_d),
        .data_out(udp_header_tx_data),
        .udp_header_tx_done_0(udp_header_tx_done_0),
        .udp_header_tx_done_1(udp_header_tx_done_1)
    );

    conv_32_8 conv_32_8_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(gmii_tx_rstn),
        .s_axis_tdata(m_axis_tdata),
        .s_axis_tvalid(m_axis_tvalid),
        .s_axis_tlast(m_axis_tlast),
        .s_axis_tready(m_axis_tready),
        .data_out(udp_data_tx_data),
        .udp_data_tx_done(udp_data_tx_done)
    );

    asyn_fifo_tx asyn_fifo_tx_inst
    (
        .aclk_wr(aclk),
        .aresetn_wr(aresetn),
        .aclk_rd(gmii_tx_clk),
        .aresetn_rd(gmii_tx_rstn),
        .udp_header_tx_done(udp_header_tx_done_0),
        .eth_header_ip_tx_start(eth_header_ip_udp_tx_start),
        .udp_len(udp_len),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready)
    );

    arp_data_tx arp_data_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(gmii_tx_rstn),
        .arp_oper(arp_oper),
        .mac_d_addr(mac_d_addr),
        .ip_d_addr(ip_d_addr),
        .mac_s_addr(mac_s_addr),
        .ip_s_addr(ip_s_addr),
        .eth_header_arp_done(eth_header_arp_tx_done),
        .arp_data_done(arp_data_tx_done),
        .data_out(arp_data_tx)
    );

    fcs_tx fcs_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(gmii_tx_rstn),
        .preamble_sfd_tx_done(preamble_sfd_tx_done),
        .data_in(data_out),
        .arp_data_done(arp_data_tx_done),
        .udp_data_done(udp_data_tx_done),
        .icmp_data_done(icmp_header_tx_done),
        .data_out(fcs_tx_data),
        .fcs_tx_done(fcs_tx_done)
    );

    mux_tx mux_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(gmii_tx_rstn),
        .data_valid(data_valid),
        .data_out(data_out),
        .preamble_sfd_tx_start(tx_frame_start),
        .preamble_sfd_tx_done(preamble_sfd_tx_done),
        .preamble_sfd_tx_data(preamble_sfd_tx_data),
        .eth_header_ip_tx_done(eth_header_ip_tx_done),
        .eth_header_arp_tx_done(eth_header_arp_tx_done),
        .eth_header_tx_data(eth_header_tx_data),
        .ip_header_tx_udp_done(ip_header_tx_udp_done),
        .ip_header_tx_icmp_done(ip_header_tx_icmp_done),
        .ip_header_tx_data(ip_header_tx_data),
        .icmp_header_tx_done(icmp_header_tx_done),
        .icmp_header_tx_data(icmp_header_tx_data),
        .udp_header_tx_done(udp_header_tx_done_1),
        .udp_header_tx_data(udp_header_tx_data),
        .udp_data_tx_done(udp_data_tx_done),
        .udp_data_tx_data(udp_data_tx_data),
        .arp_data_tx_done(arp_data_tx_done),
        .arp_data_tx(arp_data_tx),
        .fcs_tx_done(fcs_tx_done),
        .fcs_tx_data(fcs_tx_data),
        .tx_frame_done(tx_frame_done)
    );

endmodule