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

    localparam      AXI_DATA_WIDTH  =   32;
    localparam      AXI_DATA_DEPTH  =   256;

    logic           [AXI_DATA_WIDTH-1:0]                mem             [AXI_DATA_DEPTH];

    logic           [7:0]                               index_rd;
    logic           [7:0]                               index_wr;

    logic                                               flag_wr;
    logic                                               flag_rd;

    logic                                               flag_wr_sync_0;
    logic                                               flag_wr_sync_1;
    logic                                               flag_rd_sync_0;
    logic                                               flag_rd_sync_1;

    // Synchronizer WRITE
    always @(posedge aclk_wr)
    begin
        if (!aresetn_wr)
        begin
            flag_rd_sync_0 <= 'd0;
            flag_rd_sync_1 <= 'd0;
        end else
        begin
            flag_rd_sync_0 <= flag_rd;
            flag_rd_sync_1 <= flag_rd_sync_0;
        end
    end

    // Synchronizer READ
    always @(posedge aclk_rd)
    begin
        if (!aresetn_rd)
        begin
            flag_wr_sync_0 <= 'd0;
            flag_wr_sync_1 <= 'd0;
        end else
        begin
            flag_wr_sync_0 <= flag_wr;
            flag_wr_sync_1 <= flag_wr_sync_0;
        end
    end

    // FSM WRITE
    typedef enum logic [1:0]
    {  
        IDLE_WR,
        DONE_WR,
        WAIT_RD
    } state_type_wr;

    state_type_wr state_wr;

    always @(posedge aclk_wr)
    begin
        if (!aresetn_wr)
        begin
            state_wr <= IDLE_WR;
            s_axis_tready <= 'd0;
            index_wr <= 'd0;
            flag_wr <= 'd0;
        end else
        begin
            case (state_wr)
                IDLE_WR:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= IDLE_WR;
                        end else begin
                            if (s_axis_tlast) begin
                                state_wr <= DONE_WR;
                                flag_wr <= 'd1;
                            end else begin
                                index_wr <= index_wr + 1;
                            end

                            mem[index_wr] <= s_axis_tdata;
                        end

                        s_axis_tready <= 'd1;
                    end
                DONE_WR:
                    begin
                        state_wr <= WAIT_RD;
                        s_axis_tready <= 'd0;
                    end
                WAIT_RD:
                    begin
                        if (!flag_rd_sync_1) begin
                            state_wr <= WAIT_RD;
                        end else begin
                            state_wr <= IDLE_WR;
                            index_wr <= 'd0;
                        end

                        flag_wr <= 'd0;
                    end
            endcase
        end
    end

    // FSM READ
    typedef enum logic [1:0]
    {  
        WAIT_WR,
        BURST_RD,
        LAST_RD,
        DONE_RD
    } state_type_rd;

    state_type_rd state_rd;

    always @(posedge aclk_rd)
    begin
        if (!aresetn_rd)
        begin
            state_rd <= WAIT_WR;
            m_axis_tvalid <= 'd0;
            m_axis_tlast <= 'd0;
            index_rd <= 'd0;
            flag_rd <= 'd0;
        end else
        begin
            case (state_rd)
                WAIT_WR:
                    begin
                        if (!flag_wr_sync_1) begin
                            state_rd <= WAIT_WR; 
                        end else begin
                            state_rd <= BURST_RD; 
                        end
                    end
                BURST_RD:
                    begin
                        if (!m_axis_tready)
                        begin
                            state_rd <= BURST_RD;
                        end else
                        begin
                            if (index_rd != index_wr) begin
                                index_rd <= index_rd + 1;
                            end else begin
                                state_rd <= LAST_RD;
                                index_rd <= index_rd + 1;
                                m_axis_tlast <= 'd1;
                                flag_rd <= 'd1;
                            end

                            m_axis_tdata <= mem[index_rd];
                        end

                        m_axis_tvalid <= 'd1;
                    end
                LAST_RD:
                    begin
                        state_rd <= DONE_RD;
                        m_axis_tvalid <= 'd0;
                        m_axis_tlast <= 'd0;
                        index_rd <= 'd0;
                    end
                DONE_RD:
                    begin
                        state_rd <= WAIT_WR;
                        flag_rd <= 'd0;
                    end
            endcase
        end
    end

endmodule