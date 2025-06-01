module ip_header_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic           eth_header_ip_tx_done,
    input   logic           eth_header_ip_icmp_tx_start,

    input   logic   [31:0]  ip_s_addr,
    input   logic   [31:0]  ip_d_addr,

    input   logic   [15:0]  udp_len,

    output  logic   [7:0]   data_out,
    output  logic           ip_header_tx_udp_done,
    output  logic           ip_header_tx_icmp_done
);

    localparam  IPHL            =    8'h45;
    localparam  TOS             =    8'h00;
    localparam  IDP             =   16'hFF_FF;
    localparam  FLAG_OFFSET     =   16'h00_00;
    localparam  TTL             =    8'hF0;
    localparam  IP_UDP_TYPE     =    8'h11;
    localparam  IP_ICMP_TYPE    =    8'h01;

    logic   [2:0]   count;
    logic   [15:0]  len_sum;

    logic   [2:0]   count_calc;
    logic   [31:0]  sum_reg;
    logic   [31:0]  sum;
    logic   [31:0]  carry;
    logic   [15:0]  checksum_calc;

    assign len_sum = eth_header_ip_icmp_tx_start ? ('d28) : ('d28 + udp_len);

    typedef enum logic [3:0]
    {  
        WAIT_START,
        TOS_TX,
        LEN_TX,
        IDP_TX,
        FLAG_OFFSET_TX,
        TTL_TX,
        IP_TYPE_TX,
        CHECKSUM_TX,
        IP_SOURCE_TX,
        IP_DESTINATION_TX
    } state_ip_type;

    state_ip_type state_ip;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_ip <= WAIT_START;
            count <= 'd0;
            ip_header_tx_udp_done <= 'd0;
            ip_header_tx_icmp_done <= 'd0;
        end else begin
            case (state_ip)
                WAIT_START:
                    begin
                        if (!eth_header_ip_tx_done) begin
                            state_ip <= WAIT_START;
                        end else begin
                            state_ip <= TOS_TX;
                            data_out <= IPHL;
                        end

                        ip_header_tx_udp_done <= 'd0;
                        ip_header_tx_icmp_done <= 'd0;
                    end
                TOS_TX:
                    begin
                        state_ip <= LEN_TX;
                        data_out <= TOS;
                    end
                LEN_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= IDP_TX;
                            count <= 'd0;
                        end

                        data_out <= len_sum[15 - count*8 -: 8];
                    end
                IDP_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= FLAG_OFFSET_TX;
                            count <= 'd0;
                        end

                        data_out <= IDP[15 - count*8 -: 8];
                    end
                FLAG_OFFSET_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= TTL_TX;
                            count <= 'd0;
                        end

                        data_out <= FLAG_OFFSET[15 - count*8 -: 8];
                    end
                TTL_TX:
                    begin
                        state_ip <= IP_TYPE_TX;
                        data_out <= TTL;
                    end
                IP_TYPE_TX:
                    begin
                        if (!eth_header_ip_icmp_tx_start) begin
                            state_ip <= CHECKSUM_TX;
                            data_out <= IP_UDP_TYPE;
                        end else begin
                            state_ip <= CHECKSUM_TX;
                            data_out <= IP_ICMP_TYPE;
                        end
                    end
                CHECKSUM_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= IP_SOURCE_TX;
                            count <= 'd0;
                        end

                        data_out <= checksum_calc[15 - count*8 -: 8];
                    end
                IP_SOURCE_TX:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= IP_DESTINATION_TX;
                            count <= 'd0;
                        end

                        data_out <= ip_s_addr[31 - count*8 -: 8];
                    end
                IP_DESTINATION_TX:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= WAIT_START;
                            count <= 'd0;

                            if (!eth_header_ip_icmp_tx_start) begin
                                ip_header_tx_udp_done <= 'd1;
                            end else begin
                                ip_header_tx_icmp_done <= 'd1;
                            end
                        end

                        data_out <= ip_d_addr[31 - count*8 -: 8];
                    end
            endcase
        end
    end

    // Calculation Checksum
    typedef enum logic
    {  
        WAIT,
        SUM
    } state_checksum_type;

    state_checksum_type state_checksum;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_checksum <= WAIT;
            count_calc <= 'd0;
            sum_reg <= 'd0;
        end else begin
            case (state_checksum)
                WAIT:
                    begin
                        if (state_ip != TOS_TX) begin
                            state_checksum <= WAIT;
                        end else begin
                            state_checksum <= SUM;
                            sum_reg <= 'd0;
                        end
                    end
                SUM:
                    begin
                        if (count_calc != 7) begin
                            count_calc <= count_calc + 1;
                        end else begin
                            state_checksum <= WAIT;
                            count_calc <= 'd0;
                        end

                        case (count_calc)
                            0: sum_reg <= {IPHL, TOS} + len_sum;
                            1: sum_reg <= sum_reg + IDP;
                            2: sum_reg <= sum_reg + FLAG_OFFSET;
                            3: 
                                begin
                                    if (!eth_header_ip_icmp_tx_start) begin
                                        sum_reg <= sum_reg + {TTL, IP_UDP_TYPE};
                                    end else begin
                                        sum_reg <= sum_reg + {TTL, IP_ICMP_TYPE};
                                    end
                                end
                            4: sum_reg <= sum_reg + ip_s_addr[31:16];
                            5: sum_reg <= sum_reg + ip_s_addr[15:0];
                            6: sum_reg <= sum_reg + ip_d_addr[31:16];
                            7: sum_reg <= sum_reg + ip_d_addr[15:0];
                        endcase
                    end
            endcase
        end
    end

    always_comb begin
        carry = sum_reg >> 16;
        sum = (sum_reg & 32'h0000FFFF) + carry;

        carry = sum >> 16;
        sum = sum + carry;

        checksum_calc = ~sum[15:0];
    end
 
endmodule