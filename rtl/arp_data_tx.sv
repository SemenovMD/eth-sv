module arp_data_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic           arp_oper,

    input   logic   [47:0]  mac_d_addr,
    input   logic   [31:0]  ip_d_addr,

    input   logic   [47:0]  mac_s_addr,
    input   logic   [31:0]  ip_s_addr,

    input   logic           eth_header_arp_done,
    output  logic           arp_data_done,
    output  logic   [7:0]   data_out
);

    localparam  HTYPE       =   16'h00_01;
    localparam  PTYPE       =   16'h08_00;
    localparam  HLEN        =    8'h06;
    localparam  PLEN        =    8'h04;
    localparam  OPER_RQ     =   16'h00_01;
    localparam  OPER_RESP   =   16'h00_02;

    localparam  MAC_Z       =    8'h00;

    logic   [2:0]   count;

    typedef enum logic [3:0] 
    {  
        WAIT_START,
        HTYPE_TX,
        PTYPE_TX,
        HLEN_TX,
        PLEN_TX,
        OPER_TX,
        MAC_SOURCE_TX,
        IP_SOURCE_TX,
        MAC_DESTINATION_TX,
        IP_DESTINATION_TX
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT_START;
            count <= 'd0;
            arp_data_done <= 'd0;
        end else begin
            case (state)
                WAIT_START:
                    begin
                        if (!eth_header_arp_done) begin
                            state <= WAIT_START;
                        end else begin
                            state <= HTYPE_TX;
                            data_out <= HTYPE[15:8];
                        end

                        arp_data_done <= 'd0;
                    end
                HTYPE_TX:
                    begin
                        state <= PTYPE_TX;
                        data_out <= HTYPE[7:0];
                    end
                PTYPE_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= HLEN_TX;
                            count <= 'd0;
                        end

                        data_out <= PTYPE[15 - count*8 -: 8];
                    end
                HLEN_TX:
                    begin
                        state <= PLEN_TX;
                        data_out <= HLEN;
                    end
                PLEN_TX:
                    begin
                        state <= OPER_TX;
                        data_out <= PLEN;
                    end
                OPER_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= MAC_SOURCE_TX;
                            count <= 'd0;
                        end

                        if (!arp_oper) begin
                            data_out <= OPER_RESP[15 - count*8 -: 8];
                        end else begin
                            data_out <= OPER_RQ[15 - count*8 -: 8];
                        end
                    end
                MAC_SOURCE_TX:
                    begin
                        if (count != 5) begin
                            count <= count + 1;
                        end else begin
                            state <= IP_SOURCE_TX;
                            count <= 'd0;
                        end

                        data_out <= mac_s_addr[47 - count*8 -: 8];
                    end
                IP_SOURCE_TX:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                        end else begin
                            state <= MAC_DESTINATION_TX;
                            count <= 'd0;
                        end

                        data_out <= ip_s_addr[31 - count*8 -: 8];
                    end
                MAC_DESTINATION_TX:
                    begin
                        if (count != 5) begin
                            count <= count + 1;
                        end else begin
                            state <= IP_DESTINATION_TX;
                            count <= 'd0;
                        end

                        if (!arp_oper) begin
                            data_out <= mac_d_addr[47 - count*8 -: 8];
                        end else begin
                            data_out <= MAC_Z;
                        end
                    end
                IP_DESTINATION_TX:
                    begin
                        if (count != 3) begin
                            count <= count + 1;
                        end else begin
                            state <= WAIT_START;
                            count <= 'd0;
                            arp_data_done <= 'd1;
                        end

                        data_out <= ip_d_addr[31 - count*8 -: 8];
                    end
            endcase
        end
    end

endmodule