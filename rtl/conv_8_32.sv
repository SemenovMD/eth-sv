module  conv_8_32

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [7:0]   data_in,
    input   logic           udp_data_valid,

    output  logic   [31:0]  m_axis_tdata,
    output  logic           m_axis_tvalid,
    input   logic           m_axis_tready
);

    logic   [1:0]   count;
    logic           flag;

    logic   [31:0]  data_buf;

    typedef enum logic [1:0] 
    {  
        IDLE_WR,
        DATA_WR,
        DONE_WR
    } state_type_wr;

    state_type_wr state_wr;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_wr <= IDLE_WR;
            count <= 'd0;
            flag <= 'd0;
        end else begin
            case (state_wr)
                IDLE_WR:
                    begin
                        if (!udp_data_valid) begin
                            state_wr <= IDLE_WR;
                        end else begin
                            state_wr <= DATA_WR;
                            count <= count + 1;
                            data_buf[31 - count*8 -: 8] <= data_in;
                        end
                        
                        flag <= 'd0;
                    end
                DATA_WR:
                    begin
                        if (!udp_data_valid) begin
                            state_wr <= DONE_WR;

                            case (count)
                                0: data_buf <= data_buf;
                                1: data_buf[23:0] <= 'd0;
                                2: data_buf[15:0] <= 'd0;
                                3: data_buf[7:0] <= 'd0;
                            endcase
                        end else begin
                            if (count != 3) begin
                                count <= count + 1;
                                flag <= 'd0;
                            end else begin
                                count <= 'd0;
                                flag <= 'd1;
                            end

                            data_buf[31 - count*8 -: 8] <= data_in;
                        end
                    end
                DONE_WR:
                    begin
                        state_wr <= IDLE_WR;
                        count <= 'd0;
                        flag <= 'd1;
                    end
            endcase


        end
    end

    typedef enum logic [1:0]
    {  
        IDLE_RD,
        WAIT_RD,
        HAND_RD
    } state_type_rd;

    state_type_rd state_rd;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_rd <= IDLE_RD;
            m_axis_tvalid <= 'd0;
        end else begin
            case (state_rd)
                IDLE_RD:
                    begin
                        if (!flag) begin
                            state_rd <= IDLE_RD;
                        end else begin
                            state_rd <= WAIT_RD;
                            m_axis_tdata <= data_buf;
                        end
                    end
                WAIT_RD:
                    begin
                        if (!m_axis_tready) begin
                            state_rd <= WAIT_RD;
                        end else begin
                            state_rd <= HAND_RD;
                        end

                        m_axis_tvalid <= 'd1;
                    end
                HAND_RD:
                    begin
                        state_rd <= IDLE_RD;
                        m_axis_tvalid <= 'd0;
                    end
            endcase
        end
    end

endmodule