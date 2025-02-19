module eth_header_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    output  logic   [7:0]   data_out,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [47:0]  mac_s_addr,

    input   logic           preamble_sfd_tx_done,
    input   logic           eth_header_arp_resp_start,
    input   logic           eth_header_ip_start,

    output  logic           eth_header_arp_valid_done,
    output  logic           eth_header_ip_valid_done
);

    localparam  ETH_ARP_TYPE    =   16'h08_06;
    localparam  ETH_IP_TYPE     =   16'h08_00; // IPv4

    localparam  MAC_W           =   48'hFF_FF_FF_FF_FF_FF;


    typedef enum logic 
    {  

    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin

        end else begin
            case (state)
                IDLE:
                    begin

                    end
            endcase
        end
    end

endmodule