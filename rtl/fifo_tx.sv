module fifo_tx

(
    input   logic                           aclk,
    input   logic                           aresetn,

    input   logic                           udp_header_tx_done,
    output  logic                           eth_header_ip_tx_start,
    output  logic   [15:0]                  udp_len,

    input   logic   [31:0]                  s_axis_tdata,
    input   logic                           s_axis_tvalid,
    input   logic                           s_axis_tlast,
    output  logic                           s_axis_tready,

    output  logic   [31:0]                  m_axis_tdata,
    output  logic                           m_axis_tvalid,
    output  logic                           m_axis_tlast,
    input   logic                           m_axis_tready
);

    localparam  AXI_DATA_DEPTH  =   512;

    logic   [31:0]  mem_fifo    [AXI_DATA_DEPTH-1:0];

    logic   [8:0]   index_wr;
    logic   [7:0]   index_wr_0;
    logic   [7:0]   index_wr_1;
    logic   [8:0]   index_rd;

    logic           flag_frame_wr_0;
    logic           flag_frame_wr_1;

    logic           flag_frame_rd_0;
    logic           flag_frame_rd_1;

    logic           flag;

    assign udp_len = (index_wr + 1) * 4;

    // FSM WR
    typedef enum logic [2:0] 
    {  
        CHECK_RD_0,
        BURST_WR_0,
        FRAME_WR_0,
        CHECK_RD_START,
        CHECK_RD_1,
        BURST_WR_1,
        FRAME_WR_1
    } state_type_wr;

    state_type_wr state_wr;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_wr <= BURST_WR_0;
            s_axis_tready <= 'd0;
            index_wr <= 'd0;
            index_wr_0 <= 'd0;
            index_wr_1 <= 'd0;
            flag_frame_wr_0 <= 'd0;
            flag_frame_wr_1 <= 'd0;
            flag <= 'd0;
        end else begin
            case (state_wr)
                BURST_WR_0:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= BURST_WR_0;
                        end else begin
                            if (s_axis_tlast) begin
                                state_wr <= FRAME_WR_0;
                            end

                            s_axis_tready <= 'd1;
                            index_wr <= index_wr + 1;
                            mem_fifo[index_wr] <= s_axis_tdata;
                        end
                    end
                FRAME_WR_0:
                    begin
                        if (!flag) begin
                            state_wr <= CHECK_RD_START;
                        end else begin
                            state_wr <= CHECK_RD_1;
                        end

                        s_axis_tready <= 'd0;
                        flag_frame_wr_0 <= 'd1;
                        flag_frame_wr_1 <= 'd0;
                        index_wr_0 <= index_wr;
                    end
                CHECK_RD_START:
                    begin
                        state_wr <= BURST_WR_1;
                        index_wr <= 'd255;
                        flag <= 'd1;
                    end
                CHECK_RD_1:
                    begin
                        if (flag_frame_rd_1) begin
                            state_wr <= CHECK_RD_1;
                        end else begin
                            state_wr <= BURST_WR_1;
                            index_wr <= 'd255;
                        end
                    end
                BURST_WR_1:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= BURST_WR_1;
                        end else begin
                            if (s_axis_tlast) begin
                                state_wr <= FRAME_WR_1;
                            end

                            s_axis_tready <= 'd1;
                            index_wr <= index_wr + 1;
                            mem_fifo[index_wr] <= s_axis_tdata;
                        end
                    end
                FRAME_WR_1:
                    begin
                        state_wr <= CHECK_RD_0;
                        s_axis_tready <= 'd0;
                        flag_frame_wr_0 <= 'd0;
                        flag_frame_wr_1 <= 'd1;
                        index_wr_1 <= index_wr;
                    end
                CHECK_RD_0:
                    begin
                        if (flag_frame_rd_0) begin
                            state_wr <= CHECK_RD_0;
                        end else begin
                            state_wr <= BURST_WR_0;
                            index_wr <= 'd0;
                        end
                    end
            endcase
        end
    end

    // FSM RD
    typedef enum logic [2:0]
    {  
        CHECK_WR_0,
        WAIT_UDP_HEADER_DONE_0,
        UDP_DATA_0,
        UDP_DATA_DONE_0,
        CHECK_WR_1,
        WAIT_UDP_HEADER_DONE_1,
        UDP_DATA_1,
        UDP_DATA_DONE_1
    } state_type_rd;

    state_type_rd state_rd;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_rd <= CHECK_WR_0;
            flag_frame_rd_0 <= 'd0;
            flag_frame_rd_1 <= 'd0;
            m_axis_tvalid <= 'd0;
            m_axis_tlast <= 'd0;
            index_rd <= 'd0;
            eth_header_ip_tx_start <= 'd0;
        end else begin
            case (state_rd)
                CHECK_WR_0:
                    begin
                        if (!flag_frame_wr_0) begin
                            state_rd <= CHECK_WR_0;
                        end else begin
                            state_rd <= WAIT_UDP_HEADER_DONE_0;
                            eth_header_ip_tx_start <= 'd1;
                        end
                    end
                WAIT_UDP_HEADER_DONE_0:
                    begin
                        if (!udp_header_tx_done) begin
                            state_rd <= WAIT_UDP_HEADER_DONE_0;
                        end else begin
                            state_rd <= UDP_DATA_0;
                            eth_header_ip_tx_start <= 'd0;
                            m_axis_tdata <= mem_fifo[index_rd];
                            m_axis_tvalid <= 'd1;
                            index_rd <= index_rd + 1;
                        end
                    end
                UDP_DATA_0:
                    begin
                        if (!m_axis_tready) begin
                            state_rd <= UDP_DATA_0;
                        end else begin
                            if (index_rd == index_wr_0 - 2) begin
                                state_rd <= UDP_DATA_DONE_0;
                                m_axis_tlast <= 'd1;
                            end

                            index_rd <= index_rd + 1;
                            m_axis_tdata <= mem_fifo[index_rd];
                        end
                    end
                UDP_DATA_DONE_0:
                    begin
                        if (!m_axis_tready) begin
                            state_rd <= UDP_DATA_DONE_0;
                        end else begin
                            state_rd <= CHECK_WR_1;
                            m_axis_tvalid <= 'd0;
                            m_axis_tlast <= 'd0;
                            index_rd <= 'd255;
                            flag_frame_rd_0 <= 'd1;
                            flag_frame_rd_1 <= 'd0;
                        end
                    end
                CHECK_WR_1:
                    begin
                        if (!flag_frame_wr_1) begin
                            state_rd <= CHECK_WR_1;
                        end else begin
                            state_rd <= WAIT_UDP_HEADER_DONE_1;
                            eth_header_ip_tx_start <= 'd1;
                        end
                    end
                WAIT_UDP_HEADER_DONE_1:
                    begin
                        if (!udp_header_tx_done) begin
                            state_rd <= WAIT_UDP_HEADER_DONE_1;
                        end else begin
                            state_rd <= UDP_DATA_1;
                            eth_header_ip_tx_start <= 'd0;
                            m_axis_tdata <= mem_fifo[index_rd];
                            m_axis_tvalid <= 'd1;
                            index_rd <= index_rd + 1;
                        end
                    end
                UDP_DATA_1:
                    begin
                        if (!m_axis_tready) begin
                            state_rd <= UDP_DATA_1;
                        end else begin
                            if (index_rd == 256 + index_wr_1 - 2) begin
                                state_rd <= UDP_DATA_DONE_1;
                                m_axis_tlast <= 'd1;
                            end

                            index_rd <= index_rd + 1;
                            m_axis_tdata <= mem_fifo[index_rd];
                        end
                    end
                UDP_DATA_DONE_1:
                    begin
                        if (!m_axis_tready) begin
                            state_rd <= UDP_DATA_DONE_1;
                        end else begin
                            state_rd <= CHECK_WR_0;
                            m_axis_tvalid <= 'd0;
                            m_axis_tlast <= 'd0;
                            index_rd <= 'd0;
                            flag_frame_rd_0 <= 'd0;
                            flag_frame_rd_1 <= 'd1;
                        end
                    end
            endcase
        end
    end

endmodule