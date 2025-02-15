module preamble_sfd_rx

(
    input   logic           mac_gmii_rx_clk,
    input   logic           mac_gmii_rx_rstn,

    input   logic   [7:0]   mac_gmii_rxd,
    input   logic           mac_gmii_rx_dv,
    input   logic           mac_gmii_rx_er,

    input   logic           last_byte_sent,
    input   logic           error,

    output  logic           preamble_sfd_valid
);

    localparam PREAMBLE = 8'h55;
    localparam SFD      = 8'hd5;

    logic           data_valid;
    logic   [2:0]   count;

    typedef enum logic [1:0] 
    {  
        IDLE,
        PREAMBLE_CHECK,
        SFD_CHECK,
        WAIT_LAST
    } state_type;

    state_type state;

    assign data_valid = mac_gmii_rx_dv && ~mac_gmii_rx_er;

    always_ff @(posedge mac_gmii_rx_clk) begin
        if (!mac_gmii_rx_rstn) begin
            state <= PREAMBLE_CHECK;
            count <= 'd0;
        end else begin
            case (state)
                PREAMBLE_CHECK:
                    begin
                        if (!(data_valid && (mac_gmii_rxd == PREAMBLE))) begin
                            state <= PREAMBLE_CHECK;
                            count <= 'd0;
                        end else begin
                            if (count != 6) begin
                                state <= PREAMBLE_CHECK;
                                count <= count + 1;
                            end else begin
                                state <= SFD_CHECK;
                                count <= 'd0;
                            end
                        end
                    end
                SFD_CHECK:
                    begin
                        if (!(data_valid && (mac_gmii_rxd == SFD))) begin
                            state <= PREAMBLE_CHECK;
                        end else begin
                            state <= WAIT_LAST;
                        end
                    end
                WAIT_LAST:
                    begin
                        if (!(last_byte_sent || error)) begin
                            state <= PREAMBLE_CHECK;
                        end else begin
                            state <= PREAMBLE_CHECK;
                        end
                    end
            endcase
        end
    end

    always_comb begin
        case (state)
            SFD_CHECK:
                begin
                    if (!(data_valid && (mac_gmii_rxd == SFD))) begin
                        preamble_sfd_valid = 'd0;
                    end else begin
                        preamble_sfd_valid = 'd1;
                    end
                end
            default:
                begin
                    preamble_sfd_valid = 'd0;
                end
        endcase
    end

endmodule