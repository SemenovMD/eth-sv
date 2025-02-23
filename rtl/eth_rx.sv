module eth_rx

(
    input   logic           aresetn,

    input   logic   [7:0]   gmii_rxd,
    input   logic           gmii_rx_dv,
    input   logic           gmii_rx_er,
    input   logic           gmii_rx_clk,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [31:0]  ip_d_addr,
    input   logic   [47:0]  mac_s_addr,
    input   logic   [31:0]  ip_s_addr,

    output  logic   [47:0]  rq_mac_s_addr,
    output  logic           arp_data_valid,
    output  logic           crc_valid,
    output  logic           crc_error,

    output  logic   [15:0]  checksum_calc_pin,           
    output  logic           ip_header_valid_pin,
    output  logic   [3:0]   state_ip_pin,
    output  logic           eth_type_ip_valid_pin
);
    ///

    assign ip_header_valid_pin = ip_header_valid;
    assign eth_type_ip_valid_pin = eth_type_ip_valid;

    ///

    logic   [7:0]   data_out;
    logic           data_valid;

    logic           preamble_sfd_valid;

    logic           eth_type_arp_valid;
    logic           eth_type_ip_valid;

    logic           ip_header_done;
    logic           ip_header_valid;

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
        .aresetn(aresetn),
        .data_in(data_out),
        .data_valid(data_valid),
        .preamble_sfd_valid(preamble_sfd_valid)
    );

    eth_header_rx eth_header_rx_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(aresetn),
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
        .aresetn(aresetn),
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
        .aresetn(aresetn),
        .data_in(data_out),
        .data_valid(data_valid),
        .ip_s_addr(ip_s_addr),
        .ip_d_addr(ip_d_addr),
        .eth_type_ip_valid(eth_type_ip_valid),
        .ip_header_done(ip_header_done),
        .ip_header_valid(ip_header_valid),
        .checksum_calc_pin(checksum_calc_pin),
        .state_ip_pin(state_ip_pin)
    );

    fcs_rx fcs_rx_inst
    (
        .aclk(gmii_rx_clk),
        .aresetn(aresetn),
        .data_in(data_out),
        .data_valid(data_valid),
        .preamble_sfd_valid(preamble_sfd_valid),
        .crc_valid(crc_valid),
        .crc_error(crc_error)
    );

endmodule