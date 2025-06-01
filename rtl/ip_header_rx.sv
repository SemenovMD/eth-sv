module ip_header_rx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [7:0]   data_in,
    input   logic           data_valid,

    input   logic   [31:0]  ip_s_addr,
    input   logic   [31:0]  ip_d_addr,

    input   logic           eth_type_ip_valid,
    output  logic           ip_header_udp_done,
    output  logic           ip_header_icmp_done
);

    localparam  IPHL            =    8'h45;
    localparam  TOS             =    8'h00;
    localparam  LEN             =   16'h05_DC;
    localparam  IDP             =   16'hFF_FF;
    localparam  FLAG_OFFSET     =   16'h00_00;
    localparam  TTL             =    8'hFF;
    localparam  IP_UDP_TYPE     =    8'h11;
    localparam  IP_ICMP_TYPE    =    8'h01;

    logic   [2:0]   count;

    logic   [31:0]  ip_s_addr_buf;
    logic   [31:0]  ip_d_addr_buf;

    logic           aresetn_sum;

    logic           flag_udp;
    logic           flag_icmp;

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
        IP_TYPE_CHECK,
        IP_HEADER_CHECKSUM,
        IP_SOURCE,
        IP_DESTINATION,
        VALID
    } state_ip_type;

    state_ip_type state_ip;

    always_ff @(posedge aclk)
    begin
        if (!aresetn_sum) begin
            state_ip <= IPHL_CHECK;
            count <= 'd0;
            ip_header_udp_done <= 'd0;
            ip_header_icmp_done <= 'd0;
            flag_udp <= 'd0;
            flag_icmp <= 'd0;
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

                        ip_header_udp_done <= 'd0;
                        ip_header_icmp_done <= 'd0;

                        flag_udp <= 'd0;
                        flag_icmp <= 'd0;
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
                    end
                IDP_CHECK:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= FLAG_OFFSET_CHECK;
                            count <= 'd0;
                        end
                    end
                FLAG_OFFSET_CHECK:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= TTL_CHECK;
                            count <= 'd0;
                        end
                    end
                TTL_CHECK:
                    begin
                        state_ip <= IP_TYPE_CHECK;
                    end
                IP_TYPE_CHECK:
                    begin
                        case (data_in)
                            IP_UDP_TYPE:
                                begin
                                    state_ip <= IP_HEADER_CHECKSUM;
                                    flag_udp <= 'd1;
                                end
                            IP_ICMP_TYPE:
                                begin
                                    state_ip <= IP_HEADER_CHECKSUM;
                                    flag_icmp <= 'd1;
                                end
                            default:
                                begin
                                    state_ip <= IPHL_CHECK;
                                end
                        endcase
                    end
                IP_HEADER_CHECKSUM:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state_ip <= IP_SOURCE;
                            count <= 'd0;
                        end
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
                                state_ip <= IPHL_CHECK;

                                case ({flag_icmp, flag_udp})
                                    2'b01: ip_header_udp_done <= 'd1;
                                    2'b10: ip_header_icmp_done <= 'd1;
                                endcase
                            end else begin
                                state_ip <= IPHL_CHECK;
                            end

                            count <= 'd0;
                        end

                        ip_d_addr_buf[31 - count*8 -: 8] <= data_in;
                    end
            endcase
        end
    end

endmodule
