module udp_header_rx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic   [7:0]   data_in,
    input   logic           data_valid,

    input   logic   [15:0]  port_d,

    input   logic           ip_header_done,

    output  logic           udp_data_valid,
    output  logic           udp_data_tlast
);

    localparam  LEN_UDP_HEADER  =   8;

    logic   [10:0]  count;

    logic   [7:0]   port_d_buf;
    logic   [15:0]  len_buf;

    logic           aresetn_sum;

    assign aresetn_sum = aresetn & data_valid;

    typedef enum logic [2:0] 
    {  
        WAIT,
        PORT_SOURCE,
        PORT_DESTINATION,
        LENGTH,
        CHECKSUM,
        COUNT_BYTE
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn_sum) begin
            state <= WAIT;
            count <= 'd0;
            udp_data_valid <= 'd0;
        end else begin
            case (state)
                WAIT:
                    begin
                        if (!ip_header_done) begin
                            state <= WAIT;
                        end else begin
                            state <= PORT_SOURCE;
                        end
                    end
                PORT_SOURCE:
                    begin
                        state <= PORT_DESTINATION;
                    end
                PORT_DESTINATION:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            if ({port_d_buf, data_in} != port_d) begin
                                state <= WAIT;  
                            end else begin
                                state <= LENGTH;
                            end

                            count <= 'd0;
                        end

                        if (count == 0) begin
                            port_d_buf <= data_in;
                        end
                    end
                LENGTH:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= CHECKSUM;
                            count <= 'd0;
                        end

                        len_buf[15 - count*8 -: 8] <= data_in;
                    end
                CHECKSUM:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            state <= COUNT_BYTE;
                            count <= 'd0;
                            udp_data_valid <= 'd1;
                        end
                    end
                COUNT_BYTE:
                    begin
                        if (count != len_buf - LEN_UDP_HEADER - 1) begin
                            count <= count + 1;
                        end else begin
                            state <= WAIT;
                            count <= 'd0;
                            udp_data_valid <= 'd0;
                        end

                        if (count == len_buf - LEN_UDP_HEADER - 2) begin
                            udp_data_tlast <= 'd1;
                        end else begin
                            udp_data_tlast <= 'd0;
                        end
                    end
            endcase
        end
    end

endmodule