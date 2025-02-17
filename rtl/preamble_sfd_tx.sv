module preamble_sfd_tx

(
    input   logic           aclk,
    input   logic           aresetn,
    
    input   logic           preamble_sfd_tx_start,
    output  logic           preamble_sfd_tx_done,
    output  logic   [7:0]   data_out
);

    localparam PREAMBLE = 8'h55;
    localparam SFD      = 8'hd5;

    logic   [2:0]   count;

    // FSM
    typedef enum logic [1:0]
    {  
        IDLE_TX,
        PREAMBLE_TX,
        SFD_TX,
        DONE_TX
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= IDLE_TX;
            count <= 'd0;
            data_out <= 'd0;
            preamble_sfd_tx_done <= 'd0;
        end else begin
            case (state)
                IDLE_TX:
                    begin
                        if (!preamble_sfd_tx_start) begin
                            state <= IDLE_TX;
                            data_out <= 'd0;
                        end else begin
                            state <= PREAMBLE_TX;
                            data_out <= PREAMBLE;
                        end

                        preamble_sfd_tx_done <= 'd0;
                    end
                PREAMBLE_TX:
                    begin
                        if (count != 'd5) begin
                            state <= PREAMBLE_TX;
                            count <= count + 1;
                        end else begin
                            state <= SFD_TX;
                            count <= 'd0;
                        end
                    end
                SFD_TX:
                    begin
                        state <= DONE_TX;
                        data_out <= SFD;
                    end
                DONE_TX:
                    begin
                        state <= IDLE_TX;
                        preamble_sfd_tx_done <= 'd1;
                    end
            endcase
        end
    end

endmodule