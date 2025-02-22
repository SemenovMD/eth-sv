module ip_header_rx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [7:0]   data_in,
    input   logic           data_valid,

    input   logic   [31:0]  ip_s_addr,
    input   logic   [31:0]  ip_d_addr,

    input   logic           eth_type_ip_valid,
    output  logic           ip_header_valid,

    output  logic   [15:0]  checksum_calc_pin,
    output  logic   [3:0]   state_ip_pin
);

    ///
    assign state_ip_pin = state_ip;
    assign checksum_calc_pin = checksum_calc;
    ///

    localparam  IPHL        =    8'h45;
    localparam  TOS         =    8'h00;
    localparam  LEN         =   16'h05_DC;
    localparam  IDP         =   16'hFF_FF;
    localparam  FLAG_OFFSET =   16'h00_00;
    localparam  TTL         =    8'hFF;
    localparam  IP_UDP_TYPE =    8'h11;

    logic   [2:0]   count;

    logic   [15:0]  len_buf;
    logic   [15:0]  idp_buf;
    logic   [7:0]   ttl_buf;
    logic   [15:0]  checksum_buf;
    logic   [31:0]  ip_s_addr_buf;
    logic   [31:0]  ip_d_addr_buf;

    logic   [31:0]  sum_reg;
    logic   [31:0]  sum;
    logic   [31:0]  carry;
    logic   [15:0]  checksum_calc;

    logic           aresetn_sum;

    assign  aresetn_sum = aresetn & data_valid;

    // FSM
    typedef enum logic [3:0] 
    {
        IPHL_CHECK,
        TOS_CHECK,
        LEN_CHECK,
        IDP_CHECK,
        FLAG_OFFSET_CHECK,
        TTL_CHECK,
        IP_UDP_TYPE_CHECK,
        IP_HEADER_CHECKSUM,
        IP_SOURCE,
        IP_DESTINATION,
        DONE
    } state_ip_type;

    state_ip_type state_ip;

    always_ff @(posedge aclk)
    begin
        if (!aresetn_sum) begin
            state_ip <= IPHL_CHECK;
            count <= 'd0;
            ip_header_valid <= 'd0;
        end else begin
            case (state_ip)
                IPHL_CHECK:
                    begin
                        if (!eth_type_ip_valid) begin
                            state_ip <= IPHL_CHECK;
                        end else begin
                            if (data_in != IPHL) begin
                                state_ip <= IPHL_CHECK;
                            end else begin
                                state_ip <= TOS_CHECK;
                            end
                        end

                        ip_header_valid <= 'd0;
                    end
                TOS_CHECK:
                    begin
                        if (data_in != TOS) begin
                            state_ip <= IPHL_CHECK;
                        end else begin
                            state_ip <= LEN_CHECK;
                        end
                    end
                LEN_CHECK:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= IDP_CHECK;
                            count <= 'd0;
                        end

                        len_buf[15 - count*8 -: 8] <= data_in;
                    end
                IDP_CHECK:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= FLAG_OFFSET_CHECK;
                            count <= 'd0;
                        end

                        idp_buf[15 - count*8 -: 8] <= data_in;
                    end
                FLAG_OFFSET_CHECK:
                    begin
                        if (data_in != 8'h00) begin
                            state_ip <= IPHL_CHECK;
                            count <= 'd0;
                        end else begin
                            if (count != 1) begin
                                count <= count + 1;
                            end else begin
                                state_ip <= TTL_CHECK;
                                count <= 'd0;
                            end
                        end
                    end
                TTL_CHECK:
                    begin
                        state_ip <= IP_UDP_TYPE_CHECK;
                        ttl_buf <= data_in;
                    end
                IP_UDP_TYPE_CHECK:
                    begin
                        if (data_in != IP_UDP_TYPE) begin
                            state_ip <= IPHL_CHECK;
                        end else begin
                            state_ip <= IP_HEADER_CHECKSUM;
                        end
                    end
                IP_HEADER_CHECKSUM:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= IP_SOURCE;
                            count <= 'd0;
                        end

                        checksum_buf[15 - count*8 -: 8] <= data_in;
                    end
                IP_SOURCE:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= IP_DESTINATION;
                            count <= 'd0;
                        end

                        ip_s_addr_buf[31 - count*8 -: 8] <= data_in;
                    end
                IP_DESTINATION:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                        end else begin
                            if ((ip_s_addr_buf == ip_s_addr) && ({ip_d_addr_buf[31:8], data_in} == ip_d_addr)) begin
                                state_ip <= DONE;
                                count <= 'd0;
                            end else begin
                                state_ip <= IPHL_CHECK;
                                count <= 'd0;
                            end
                        end

                        ip_d_addr_buf[31 - count*8 -: 8] <= data_in;
                    end
                DONE:
                    begin
                        state_ip <= IPHL_CHECK;

                        if (checksum_buf == checksum_calc) begin
                            ip_header_valid <= 'd1;
                        end
                    end
            endcase
        end
    end

    // Calculation Checksum
    typedef enum logic [2:0] 
    {  
        STAGE_0,
        STAGE_1,
        STAGE_2,
        STAGE_3,
        STAGE_4,
        DELAY,
        CLEAR
    } state_checksum_type;

    state_checksum_type state_checksum;

    always_ff @(posedge aclk) begin
        if (!aresetn_sum) begin
            state_checksum <= STAGE_0;
            sum_reg <= 'd0;
        end else begin
            case (state_checksum)
                STAGE_0:
                    begin
                        if (!((state_ip == IP_SOURCE) && (count == 3))) begin
                            state_checksum <= STAGE_0;
                        end else begin
                            state_checksum <= STAGE_1;
                            sum_reg <= {IPHL, TOS} + len_buf;
                        end
                    end
                STAGE_1:
                    begin
                        state_checksum <= STAGE_2;
                        sum_reg <= sum_reg + idp_buf + FLAG_OFFSET;
                    end
                STAGE_2:
                    begin
                        state_checksum <= STAGE_3;
                        sum_reg <= sum_reg + {ttl_buf, IP_UDP_TYPE} + 16'h0000;
                    end
                STAGE_3:
                    begin
                        state_checksum <= STAGE_4;
                        sum_reg <= sum_reg + ip_s_addr_buf[31:16] + ip_s_addr_buf[15:0];
                    end
                STAGE_4:
                    begin
                        state_checksum <= DELAY;
                        sum_reg <= sum_reg + ip_d_addr_buf[31:16] + {ip_d_addr_buf[15:8], data_in};
                    end
                DELAY:
                    begin
                        state_checksum <= CLEAR;
                    end
                CLEAR:
                    begin
                        state_checksum <= STAGE_0;
                        sum_reg <= 'd0;
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