module fcs_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic           preamble_sfd_tx_done,
    input   logic   [7:0]   data_in,

    input   logic           arp_data_done,
    input   logic           udp_data_done,

    output  logic   [7:0]   data_out,
    output  logic           fcs_tx_done
);

    localparam  POLY_CRC    =   32'hEDB8_8320;
    localparam  INIT_CRC    =   32'hFFFF_FFFF;

    logic   [31:0]  crc_reg;
    logic   [31:0]  crc_next;
    logic   [31:0]  crc_final;

    logic   [1:0]   count;

    always_comb begin
        crc_next = crc_reg ^ {24'd0, data_in};

        for (int i = 0; i < 8; i++) begin
            crc_next = (crc_next[0]) ? ((crc_next >> 1) ^ POLY_CRC) : (crc_next >> 1);
        end
    end

    typedef enum logic [1:0] 
    {  
        WAIT_START,
        CALC_TX,
        FCS_TX
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT_START;
            count <= 'd0;
            crc_reg <= INIT_CRC;
        end else begin
            case (state)
                WAIT_START:
                    begin
                        if (!preamble_sfd_tx_done) begin
                            state <= WAIT_START;
                        end else begin
                            state <= CALC_TX;
                        end

                        crc_reg <= INIT_CRC;
                    end
                CALC_TX:
                    begin
                        if (!(arp_data_done || udp_data_done)) begin
                            state <= CALC_TX;
                        end else begin
                            state <= FCS_TX;
                        end

                        crc_reg <=  crc_next;
                    end
                FCS_TX:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                        end else begin
                            state <= WAIT_START;
                            count <= 'd0;
                        end
                    end
            endcase
        end
    end

    assign crc_final = ~crc_reg;

    always_comb begin
        case (state)
            FCS_TX:
                begin
                    data_out = crc_final[count*8 +: 8];

                    if (count != 3) begin
                        fcs_tx_done = 'd0;
                    end else begin
                        fcs_tx_done = 'd1;
                    end
                end
            default:
                begin
                    data_out = 'd0;
                    fcs_tx_done = 'd0;
                end
        endcase
    end

endmodule