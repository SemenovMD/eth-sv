module eth_header_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [47:0]  mac_s_addr,

    input   logic           preamble_sfd_tx_done,
    input   logic           arp_oper,
    input   logic           eth_header_arp_tx_start,
    input   logic           eth_header_ip_tx_start,

    output  logic   [7:0]   data_out,
    output  logic           eth_header_arp_tx_done,
    output  logic           eth_header_ip_tx_done
);

    localparam  ETH_ARP_TYPE    =   16'h08_06;
    localparam  ETH_IP_TYPE     =   16'h08_00;

    localparam  MAC_W           =    8'hFF;

    logic   [2:0]   count;

    typedef enum logic [1:0]
    {
        WAIT_START,
        MAC_DESTINATION_TX,
        MAC_SOURCE_TX,
        ETH_TYPE_TX
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT_START;
            count <= 'd0;
            eth_header_arp_tx_done <= 'd0;
            eth_header_ip_tx_done <= 'd0;
        end else begin
            case (state)
                WAIT_START:
                    begin
                        if (!preamble_sfd_tx_done) begin
                            state <= WAIT_START;
                        end else begin
                            state <= MAC_DESTINATION_TX;

                            if (!arp_oper) begin
                                data_out <= mac_d_addr[47 - count*8 -: 8];
                            end else begin
                                data_out <= MAC_W;
                            end

                            count <= count + 1;
                        end

                        eth_header_arp_tx_done <= 'd0;
                        eth_header_ip_tx_done <= 'd0;
                    end
                MAC_DESTINATION_TX:
                    begin
                        if (count != 5) begin
                            count <= count + 1;
                        end else begin
                            state <= MAC_SOURCE_TX;
                            count <= 'd0;
                        end

                        if (!arp_oper) begin
                            data_out <= mac_d_addr[47 - count*8 -: 8];
                        end else begin
                            data_out <= MAC_W;
                        end
                    end
                MAC_SOURCE_TX:
                    begin
                        if (count != 5) begin
                            count <= count + 1;
                        end else begin
                            state <= ETH_TYPE_TX;
                            count <= 'd0;
                        end

                        data_out <= mac_s_addr[47 - count*8 -: 8];
                    end
                ETH_TYPE_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= WAIT_START;
                            count <= 'd0;

                            case ({eth_header_arp_tx_start, eth_header_ip_tx_start})
                                2'b11: eth_header_arp_tx_done <= 'd1;
                                2'b01: eth_header_ip_tx_done <= 'd1;
                                2'b10: eth_header_arp_tx_done <= 'd1;
                            endcase
                        end

                        case ({eth_header_arp_tx_start, eth_header_ip_tx_start})
                            2'b11: data_out <= ETH_ARP_TYPE[15 - count*8 -: 8];
                            2'b01: data_out <= ETH_IP_TYPE[15 - count*8 -: 8];
                            2'b10: data_out <= ETH_ARP_TYPE[15 - count*8 -: 8];
                        endcase
                    end
            endcase
        end
    end

endmodule