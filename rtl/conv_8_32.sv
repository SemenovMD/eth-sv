module  conv_8_32

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [7:0]   data_in,
    input   logic           udp_data_valid,
    input   logic           udp_data_tlast,

    output  logic   [31:0]  m_axis_tdata,
    output  logic           m_axis_tvalid,
    output  logic           m_axis_tlast,
    input   logic           m_axis_tready
);

    logic   [1:0]   count;
    logic           flag;
    logic           flag_last;
    logic           flag_reg;

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
            flag_last <= 'd0;
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
                    end
                DATA_WR:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                            flag <= 'd0;
                        end else begin
                            count <= 'd0;

                            if (udp_data_tlast) begin
                                state_wr <= DONE_WR;
                                flag_last <= 'd1;
                            end else begin
                                flag <= 'd1;
                            end
                        end

                        data_buf[31 - count*8 -: 8] <= data_in;
                    end
                DONE_WR:
                    begin
                        state_wr <= IDLE_WR;
                        flag <= 'd0;
                        flag_last <= 'd0;
                        count <= 'd0;
                    end
            endcase
        end
    end

    typedef enum logic
    {  
        IDLE_RD,
        HAND_RD
    } state_type_rd;

    state_type_rd state_rd;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_rd <= IDLE_RD;
            m_axis_tvalid <= 'd0;
            m_axis_tlast <= 'd0;
        end else begin
            case (state_rd)
                IDLE_RD: 
                    begin
                        if (!(flag || flag_last)) begin
                            state_rd <= IDLE_RD;
                        end else begin
                            state_rd <= HAND_RD;
                            m_axis_tdata <= data_buf;
                            m_axis_tvalid <= 'd1;
                            m_axis_tlast <= flag_last;
                        end
                    end
                HAND_RD: 
                    begin
                        if (!m_axis_tready) begin
                            state_rd <= HAND_RD;
                        end else begin
                            state_rd <= IDLE_RD;
                            m_axis_tvalid <= 'd0;
                            m_axis_tlast <= 'd0;
                        end
                    end
            endcase
        end
    end

endmodule