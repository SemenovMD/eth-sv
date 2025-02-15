module arp_header_rx

(
    input   logic           mac_gmii_rx_clk,
    input   logic           mac_gmii_rx_rstn,

    input   logic   [7:0]   mac_gmii_rxd,
    input   logic           mac_gmii_rx_dv,
    input   logic           mac_gmii_rx_er,

    // Request
    output  logic   [47:0]  rq_mac_s_addr,
    output  logic   [31:0]  rq_ip_s_addr,
    input   logic   [31:0]  rq_ip_d_addr,
    output  logic           rq_valid,

    // Response
    output  logic   [47:0]  resp_mac_s_addr,
    input   logic   [31:0]  resp_ip_s_addr,
    input   logic   [47:0]  resp_mac_d_addr,
    input   logic   [31:0]  resp_ip_d_addr,
    output  logic           resp_valid,

    input   logic           eth_type_arp_valid,
    output  logic           arp_handler_valid,

    input   logic   [1:0]   crc_rx_valid
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

    logic   [47:0]  rq_mac_d_addr_buf;
    logic   [31:0]  rq_ip_d_addr_buf;

    logic   [47:0]  resp_mac_d_addr_buf;
    logic   [31:0]  resp_ip_s_addr_buf;
    logic   [31:0]  resp_ip_d_addr_buf;

    assign data_valid = mac_gmii_rx_dv && ~mac_gmii_rx_er;

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

    always_ff @(posedge mac_gmii_rx_clk) begin
        if (!mac_gmii_rx_rstn) begin
            state_arp <= WAIT;
            count <= 'd0;
        end else begin
            if (!data_valid) begin
                state_arp <= WAIT;
                count <= 'd0;
            end else begin
                case (state_arp)
                    WAIT:
                        begin
                            if (!eth_type_arp_valid) begin
                                state_arp <= WAIT;
                            end else begin
                                state_arp <= HTYPE_CHECK;
                                arp_buf <= mac_gmii_rxd;
                            end
                        end
                    HTYPE_CHECK:
                        begin
                            if ({arp_buf, mac_gmii_rxd} != HTYPE) begin
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
                                if ({arp_buf, mac_gmii_rxd} != PTYPE) begin
                                    state_arp <= WAIT;
                                    count <= 'd0;
                                end else begin
                                    state_arp <= HLEN_CHECK;
                                    count <= 'd0;
                                end
                            end

                            if (count == 0) begin
                                arp_buf <= mac_gmii_rxd;
                            end
                        end
                    HLEN_CHECK:
                        begin
                            if (mac_gmii_rxd != HLEN) begin
                                state_arp <= WAIT;
                            end else begin
                                state_arp <= PLEN_CHECK;
                            end
                        end
                    PLEN_CHECK:
                        begin
                            if (mac_gmii_rxd != PLEN) begin
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

                                case ({arp_buf, mac_gmii_rxd})
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
                                arp_buf <= mac_gmii_rxd;
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
                                case (count)
                                    count: rq_mac_s_addr[47 - count*8 -: 8] <= mac_gmii_rxd;
                                endcase
                            end else begin
                                case (count)
                                    count: resp_mac_s_addr[47 - count*8 -: 8] <= mac_gmii_rxd;
                                endcase
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
                                case (count)
                                    count: rq_ip_s_addr[31 - count*8 -: 8] <= mac_gmii_rxd;
                                endcase
                            end else begin
                                case (count)
                                    count: resp_ip_s_addr_buf[31 - count*8 -: 8] <= mac_gmii_rxd;
                                endcase
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
                                case (count)
                                    count: rq_mac_d_addr_buf[47 - count*8 -: 8] <= mac_gmii_rxd;
                                endcase
                            end else begin
                                case (count)
                                    count: resp_mac_d_addr_buf[47 - count*8 -: 8] <= mac_gmii_rxd;
                                endcase
                            end
                        end
                    IP_DESTINATION:
                        begin
                            if (count != 3) begin
                                count <= count + 1;
                            end else begin
                                state_arp <= WAIT;
                                count <= 'd0;
                            end

                            if (!oper_flag) begin
                                case (count)
                                    count: rq_ip_d_addr_buf[31 - count*8 -: 8] <= mac_gmii_rxd;
                                endcase
                            end else begin
                                case (count)
                                    count: resp_ip_d_addr_buf[31 - count*8 -: 8] <= mac_gmii_rxd;
                                endcase
                            end
                        end
                endcase
            end
        end
    end

    // FSM
    typedef enum logic 
    {  
        WAIT_CRC,
        VALID_CHECK
    } state_type_crc;

    state_type_crc state_crc;

    always_ff @(posedge mac_gmii_rx_clk) begin
        if (!mac_gmii_rx_rstn) begin
            state_crc <= WAIT_CRC;
            rq_valid <= 'd0;
            resp_valid <= 'd0;
        end else begin
            case (state_crc)
                WAIT_CRC:
                    begin
                        if (crc_rx_valid != 'd1) begin
                            state_crc <= WAIT_CRC;
                        end else begin
                            state_crc <= VALID_CHECK;
                        end

                        rq_valid <= 'd0;
                        resp_valid <= 'd0;
                    end
                VALID_CHECK:
                    begin
                        state_crc <= WAIT_CRC;

                        if (!oper_flag) begin
                            if (rq_ip_d_addr_buf == rq_ip_d_addr) begin
                                if (rq_mac_d_addr_buf == MAC_Z) begin
                                    rq_valid <= 'd1;
                                end
                            end
                        end else begin
                            if (resp_ip_d_addr_buf == resp_ip_d_addr) begin
                                if (resp_mac_d_addr_buf == resp_mac_d_addr) begin
                                    if (resp_ip_s_addr_buf == resp_ip_d_addr) begin
                                        resp_valid <= 'd1;
                                    end
                                end
                            end
                        end
                    end
            endcase
        end
    end

endmodule