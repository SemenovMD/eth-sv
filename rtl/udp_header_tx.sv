module udp_header_tx

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic           ip_header_tx_done,
    input   logic   [15:0]  udp_len,

    input   logic   [15:0]  port_s,
    input   logic   [15:0]  port_d,

    output  logic   [7:0]   data_out,
    output  logic           udp_header_tx_done_0,
    output  logic           udp_header_tx_done_1
);

    logic   [15:0]  udp_len_sum;
    logic           count;

    assign udp_len_sum = udp_len;

    typedef enum logic [2:0]
    {  
        WAIT_START,
        PORT_SOURCE_TX,
        PORT_DESTINATION_TX,
        LENGTH_TX,
        CHECKSUM_TX
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT_START;
            count <= 'd0;
            udp_header_tx_done_0 <= 'd0;
            udp_header_tx_done_1 <= 'd0;
        end else begin
            case (state)
                WAIT_START:
                    begin
                        if (!ip_header_tx_done) begin
                            state <= WAIT_START;
                        end else begin
                            state <= PORT_SOURCE_TX;
                            data_out <= port_s[15:8];
                        end

                        udp_header_tx_done_0 <= 'd0;
                        udp_header_tx_done_1 <= 'd0;
                    end
                PORT_SOURCE_TX:
                    begin
                        state <= PORT_DESTINATION_TX;
                        data_out <= port_s[7:0];
                    end
                PORT_DESTINATION_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            count <= 'd0;
                            state <= LENGTH_TX;
                        end

                        data_out <= port_d[15 - count*8 -: 8];
                    end
                LENGTH_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                        end else begin
                            count <= 'd0;
                            state <= CHECKSUM_TX;
                        end

                        data_out <= udp_len_sum[15 - count*8 -: 8];
                    end
                CHECKSUM_TX:
                    begin
                        if (count != 1) begin
                            count <= count + 1;
                            udp_header_tx_done_0 <= 'd1;
                            udp_header_tx_done_1 <= 'd0;
                        end else begin
                            count <= 'd0;
                            state <= WAIT_START;
                            udp_header_tx_done_0 <= 'd0;
                            udp_header_tx_done_1 <= 'd1;
                        end

                        data_out <= 'd0;
                    end                
            endcase
        end
    end

endmodule