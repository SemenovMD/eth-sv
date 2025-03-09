module asyn_fifo_rx

(
    input   logic           aclk_wr,
    input   logic           aresetn_wr,

    input   logic           aclk_rd,
    input   logic           aresetn_rd,

    output  logic   [31:0]  m_axis_tdata,
    output  logic           m_axis_tvalid,
    output  logic           m_axis_tlast,
    input   logic           m_axis_tready,

    input   logic   [31:0]  s_axis_tdata,
    input   logic           s_axis_tvalid,
    input   logic           s_axis_tlast,
    output  logic           s_axis_tready
);

    localparam      AXI_DATA_DEPTH  =   256;

    logic   [31:0]  mem_0 [AXI_DATA_DEPTH-1:0];
    logic   [31:0]  mem_1 [AXI_DATA_DEPTH-1:0];

    logic   [7:0]   index_wr_0;
    logic   [7:0]   index_wr_1;
    logic   [7:0]   index_rd;

    logic           frame_wr_0;
    logic           frame_wr_1;

    logic           frame_wr_0_sync_0;
    logic           frame_wr_0_sync_1;
    logic           frame_wr_1_sync_0;
    logic           frame_wr_1_sync_1;

    logic           frame_rd_0;
    logic           frame_rd_1;

    logic           frame_rd_0_sync_0;
    logic           frame_rd_0_sync_1;
    logic           frame_rd_1_sync_0;
    logic           frame_rd_1_sync_1;

    logic           flag;

    // SYNC WRITE
    always_ff @(posedge aclk_wr)
    begin
        if (!aresetn_wr)
        begin
            frame_rd_0_sync_0 <= 'd0;
            frame_rd_0_sync_1 <= 'd0;
        end else
        begin
            frame_rd_0_sync_0 <= frame_rd_0;
            frame_rd_0_sync_1 <= frame_rd_0_sync_0;
        end
    end

    always_ff @(posedge aclk_wr)
    begin
        if (!aresetn_wr)
        begin
            frame_rd_1_sync_0 <= 'd0;
            frame_rd_1_sync_1 <= 'd0;
        end else
        begin
            frame_rd_1_sync_0 <= frame_rd_1;
            frame_rd_1_sync_1 <= frame_rd_1_sync_0;
        end
    end

    // SYNC READ
    always_ff @(posedge aclk_rd)
    begin
        if (!aresetn_rd)
        begin
            frame_wr_0_sync_0 <= 'd0;
            frame_wr_0_sync_1 <= 'd0;
        end else
        begin
            frame_wr_0_sync_0 <= frame_wr_0;
            frame_wr_0_sync_1 <= frame_wr_0_sync_0;
        end
    end

    always_ff @(posedge aclk_rd)
    begin
        if (!aresetn_rd)
        begin
            frame_wr_1_sync_0 <= 'd0;
            frame_wr_1_sync_1 <= 'd0;
        end else
        begin
            frame_wr_1_sync_0 <= frame_wr_1;
            frame_wr_1_sync_1 <= frame_wr_1_sync_0;
        end
    end

    // FSM WRITE
    typedef enum logic [2:0]
    {
        WAIT_VALID_WR_0,
        BURST_WR_0,
        FRAME_WR_0,
        CHECK_RD_1,
        WAIT_VALID_WR_1,
        BURST_WR_1,
        FRAME_WR_1,
        CHECK_RD_0
    } state_type_wr;

    state_type_wr state_wr;

    always_ff @(posedge aclk_wr)
    begin
        if (!aresetn_wr)
        begin
            state_wr <= WAIT_VALID_WR_0;
            s_axis_tready <= 'd0;
            index_wr_0 <= 'd0;
            index_wr_1 <= 'd0;
            frame_wr_0 <= 'd0;
            frame_wr_1 <= 'd0;
            flag <= 'd0;
        end else
        begin
            case (state_wr)
                WAIT_VALID_WR_0:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= WAIT_VALID_WR_0;
                        end else begin
                            state_wr <= BURST_WR_0;
                            s_axis_tready <= 'd1;
                            mem_0[index_wr_0] <= s_axis_tdata;
                        end
                    end
                BURST_WR_0:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= BURST_WR_0;
                        end else begin
                            if (s_axis_tlast) begin
                                state_wr <= FRAME_WR_0;
                                s_axis_tready <= 'd0;
                            end else begin
                                index_wr_0 <= index_wr_0 + 1;
                            end

                            mem_0[index_wr_0] <= s_axis_tdata;
                        end
                    end
                FRAME_WR_0:
                    begin
                        if (!flag) begin
                            state_wr <= WAIT_VALID_WR_1;
                            flag <= 'd1;
                        end else begin
                            state_wr <= CHECK_RD_1;
                        end

                        frame_wr_0 <= 'd1;
                        frame_wr_1 <= 'd0;
                    end
                CHECK_RD_1:
                    begin
                        if (!frame_rd_1_sync_1) begin
                            state_wr <= CHECK_RD_1;
                        end else begin
                            state_wr <= WAIT_VALID_WR_1;
                            index_wr_1 <= 'd0;
                        end
                    end
                WAIT_VALID_WR_1:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= WAIT_VALID_WR_1;
                        end else begin
                            state_wr <= BURST_WR_1;
                            s_axis_tready <= 'd1;
                            mem_1[index_wr_1] <= s_axis_tdata;
                        end
                    end
                BURST_WR_1:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= BURST_WR_1;
                        end else begin
                            if (s_axis_tlast) begin
                                state_wr <= FRAME_WR_1;
                                s_axis_tready <= 'd0;
                            end else begin
                                index_wr_1 <= index_wr_1 + 1;
                                s_axis_tready <= 'd1;
                            end

                            mem_1[index_wr_1] <= s_axis_tdata;
                        end
                    end
                FRAME_WR_1:
                    begin
                        state_wr <= CHECK_RD_0;
                        frame_wr_0 <= 'd0;
                        frame_wr_1 <= 'd1;
                    end
                CHECK_RD_0:
                    begin
                        if (!frame_rd_0_sync_1) begin
                            state_wr <= CHECK_RD_0;
                        end else begin
                            state_wr <= WAIT_VALID_WR_0;
                            index_wr_0 <= 'd0;
                        end
                    end
            endcase
        end
    end

    // FSM READ
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

    always_ff @(posedge aclk_rd)
    begin
        if (!aresetn_rd)
        begin
            state_rd <= CHECK_WR_0;
            m_axis_tvalid <= 'd0;
            m_axis_tlast <= 'd0;
            index_rd <= 'd0;
            frame_rd_0 <= 'd0;
            frame_rd_1 <= 'd0;
        end else
        begin
            case (state_rd)
                CHECK_WR_0:
                    begin
                        if (!frame_wr_0_sync_1) begin
                            state_rd <= CHECK_WR_0;
                        end else begin
                            state_rd <= WAIT_UDP_HEADER_DONE_0;
                        end
                    end
                WAIT_UDP_HEADER_DONE_0:
                    begin
                        state_rd <= UDP_DATA_0;
                        m_axis_tdata <= mem_0[index_rd];
                        m_axis_tvalid <= 'd1;
                        index_rd <= index_rd + 1;
                    end
                UDP_DATA_0:
                    begin
                        if (!m_axis_tready) begin
                            state_rd <= UDP_DATA_0;
                        end else begin
                            if (index_rd == index_wr_0) begin
                                state_rd <= UDP_DATA_DONE_0;
                                m_axis_tlast <= 'd1;
                            end

                            index_rd <= index_rd + 1;
                            m_axis_tdata <= mem_0[index_rd];
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
                            index_rd <= 'd0;
                            frame_rd_0 <= 'd1;
                            frame_rd_1 <= 'd0;
                        end
                    end
                CHECK_WR_1:
                    begin
                        if (!frame_wr_1_sync_1) begin
                            state_rd <= CHECK_WR_1;
                        end else begin
                            state_rd <= WAIT_UDP_HEADER_DONE_1;
                        end
                    end
                WAIT_UDP_HEADER_DONE_1:
                    begin
                        state_rd <= UDP_DATA_1;
                        m_axis_tdata <= mem_1[index_rd];
                        m_axis_tvalid <= 'd1;
                        index_rd <= index_rd + 1;
                    end
                UDP_DATA_1:
                    begin
                        if (!m_axis_tready) begin
                            state_rd <= UDP_DATA_1;
                        end else begin
                            if (index_rd == index_wr_1) begin
                                state_rd <= UDP_DATA_DONE_1;
                                m_axis_tlast <= 'd1;
                            end

                            index_rd <= index_rd + 1;
                            m_axis_tdata <= mem_1[index_rd];
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
                            frame_rd_0 <= 'd0;
                            frame_rd_1 <= 'd1;
                        end
                    end
            endcase
        end
    end

endmodule