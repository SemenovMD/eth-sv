module arp_handler_rx

(
    input   logic           mac_gmii_rx_clk,
    input   logic           mac_gmii_rx_rstn,

    input   logic   [7:0]   mac_gmii_rxd,
    input   logic           mac_gmii_rx_dv,
    input   logic           mac_gmii_rx_er,

    // Request
    input   logic   [47:0]  mac_s_addr,
    input   logic   

    // Response
    input   logic   [47:0]  mac_d_addr,
    input   logic   [47:0]  mac_s_addr,

    input   logic           eth_type_arp_valid,
    output  logic           arp_handler_valid
);

    localparam  HTYPE       =   16'h00_01;
    localparam  PTYPE       =   16'h08_00;
    localparam  HLEN        =    8'h06;
    localparam  PLEN        =    8'h04;
    localparam  OPER_RQ     =   16'h00_01;
    localparam  OPER_RESP   =   16'h00_02;

    localparam  MAC_Z       =   48'h00_00_00_00_00_00;

    logic   [7:0]   arp_buf;

    logic   [2:0]   count;


    typedef enum logic [2:0] 
    {  
        WAIT,
        HTYPE_CHECK,
        PTYPE_CHECK,
        HLEN_CHECK,
        PLEN_CHECK,
        OPER_CHECK

    } state_type;

    state_type state;

    assign data_valid = mac_gmii_rx_dv && ~mac_gmii_rx_er;

    always_ff @(posedge mac_gmii_rx_clk) begin
        if (!mac_gmii_rx_rstn) begin
            state <= WAIT;
            count <= 'd0;
        end else begin
            if (!data_valid) begin
                state <= WAIT;
                count <= 'd0;
            end else begin
                case (state)
                    WAIT:
                        begin
                            if (!eth_type_arp_valid) begin
                                state <= WAIT;
                            end else begin
                                state <= HTYPE_CHECK;
                                arp_buf <= mac_gmii_rxd;
                            end
                        end
                    HTYPE_CHECK:
                        begin
                            if ({arp_buf, mac_gmii_rxd} != HTYPE) begin
                                state <= WAIT;
                                count <= 'd0;
                            end else begin
                                state <= PTYPE_CHECK;
                                count <= 'd0;
                            end
                        end
                    PTYPE_CHECK:
                        begin
                            if (count != 1) begin
                                count <= count + 1
                            end else begin
                                if ({arp_buf, mac_gmii_rxd} != PTYPE) begin
                                    state <= WAIT;
                                    count <= 'd0;
                                end else begin
                                    state <= HLEN_CHECK;
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
                                state <= WAIT;
                            end else begin
                                state <= PLEN_CHECK;
                            end
                        end
                    PLEN_CHECK:
                        begin
                            if (mac_gmii_rxd != PLEN) begin
                                state <= WAIT;
                            end else begin
                                state <= OPER_CHECK;
                            end
                        end
                    OPER_CHECK:
                        begin
                            if (count != 1) begin
                                count <= count + 1
                            end else begin
                                case ({arp_buf, mac_gmii_rxd})
                                    OPER_RQ:
                                        begin
                                            state <= 
                                        end
                                    OPER_RESP:
                                        begin

                                        end
                                    default:
                                        begin
                                            state <= WAIT;
                                            count <= 'd0;
                                        end
                                endcase
                            end

                            if (count == 0) begin
                                arp_buf <= mac_gmii_rxd;
                            end
                        end
                endcase
            end
        end
    end

endmodule