module icmp_rx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [7:0]   data_in,
    input   logic           data_valid,

    input   logic           ip_header_icmp_done,
    
    output  logic           icmp_request_done,
    output  logic   [15:0]  icmp_id,
    output  logic   [15:0]  icmp_seq_num
);

    localparam  ICMP_TYPE_REQ   =   8'h08;
    localparam  ICMP_CODE       =   8'h00;

    logic           count;
    logic   [15:0]  crc_buf;

    logic           aresetn_sum;

    assign  aresetn_sum = aresetn & data_valid;

    // FSM
    typedef enum logic [2:0] 
    {
        TYPE_ICMP,
        CODE_ICMP,
        CHECKSUM_ICMP,
        ID_ICMP,
        SEQ_NUM_ICMP
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn_sum) begin
            state <= TYPE_ICMP;
            count <= 'd0;
            icmp_request_done <= 'd0;
        end else begin
            case (state)
                TYPE_ICMP:
                    begin
                        if (!ip_header_icmp_done) begin
                            state <= TYPE_ICMP;
                        end else begin
                            if (data_in != ICMP_TYPE_REQ) begin
                                state <= TYPE_ICMP;
                            end else begin
                                state <= CODE_ICMP;
                            end
                        end

                        icmp_request_done <= 'd0;
                    end
                CODE_ICMP:
                    begin
                        if (data_in != ICMP_CODE) begin
                            state <= TYPE_ICMP;
                        end else begin
                            state <= CHECKSUM_ICMP;
                        end
                    end
                CHECKSUM_ICMP:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= ID_ICMP;
                            count <= 'd0;
                        end

                        crc_buf[15 - count*8 -: 8] <= data_in;
                    end
                ID_ICMP:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= SEQ_NUM_ICMP;
                            count <= 'd0;
                        end

                        icmp_id[15 - count*8 -: 8] <= data_in;
                    end
                SEQ_NUM_ICMP:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= TYPE_ICMP;
                            count <= 'd0;
                            icmp_request_done <= 'd1;
                        end

                        icmp_seq_num[15 - count*8 -: 8] <= data_in;
                    end
            endcase
        end
    end

endmodule