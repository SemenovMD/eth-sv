module arp_handler_rx

(
    input   logic           mac_gmii_rx_clk,
    input   logic           mac_gmii_rx_rstn,

    input   logic   [7:0]   mac_gmii_rxd,
    input   logic           mac_gmii_rx_dv,
    input   logic           mac_gmii_rx_er,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [47:0]  mac_s_addr,

    input   logic           preamble_sfd_valid,

    output  logic           arp_handler_valid
);

    localparam  HTYPE       =   16'h00_01;
    localparam  PTYPE       =   16'h08_00;
    localparam  HLEN        =    8'h06;
    localparam  PLEN        =    8'h04;
    localparam  OPER_RQ     =   16'h00_01;
    localparam  OPER_RESP   =   16'h00_02;

    localparam  MAC_Z       =   48'h00_00_00_00_00_00;



endmodule