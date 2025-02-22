module mux_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    // RGMII TX
    output  logic           data_valid,
    output  logic   [7:0]   data_out,

    // Preamble and SFD
    input   logic           preamble_sfd_tx_start,
    input   logic           preamble_sfd_tx_done,
    input   logic   [7:0]   preamble_sfd_tx_data,

    // Ethernet Header
    input   logic           eth_header_arp_tx_done,
    input   logic   [7:0]   eth_header_arp_tx_data,

    // ARP Data
    input   logic           arp_data_tx_done,
    input   logic   [7:0]   arp_data_tx,

    // FCS
    input   logic           fcs_tx_done,
    input   logic   [7:0]   fcs_tx_data,

    // Flag
    output  logic           tx_frame_done
);

    logic   [31:0]  count;

    typedef enum logic [2:0] 
    {  
        WAIT_START,
        PREAMBLE_SFD,
        ETH_HEADER,
        ARP_DATA,
        FCS,
        DELAY
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT_START;
            tx_frame_done <= 'd0;
            count <= 'd0;
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
                        if (!eth_header_arp_tx_done) begin
                            state <= ETH_HEADER;
                        end else begin
                            state <= ARP_DATA;
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
                            state <= DELAY;
                            tx_frame_done <= 'd1;
                        end
                    end
                DELAY:
                    begin
                        if (count < 50_000_000 - 1) begin
                            count <= count + 1;
                        end else begin
                            count <= 'd0;
                            state <= WAIT_START;
                        end

                        tx_frame_done <= 'd0;
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
                    data_out = eth_header_arp_tx_data;
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