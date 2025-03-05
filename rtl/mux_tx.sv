module mux_tx

(
    // RGMII TX
    input   logic           aclk,
    input   logic           aresetn,
    output  logic           data_valid,
    output  logic   [7:0]   data_out,

    // Preamble and SFD
    input   logic           preamble_sfd_tx_start,
    input   logic           preamble_sfd_tx_done,
    input   logic   [7:0]   preamble_sfd_tx_data,

    // Ethernet Header
    input   logic           eth_header_ip_tx_done,
    input   logic           eth_header_arp_tx_done,
    input   logic   [7:0]   eth_header_tx_data,

    // IP Header
    input   logic           ip_header_tx_done,
    input   logic   [7:0]   ip_header_tx_data,

    // UDP Header
    input   logic           udp_header_tx_done,
    input   logic   [7:0]   udp_header_tx_data,

    // UDP Data
    input   logic           udp_data_tx_done,
    input   logic   [7:0]   udp_data_tx_data,

    // ARP Data
    input   logic           arp_data_tx_done,
    input   logic   [7:0]   arp_data_tx,

    // FCS
    input   logic           fcs_tx_done,
    input   logic   [7:0]   fcs_tx_data,
    
    output  logic           tx_frame_done
);

    logic   [3:0]   count;

    typedef enum logic [3:0] 
    {  
        WAIT_START,
        PREAMBLE_SFD,
        ETH_HEADER,
        IP_HEADER,
        UDP_HEADER,
        UDP_DATA,
        ARP_DATA,
        FCS,
        IPG
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT_START;
            count <= 'd0;
            tx_frame_done <= 'd0;
        end else begin
            case (state)
                WAIT_START:
                    begin
                        if (!preamble_sfd_tx_start) begin
                            state <= WAIT_START;
                        end else begin
                            state <= PREAMBLE_SFD;
                        end
                    end
                PREAMBLE_SFD:
                    begin
                        if (!preamble_sfd_tx_done) begin
                            state <= PREAMBLE_SFD;
                        end else begin
                            state <= ETH_HEADER;
                        end
                    end
                ETH_HEADER:
                    begin
                        case ({eth_header_arp_tx_done, eth_header_ip_tx_done})
                            2'b00: state <= ETH_HEADER;
                            2'b01: state <= IP_HEADER;
                            2'b10, 2'b11: state <= ARP_DATA;
                        endcase
                    end
                IP_HEADER:
                    begin
                        if (!ip_header_tx_done) begin
                            state <= IP_HEADER;
                        end else begin
                            state <= UDP_HEADER;
                        end
                    end
                UDP_HEADER:
                    begin
                        if (!udp_header_tx_done) begin
                            state <= UDP_HEADER;
                        end else begin
                            state <= UDP_DATA;
                        end
                    end
                UDP_DATA:
                    begin
                        if (!udp_data_tx_done) begin
                            state <= UDP_DATA;
                        end else begin
                            state <= FCS;
                        end
                    end
                ARP_DATA:
                    begin
                        if (!arp_data_tx_done) begin
                            state <= ARP_DATA;
                        end else begin
                            state <= FCS;
                        end
                    end
                FCS:
                    begin
                        if (!fcs_tx_done) begin
                            state <= FCS;
                        end else begin
                            state <= IPG;
                        end
                    end
                IPG:
                    begin
                        if (count != 10) begin
                            count <= count + 1;
                        end else begin
                            count <= 'd0;
                            state <= WAIT_START;
                        end

                        if (count == 9) begin
                            tx_frame_done <= 'd1;
                        end else begin
                            tx_frame_done <= 'd0;
                        end
                    end
            endcase
        end
    end

    always_comb begin
        case (state)
            PREAMBLE_SFD:
                begin
                    data_valid = 'd1;
                    data_out = preamble_sfd_tx_data;
                end
            ETH_HEADER:
                begin
                    data_valid = 'd1;
                    data_out = eth_header_tx_data;
                end
            IP_HEADER:
                begin
                    data_valid = 'd1;
                    data_out = ip_header_tx_data;
                end
            UDP_HEADER:
                begin
                    data_valid = 'd1;
                    data_out = udp_header_tx_data;
                end
            UDP_DATA:
                begin
                    data_valid = 'd1;
                    data_out = udp_data_tx_data;
                end
            ARP_DATA:
                begin
                    data_valid = 'd1;
                    data_out = arp_data_tx;
                end
            FCS:
                begin
                    data_valid = 'd1;
                    data_out = fcs_tx_data;
                end
            default:
                begin
                    data_valid = 'd0;
                    data_out = 'd0;
                end
        endcase
    end

endmodule