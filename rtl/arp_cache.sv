module arp_cache

(
    input   logic           aclk,
    input   logic           aresetn,

    // Configuration Interface
    input   logic   [47:0]  mac_config_addr_in,
    input   logic   [31:0]  ip_config_addr_in,

    output  logic   [47:0]  mac_config_addr_out,
    output  logic   [31:0]  ip_config_addr_out,

    // Ethernet Header
    input   logic   [47:0]  eth_mac_s_addr,
    output  logic           eth_mac_s_addr_valid,
    
    // ARP data
    input   logic   [47:0]  arp_mac_s_addr,
    input   logic   [31:0]  arp_ip_s_addr,
    input   logic           arp_mac_s_addr_valid,

    // IP Header
    input   logic   [31:0]  ip_ip_s_addr,
    output  logic           ip_ip_s_addr_valid
);


endmodule