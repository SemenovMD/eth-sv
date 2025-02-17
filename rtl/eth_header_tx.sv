module eth_header_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [47:0]  mac_s_addr,
    
    input   logic           preamble_sfd_tx_valid,
    input   logic           arp_resp_start,
    input   logic           ip_start,

    output  logic           eth_type_arp_valid_done,
    output  logic           eth_type_ip_valid_done
);


endmodule