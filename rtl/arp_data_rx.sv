module arp_data_rx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [7:0]   data_in,
    input   logic           data_valid,

    // Request
    output  logic   [47:0]  mac_s_addr,
    input   logic   [31:0]  ip_s_addr,
    input   logic   [47:0]  mac_d_addr,
    input   logic   [31:0]  ip_d_addr,

    input   logic           eth_type_arp_valid,
    output  logic           arp_data_valid
);

    localparam  HTYPE       =   16'h00_01;
    localparam  PTYPE       =   16'h08_00;
    localparam  HLEN        =    8'h06;
    localparam  PLEN        =    8'h04;
    localparam  OPER_RQ     =   16'h00_01;
    localparam  OPER_RESP   =   16'h00_02;

    localparam  MAC_Z       =   48'h00_00_00_00_00_00;

    logic   [7:0]   arp_buf;
    logic           oper_flag;
    logic   [2:0]   count;

    logic   [31:0]  ip_s_addr_buf;
    logic   [47:0]  mac_d_addr_buf;
    logic   [31:0]  ip_d_addr_buf;

    logic           aresetn_sum;

    assign aresetn_sum = aresetn & data_valid;

    // FSM
    typedef enum logic [3:0] 
    {  
        WAIT,
        HTYPE_CHECK,
        PTYPE_CHECK,
        HLEN_CHECK,
        PLEN_CHECK,
        OPER_CHECK,
        MAC_SOURCE,
        IP_SOURCE,
        MAC_DESTINATION,
        IP_DESTINATION
    } state_type_arp;

    state_type_arp state_arp;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_arp <= WAIT;
            count <= 'd0;
            arp_data_valid <= 'd0;
        end else begin
            case (state_arp)
                WAIT:
                    begin
                        if (!eth_type_arp_valid) begin
                            state_arp <= WAIT;
                        end else begin
                            state_arp <= HTYPE_CHECK;
                            arp_buf <= data_in;
                        end

                        arp_data_valid <= 'd0;
                    end
                HTYPE_CHECK:
                    begin
                        if ({arp_buf, data_in} != HTYPE) begin
                            state_arp <= WAIT;
                            count <= 'd0;
                        end else begin
                            state_arp <= PTYPE_CHECK;
                            count <= 'd0;
                        end
                    end
                PTYPE_CHECK:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            if ({arp_buf, data_in} != PTYPE) begin
                                state_arp <= WAIT;
                                count <= 'd0;
                            end else begin
                                state_arp <= HLEN_CHECK;
                                count <= 'd0;
                            end
                        end

                        if (count == 0) begin
                            arp_buf <= data_in;
                        end
                    end
                HLEN_CHECK:
                    begin
                        if (data_in != HLEN) begin
                            state_arp <= WAIT;
                        end else begin
                            state_arp <= PLEN_CHECK;
                        end
                    end
                PLEN_CHECK:
                    begin
                        if (data_in != PLEN) begin
                            state_arp <= WAIT;
                        end else begin
                            state_arp <= OPER_CHECK;
                        end
                    end
                OPER_CHECK:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            count <= 'd0;

                            case ({arp_buf, data_in})
                                OPER_RQ:
                                    begin
                                        state_arp <= MAC_SOURCE;
                                        oper_flag <= 'd0;
                                    end
                                OPER_RESP:
                                    begin
                                        state_arp <= MAC_SOURCE;
                                        oper_flag <= 'd1;
                                    end
                                default:
                                    begin
                                        state_arp <= WAIT;
                                        oper_flag <= 'd0;
                                    end
                            endcase
                        end

                        if (count == 0) begin
                            arp_buf <= data_in;
                        end
                    end
                MAC_SOURCE:
                    begin
                        if (count != 5) begin
                            count <= count + 1;
                        end else begin
                            state_arp <= IP_SOURCE;
                            count <= 'd0;
                        end

                        if (!oper_flag) begin
                            mac_s_addr[47 - count*8 -: 8] <= data_in;
                        end
                    end
                IP_SOURCE:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                        end else begin
                            state_arp <= MAC_DESTINATION;
                            count <= 'd0;
                        end

                        if (!oper_flag) begin
                            ip_s_addr_buf[31 - count*8 -: 8] <= data_in;
                        end
                    end
                MAC_DESTINATION:
                    begin
                        if (count != 5) begin
                            count <= count + 1;
                        end else begin
                            state_arp <= IP_DESTINATION;
                            count <= 'd0;
                        end

                        if (!oper_flag) begin
                            mac_d_addr_buf[47 - count*8 -: 8] <= data_in;
                        end
                    end
                IP_DESTINATION:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                        end else begin
                            state_arp <= WAIT;
                            count <= 'd0;

                            if (((mac_d_addr_buf == mac_d_addr) || (mac_d_addr_buf == MAC_Z)) && ({ip_d_addr_buf[31:8], data_in} == ip_d_addr)) begin
                                arp_data_valid <= 'd1;
                            end
                        end

                        if (!oper_flag) begin
                            ip_d_addr_buf[31 - count*8 -: 8] <= data_in;
                        end
                    end
            endcase
        end
    end

endmodule