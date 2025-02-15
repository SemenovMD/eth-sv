module eth_header_rx

(
    input   logic           mac_gmii_rx_clk,
    input   logic           mac_gmii_rx_rstn,

    input   logic   [7:0]   mac_gmii_rxd,
    input   logic           mac_gmii_rx_dv,
    input   logic           mac_gmii_rx_er,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [47:0]  mac_s_addr,

    input   logic           preamble_sfd_valid,

    output  logic           eth_type_arp_valid,
    output  logic           eth_type_ip_valid,

    // ILA
    output  logic   [47:0]  mac_d_addr_buf_ila,
    output  logic   [47:0]  mac_s_addr_buf_ila
);

    localparam  ETH_ARP_TYPE    =   16'h08_06;
    localparam  ETH_IP_TYPE     =   16'h08_00; // IPv4

    localparam  MAC_W           =   48'hFF_FF_FF_FF_FF_FF;

    logic           data_valid;

    logic   [2:0]   count;

    logic   [47:0]  mac_d_addr_buf;
    logic   [47:0]  mac_s_addr_buf;
    logic   [7:0]   eth_type_buf;

    //
    assign mac_s_addr_buf_ila = mac_s_addr_buf;
    assign mac_d_addr_buf_ila = mac_d_addr_buf;
    //

    typedef enum logic [1:0]
    {  
        WAIT,
        MAC_DESTINATION,
        MAC_SOURCE,
        ETH_TYPE
    } state_type;

    state_type state;

    assign data_valid = mac_gmii_rx_dv && ~mac_gmii_rx_er;

    always_ff @(posedge mac_gmii_rx_clk) begin
        if (!mac_gmii_rx_rstn) begin
            state <= WAIT;
            count <= 'd0;
            mac_d_addr_buf <= 'd0;
            mac_s_addr_buf <= 'd0;
            eth_type_buf <= 'd0;
        end else begin
            case (state)
                WAIT:
                    begin
                        if (!preamble_sfd_valid) begin
                            state <= WAIT;
                        end else begin
                            state <= MAC_DESTINATION;
                        end
                    end
                MAC_DESTINATION:
                    begin
                        if (!data_valid) begin
                            state <= WAIT;
                            count <= 'd0;
                        end else
                        begin
                            if (count != 5) begin
                                count <= count + 1;
                            end else begin
                                state <= MAC_SOURCE;
                                count <= 'd0;
                            end
                        end

                        case (count)
                            count: mac_d_addr_buf[47 - count*8 -: 8] <= mac_gmii_rxd;
                        endcase
                    end
                MAC_SOURCE:
                    begin
                        if (!data_valid) begin
                            state <= WAIT;
                            count <= 'd0;
                        end else
                        begin
                            if (count != 5) begin
                                count <= count + 1;
                            end else begin
                                state <= ETH_TYPE;
                                count <= 'd0;
                            end
                        end

                        case (count)
                            count: mac_s_addr_buf[47 - count*8 -: 8] <= mac_gmii_rxd;
                        endcase
                    end
                ETH_TYPE:
                    begin
                        if (!data_valid) begin
                            state <= WAIT;
                            count <= 'd0;
                        end else
                        begin
                            if (count != 1) begin
                                count <= count + 1;
                            end else begin
                                state <= WAIT;
                                count <= 'd0;
                            end
                        end

                        if (count == 0) begin
                            eth_type_buf <= mac_gmii_rxd;
                        end else begin
                            eth_type_buf <= eth_type_buf;
                        end
                    end
            endcase
        end
    end

    always_comb begin
        case (state)
            ETH_TYPE:
                begin
                    if (count == 1)
                    begin
                        case ({eth_type_buf, mac_gmii_rxd})
                            ETH_ARP_TYPE:
                                begin
                                    if (mac_d_addr_buf == MAC_W) begin
                                        eth_type_arp_valid = 'd1;
                                        eth_type_ip_valid = 'd0;
                                    end else begin
                                        eth_type_arp_valid = 'd0;
                                        eth_type_ip_valid = 'd0;
                                    end
                                end
                            ETH_IP_TYPE:
                                begin
                                    if ((mac_d_addr_buf == mac_d_addr) && (mac_s_addr_buf == mac_s_addr)) begin
                                        eth_type_arp_valid = 'd0;
                                        eth_type_ip_valid = 'd1;
                                    end else begin
                                        eth_type_arp_valid = 'd0;
                                        eth_type_ip_valid = 'd0;
                                    end
                                end
                            default:
                                begin
                                    eth_type_arp_valid = 'd0;
                                    eth_type_ip_valid = 'd0;
                                end
                        endcase
                    end else
                    begin
                        eth_type_arp_valid = 'd0;
                        eth_type_ip_valid = 'd0;
                    end
                end
            default:
                begin
                    eth_type_arp_valid = 'd0;
                    eth_type_ip_valid = 'd0;
                end
        endcase
    end

endmodule