module preamble_sfd_tx

(
    input   logic           aclk,
    input   logic           aresetn,
    
    input   logic           preamble_sfd_tx_start,
    output  logic           preamble_sfd_tx_done,
    output  logic   [7:0]   data_out,

    input   logic           tx_frame_done
);

    localparam PREAMBLE = 8'h55;
    localparam SFD      = 8'hd5;

    logic   [2:0]   count;

    typedef enum logic [1:0]
    {  
        WAIT_START,
        PREAMBLE_TX,
        SFD_TX,
        WAIT_CRC
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT_START;
            count <= 'd0;
            preamble_sfd_tx_done <= 'd0;
        end else begin
            case (state)
                WAIT_START:
                    begin
                        if (!preamble_sfd_tx_start) begin
                            state <= WAIT_START;
                        end else begin
                            state <= PREAMBLE_TX;
                            data_out <= PREAMBLE;
                            count <= count + 1;
                        end

                        preamble_sfd_tx_done <= 'd0;
                    end
                PREAMBLE_TX:
                    begin
                        if (count != 'd6) begin
                            count <= count + 1;
                        end else begin
                            state <= SFD_TX;
                            count <= 'd0;
                        end
                    end
                SFD_TX:
                    begin
                        state <= WAIT_CRC;
                        data_out <= SFD;
                        preamble_sfd_tx_done <= 'd1;
                    end
                WAIT_CRC:
                    begin
                        if (!tx_frame_done) begin
                            state <= WAIT_CRC;
                        end else begin
                            state <= WAIT_START;
                        end

                        preamble_sfd_tx_done <= 'd0;
                    end
            endcase
        end
    end

endmodule