module preamble_sfd_rx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [7:0]   data_in,
    input   logic           data_valid,

    output  logic           preamble_sfd_valid
);

    localparam PREAMBLE = 8'h55;
    localparam SFD      = 8'hd5;

    logic   [2:0]   count;

    logic           aresetn_sum;

    assign  aresetn_sum = aresetn & data_valid;

    typedef enum logic [1:0] 
    {  
        PREAMBLE_CHECK,
        SFD_CHECK,
        WAIT
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn_sum) begin
            state <= PREAMBLE_CHECK;
            count <= 'd0;
            preamble_sfd_valid <= 'd0;
        end else begin
            case (state)
                PREAMBLE_CHECK:
                    begin
                        if (data_in != PREAMBLE) begin
                            state <= PREAMBLE_CHECK;
                            count <= 'd0;
                        end else begin
                            if (count != 6) begin
                                count <= count + 1;
                            end else begin
                                state <= SFD_CHECK;
                                count <= 'd0;
                            end
                        end
                    end
                SFD_CHECK:
                    begin
                        if (data_in != SFD) begin
                            state <= PREAMBLE_CHECK;
                        end else begin
                            state <= WAIT;
                            preamble_sfd_valid <= 'd1;
                        end
                    end
                WAIT:
                    begin
                        state <= WAIT;
                        preamble_sfd_valid <= 'd0;
                    end
            endcase
        end
    end

endmodule