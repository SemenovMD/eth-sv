module eth_header_rx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [7:0]   data_in,
    input   logic           data_valid,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [47:0]  mac_s_addr,

    input   logic           preamble_sfd_valid,

    output  logic           eth_type_arp_valid,
    output  logic           eth_type_ip_valid
);

    localparam  ETH_ARP_TYPE    =   16'h08_06;
    localparam  ETH_IP_TYPE     =   16'h08_00; // IPv4

    localparam  MAC_W           =   48'hFF_FF_FF_FF_FF_FF;

    logic   [2:0]   count;

    logic   [47:0]  mac_d_addr_buf;
    logic   [47:0]  mac_s_addr_buf;
    logic   [7:0]   eth_type_buf;

    typedef enum logic [1:0]
    {  
        WAIT,
        MAC_DESTINATION,
        MAC_SOURCE,
        ETH_TYPE
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT;
            count <= 'd0;
            eth_type_arp_valid <= 'd0;
            eth_type_ip_valid <= 'd0;
        end else begin
            if (!data_valid) begin
                state <= WAIT;
                count <= 'd0;
                eth_type_arp_valid <= 'd0;
                eth_type_ip_valid <= 'd0;
            end else begin
                case (state)
                    WAIT:
                        begin
                            if (!preamble_sfd_valid) begin
                                state <= WAIT;
                            end else begin
                                state <= MAC_DESTINATION;
                                mac_d_addr_buf[47:40] <= data_in;
                            end

                            eth_type_arp_valid <= 'd0;
                            eth_type_ip_valid <= 'd0;
                        end
                    MAC_DESTINATION:
                        begin
                            if (count != 4) begin
                                count <= count + 1;
                            end else begin
                                state <= MAC_SOURCE;
                                count <= 'd0;
                            end

                            case (count)
                                count: mac_d_addr_buf[39 - count*8 -: 8] <= data_in;
                            endcase
                        end
                    MAC_SOURCE:
                        begin
                            if (count != 5) begin
                                count <= count + 1;
                            end else begin
                                state <= ETH_TYPE;
                                count <= 'd0;
                            end

                            case (count)
                                count: mac_s_addr_buf[47 - count*8 -: 8] <= data_in;
                            endcase
                        end
                    ETH_TYPE:
                        begin
                            if (count != 1) begin
                                count <= count + 1;
                            end else begin
                                state <= WAIT;
                                count <= 'd0;

                                case ({eth_type_buf, data_in})
                                    ETH_ARP_TYPE:
                                        begin
                                            if (mac_d_addr_buf == MAC_W) begin
                                                eth_type_arp_valid <= 'd1;
                                            end
                                        end
                                    ETH_IP_TYPE:
                                        begin
                                            if ((mac_d_addr_buf == mac_d_addr) && (mac_s_addr_buf == mac_s_addr)) begin
                                                eth_type_ip_valid <= 'd1;
                                            end
                                        end
                                endcase
                            end

                            if (count == 0) begin
                                eth_type_buf <= data_in;
                            end
                        end
                endcase
            end
        end
    end

endmodule