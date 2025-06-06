module icmp_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic           ip_header_tx_done,

    input   logic           icmp_request_done,
    input   logic   [15:0]  icmp_id,
    input   logic   [15:0]  icmp_seq_num,
    output  logic           eth_header_ip_icmp_tx_start,

    output  logic   [7:0]   data_out,
    output  logic           icmp_header_tx_done
);

    localparam  ICMP_TYPE_RESP  =   8'h00;
    localparam  ICMP_CODE       =   8'h00;
    localparam  PADDING         =   8'h00;

    logic   [15:0]  icmp_id_buf;
    logic   [15:0]  icmp_seq_num_buf;

    logic   [4:0]   count;

    logic           count_calc;
    logic   [31:0]  sum_reg;
    logic   [31:0]  sum;
    logic   [31:0]  carry;
    logic   [15:0]  checksum_calc;

    typedef enum logic [2:0]
    {  
        WAIT_REQUEST,
        TYPE_ICMP,
        CODE_ICMP,
        CHECKSUM_ICMP,
        ID_ICMP,
        SEQ_NUM_ICMP,
        PADDING_TX
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT_REQUEST;
            count <= 'd0;
            eth_header_ip_icmp_tx_start <= 'd0;
            icmp_header_tx_done <= 'd0;
        end else begin
            case (state)
                WAIT_REQUEST:
                    begin
                        if (!icmp_request_done) begin
                            state <= WAIT_REQUEST;
                        end else begin
                            state <= TYPE_ICMP;
                            icmp_id_buf <= icmp_id;
                            icmp_seq_num_buf <= icmp_seq_num;
                            eth_header_ip_icmp_tx_start <= 'd1;
                        end

                        icmp_header_tx_done <= 'd0;
                    end
                TYPE_ICMP:
                    begin
                        if (!ip_header_tx_done) begin
                            state <= TYPE_ICMP;
                        end else begin
                            state <= CODE_ICMP;
                            data_out <= ICMP_TYPE_RESP;
                            eth_header_ip_icmp_tx_start <= 'd0;
                        end
                    end
                CODE_ICMP:
                    begin
                        state <= CHECKSUM_ICMP;
                        data_out <= ICMP_CODE;
                    end
                CHECKSUM_ICMP:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= ID_ICMP;
                            count <= 'd0;
                        end

                        data_out <= checksum_calc[15 - count*8 -: 8];
                    end
                ID_ICMP:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= SEQ_NUM_ICMP;
                            count <= 'd0;
                        end

                        data_out <= icmp_id_buf[15 - count*8 -: 8];
                    end
                SEQ_NUM_ICMP:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= PADDING_TX;
                            count <= 'd0;
                        end

                        data_out <= icmp_seq_num_buf[15 - count*8 -: 8];
                    end
                PADDING_TX:
                    begin
                        if (count != 17) begin
                            count <= count + 1;
                        end else begin
                            state <= WAIT_REQUEST;
                            count <= 'd0;
                            icmp_header_tx_done <= 'd1;
                        end
                        
                        data_out <= PADDING;
                    end
            endcase
        end
    end

    // Calculation Checksum
    typedef enum logic [1:0] 
    {
        WAIT,
        SUM,
        FOLD,
        RESET_SUM
    } state_checksum_type;

    state_checksum_type state_checksum;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_checksum <= WAIT;
            count_calc <= 'd0;
            sum_reg <= 'd0;
            checksum_calc <= 'd0;
        end else begin
            case (state_checksum)
                WAIT: 
                    if (icmp_request_done) begin
                        state_checksum <= SUM;
                        sum_reg <= {ICMP_TYPE_RESP, ICMP_CODE};
                    end
                SUM: 
                    if (count_calc == 0) begin
                        count_calc <= 'd1;
                        sum_reg <= sum_reg + icmp_id_buf;
                    end else begin
                        state_checksum <= FOLD;
                        count_calc <= 'd0;
                        sum_reg <= sum_reg + icmp_seq_num_buf;
                    end
                FOLD: 
                    begin
                        sum_reg <= (sum_reg >> 16) + (sum_reg & 32'hFFFF);

                        if ((sum_reg >> 16) == 0) begin
                            state_checksum <= RESET_SUM;
                            checksum_calc <= ~sum_reg[15:0];
                        end
                    end
                RESET_SUM:
                    begin
                        state_checksum <= WAIT;
                        sum_reg <= 'd0;
                    end
            endcase
        end
    end

endmodule