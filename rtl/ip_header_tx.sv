module ip_header_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic           eth_header_ip_tx_done,

    input   logic   [31:0]  ip_s_addr,
    input   logic   [31:0]  ip_d_addr,

    input   logic   [15:0]  udp_len,

    output  logic   [7:0]   data_out,
    output  logic           ip_header_tx_done
);

    localparam  IPHL        =    8'h45;
    localparam  TOS         =    8'h00;
    localparam  IDP         =   16'hFF_FF;
    localparam  FLAG_OFFSET =   16'h00_00;
    localparam  TTL         =    8'hFF;
    localparam  IP_UDP_TYPE =    8'h11;

    logic   [2:0]   count;
    logic   [15:0]  len_sum;

    assign len_sum = 'd28 + udp_len;

    typedef enum logic [3:0]
    {  
        WAIT_START,
        TOS_TX,
        LEN_TX,
        IDP_TX,
        FLAG_OFFSET_TX,
        TTL_TX,
        IP_UDP_TYPE_TX,
        CHECKSUM_TX,
        IP_SOURCE_TX,
        IP_DESTINATION_TX
    } state_ip_type;

    state_ip_type state_ip;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_ip <= WAIT_START;
            count <= 'd0;
            ip_header_tx_done <= 'd0;
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

                        ip_header_tx_done <= 'd0;
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
                        state_ip <= IP_UDP_TYPE_TX;
                        data_out <= TTL;
                    end
                IP_UDP_TYPE_TX:
                    begin
                        state_ip <= CHECKSUM_TX;
                        data_out <= IP_UDP_TYPE;
                    end
                CHECKSUM_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= IP_SOURCE_TX;
                            count <= 'd0;
                        end

                        data_out <= 'd0;
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
                            ip_header_tx_done <= 'd1;
                        end

                        data_out <= ip_d_addr[31 - count*8 -: 8];
                    end
            endcase
        end
    end

endmodule