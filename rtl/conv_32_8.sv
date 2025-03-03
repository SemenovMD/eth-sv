module conv_32_8

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [31:0]  s_axis_tdata,
    input   logic           s_axis_tvalid,
    input   logic           s_axis_tlast,
    output  logic           s_axis_tready,

    output  logic   [7:0]   data_out,
    output  logic           udp_data_tx_done
);

    logic   [1:0]   count;

    logic   [23:0]  data_buf;

    typedef enum logic [1:0]
    {  
        IDLE,
        HAND,
        LAST
    } state_type;
    
    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= IDLE;
            s_axis_tready <= 'd0;
            count <= 'd0;
            udp_data_tx_done <= 'd0;
        end else begin
            case (state)
                IDLE:
                    begin
                        if (!s_axis_tvalid) begin
                            state <= IDLE;
                        end else begin
                            if (!s_axis_tlast) begin
                                state <= HAND;
                            end else begin
                                state <= LAST;
                            end
                            
                            s_axis_tready <= 'd1;
                            data_buf <= s_axis_tdata[23:0];
                            data_out <= s_axis_tdata[31:24];
                        end

                        udp_data_tx_done <= 'd0;
                    end
                HAND:
                    begin
                        if (count != 2) begin
                            count <= count + 1;
                        end else begin
                            state <= IDLE;
                            count <= 'd0;
                        end

                        data_out <= data_buf[23 - count*8 -: 8];
                        s_axis_tready <= 'd0;
                    end
                LAST:
                    begin
                        if (count != 2) begin
                            count <= count + 1;
                        end else begin
                            state <= IDLE;
                            count <= 'd0;
                            udp_data_tx_done <= 'd1;
                        end

                        data_out <= data_buf[23 - count*8 -: 8];
                        s_axis_tready <= 'd0;
                    end
            endcase
        end
    end

endmodule