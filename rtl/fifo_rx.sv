module fifo_rx

(
    input   logic                           aclk,
    input   logic                           aresetn,
    
    input   logic                           crc_valid,

    input   logic   [32-1:0]                s_axis_tdata,
    input   logic                           s_axis_tvalid,
    input   logic                           s_axis_tlast,
    output  logic                           s_axis_tready,

    output  logic   [32-1:0]                m_axis_tdata,
    output  logic                           m_axis_tvalid,
    output  logic                           m_axis_tlast,
    input   logic                           m_axis_tready
);

    localparam  AXI_DATA_DEPTH  =   1024;
    localparam  AXI_DATA_WIDTH  =   32;

    logic   [AXI_DATA_WIDTH-1:0]    mem_fifo    [AXI_DATA_DEPTH-1:0];
    logic   [9:0]                   mem_index   [7:0];

    logic   [9:0]   index_wr;
    logic   [9:0]   index_rd;
    logic   [9:0]   index_rd_buf;
    logic   [2:0]   index_frame_wr;
    logic   [2:0]   index_frame_rd;
    logic   [2:0]   count;

    // FSM FIFO WR
    typedef enum logic [1:0] 
    {  
        IDLE_WR,
        HAND_WR,
        CHECKSUM_CRC,
        CLEAR
    } state_type_wr;

    state_type_wr state_wr;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_wr <= IDLE_WR;
            index_wr <= 'd0;
            count <= 'd0;
            s_axis_tready <= 'd0;
            index_frame_wr <= 'd0;
        end else begin
            case (state_wr)
                IDLE_WR:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= IDLE_WR;
                        end else begin
                            state_wr <= HAND_WR;
                            mem_fifo[index_wr] <= s_axis_tdata;
                            index_wr <= index_wr + 1;

                            if (s_axis_tlast) begin
                                state_wr <= CHECKSUM_CRC;
                            end

                            s_axis_tready <= 'd1;
                        end
                    end
                HAND_WR:
                    begin
                        state_wr <= IDLE_WR;
                        s_axis_tready <= 'd0;
                    end
                CHECKSUM_CRC:
                    begin
                        if (!crc_valid) begin
                            if (~&count) begin
                                count <= count + 1;
                            end else begin
                                state_wr <= IDLE_WR;
                                count <= 'd0;
                                index_wr <= mem_index[index_frame_wr];
                            end
                        end else begin
                            if (index_wr < AXI_DATA_DEPTH - 256 - 1) begin
                                state_wr <= IDLE_WR;
                                index_frame_wr <= index_frame_wr + 1; 
                            end else begin
                                state_wr <= CLEAR;
                            end

                            mem_index[index_frame_wr] <= index_wr;
                            count <= 'd0;
                        end

                        s_axis_tready <= 'd0;
                    end
                CLEAR:
                    begin
                        state_wr <= IDLE_WR;
                        index_frame_wr <= 'd0;
                        index_wr <= 'd0;
                    end
            endcase
        end
    end

    // FSM FIFO RD
    typedef enum logic [1:0] 
    {  
        IDLE_RD,
        BURST_RD,
        LAST_RD
    } state_type_rd;

    state_type_rd state_rd;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_rd <= IDLE_RD;
            index_rd <= 'd0;
            index_rd_buf <= 'd0;
            index_frame_rd <= 'd0;
            m_axis_tvalid <= 'd0;
            m_axis_tlast <= 'd0;
        end else begin
            case (state_rd)
                IDLE_RD:
                    begin
                        if (index_frame_wr == index_frame_rd) begin
                            state_rd <= IDLE_RD;
                        end else begin
                            state_rd <= BURST_RD;
                            index_rd_buf <= mem_index[index_frame_rd];
                        end
                    end
                BURST_RD:
                    begin
                        if (!m_axis_tready) begin
                            state_rd <= BURST_RD;
                        end else begin
                            if (index_rd != index_rd_buf - 1) begin
                                index_rd <= index_rd + 1;
                            end else begin
                                state_rd <= LAST_RD;
                                index_rd <= index_rd + 1;
                                m_axis_tlast <= 'd1;
                            end

                            m_axis_tdata <= mem_fifo[index_rd];
                        end

                        m_axis_tvalid <= 'd1;
                    end
                LAST_RD:
                    begin
                        state_rd <= IDLE_RD;
                        m_axis_tvalid <= 'd0;
                        m_axis_tlast <= 'd0;

                        if (index_rd < AXI_DATA_DEPTH - 256 - 1) begin
                            index_frame_rd <= index_frame_rd + 1;
                        end else begin
                            index_frame_rd <= 'd0;
                            index_rd <= 'd0;
                        end
                    end
            endcase
        end
    end

endmodule