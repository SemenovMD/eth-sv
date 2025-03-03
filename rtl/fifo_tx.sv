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

    localparam  AXI_DATA_DEPTH  =   256;

    logic   [31:0]  mem_fifo    [AXI_DATA_DEPTH-1:0];

    logic   [7:0]   index_wr;
    logic   [7:0]   index_rd;
    logic   [7:0]   index_buf;

    assign udp_len = (index_wr + 1) * 4;

    // FSM FIFO WR
    typedef enum logic [2:0] 
    {  
        WAIT_WR,
        BURST_WR,
        START_UDP,
        WAIT_UDP_HEADER_DONE,
        UDP_DATA,
        UDP_DATA_DONE
    } state_type_wr;

    state_type_wr state_wr;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_wr <= WAIT_WR;
            s_axis_tready <= 'd0;
            m_axis_tvalid <= 'd0;
            m_axis_tlast <= 'd0;
            index_wr <= 'd0;
            index_rd <= 'd0;
        end else begin
            case (state_wr)
                WAIT_WR:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= WAIT_WR;
                        end else begin
                            state_wr <= BURST_WR;
                            s_axis_tready <= 'd1;
                            index_wr <= index_wr + 1;
                            mem_fifo[index_wr] <= s_axis_tdata;
                        end
                    end
                BURST_WR:
                    begin
                        if (!s_axis_tvalid) begin
                            state_wr <= BURST_WR;
                        end else begin
                            if (s_axis_tlast) begin
                                state_wr <= START_UDP;
                                s_axis_tready <= 'd0;
                            end

                            index_wr <= index_wr + 1;
                            mem_fifo[index_wr] <= s_axis_tdata;
                        end
                    end
                START_UDP:
                    begin
                        state_wr <= WAIT_UDP_HEADER_DONE;
                        eth_header_ip_tx_start <= 'd1;
                    end
                WAIT_UDP_HEADER_DONE:
                    begin
                        if (!udp_header_tx_done) begin
                            state_wr <= WAIT_UDP_HEADER_DONE;
                        end else begin
                            state_wr <= UDP_DATA;
                            eth_header_ip_tx_start <= 'd1;
                            m_axis_tdata <= mem_fifo[index_rd];
                            m_axis_tvalid <= 'd1;
                            index_rd <= index_rd + 1;
                        end
                    end
                UDP_DATA:
                    begin
                        if (!m_axis_tready) begin
                            state_wr <= UDP_DATA;
                        end else begin
                            if (index_rd != index_wr) begin
                                state_wr <= UDP_DATA_DONE;
                                m_axis_tlast <= 'd1;
                            end

                            index_rd <= index_rd + 1;
                            m_axis_tdata <= mem_fifo[index_rd];
                        end
                    end
                UDP_DATA_DONE:
                    begin
                        state_wr <= WAIT_WR;
                        m_axis_tvalid <= 'd0;
                        m_axis_tlast <= 'd0;
                        index_rd <= 'd0;
                        index_wr <= 'd0;
                    end
            endcase
        end
    end

endmodule