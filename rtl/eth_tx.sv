module eth_tx

(
    input   logic           aresetn,

    output  logic   [7:0]   gmii_txd,
    output  logic           gmii_tx_en,
    output  logic           gmii_tx_er,
    input   logic           gmii_tx_clk,

    input   logic           tx_frame_start,
    output  logic           tx_frame_done,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [31:0]  ip_d_addr,
    input   logic   [47:0]  mac_s_addr,
    input   logic   [31:0]  ip_s_addr,

    input   logic           arp_oper
);

    logic           preamble_sfd_tx_done_wire;
    logic   [7:0]   preamble_sfd_tx_data_wire;

    logic           eth_header_arp_tx_done_wire;
    logic   [7:0]   eth_header_arp_tx_data_wire;

    logic           arp_data_tx_done_wire;
    logic   [7:0]   arp_data_tx_wire;

    logic           fcs_tx_done_wire;
    logic   [7:0]   fcs_tx_data_wire;

    logic           data_valid;
    logic   [7:0]   data_out;


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
        .aresetn(aresetn),
        .preamble_sfd_tx_start(tx_frame_start),
        .preamble_sfd_tx_done(preamble_sfd_tx_done_wire),
        .data_out(preamble_sfd_tx_data_wire)
    );

    eth_header_tx eth_header_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(aresetn),
        .mac_d_addr(mac_d_addr),
        .mac_s_addr(mac_s_addr),
        .preamble_sfd_tx_done(preamble_sfd_tx_done_wire),
        .eth_header_arp_tx_start('d1),
        .eth_header_ip_tx_start('d0),
        .data_out(eth_header_arp_tx_data_wire),
        .eth_header_arp_tx_done(eth_header_arp_tx_done_wire)
        //.eth_header_ip_tx_done
    );

    arp_data_tx arp_data_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(aresetn),
        .arp_oper(arp_oper),
        .mac_d_addr(mac_d_addr),
        .ip_d_addr(ip_d_addr),
        .mac_s_addr(mac_s_addr),
        .ip_s_addr(ip_s_addr),
        .eth_header_arp_done(eth_header_arp_tx_done_wire),
        .arp_data_done(arp_data_tx_done_wire),
        .data_out(arp_data_tx_wire)
    );

    fcs_tx fcs_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(aresetn),
        .preamble_sfd_tx_done(preamble_sfd_tx_done_wire),
        .data_in(data_out),
        .arp_data_done(arp_data_tx_done_wire),
        .udp_data_done('d0),
        .data_out(fcs_tx_data_wire),
        .fcs_tx_done(fcs_tx_done_wire)
    );

    mux_tx mux_tx_inst
    (
        .aclk(gmii_tx_clk),
        .aresetn(aresetn),
        .data_valid(data_valid),
        .data_out(data_out),
        .preamble_sfd_tx_start(tx_frame_start),
        .preamble_sfd_tx_done(preamble_sfd_tx_done_wire),
        .preamble_sfd_tx_data(preamble_sfd_tx_data_wire),
        .eth_header_arp_tx_done(eth_header_arp_tx_done_wire),
        .eth_header_arp_tx_data(eth_header_arp_tx_data_wire),
        .arp_data_tx_done(arp_data_tx_done_wire),
        .arp_data_tx(arp_data_tx_wire),
        .fcs_tx_done(fcs_tx_done_wire),
        .fcs_tx_data(fcs_tx_data_wire),
        .tx_frame_done(tx_frame_done)
    );


endmodule