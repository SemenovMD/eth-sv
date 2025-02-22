module fcs_rx 

(
    input   logic           aclk,
    input   logic           aresetn,
    input   logic   [7:0]   data_in,
    input   logic           data_valid,
    input   logic           preamble_sfd_valid,
    output  logic           crc_valid,
    output  logic           crc_error
);

    localparam POLY_CRC = 32'hEDB8_8320;
    localparam INIT_CRC = 32'hFFFF_FFFF;

    logic   [31:0]  crc_reg;
    logic   [31:0]  crc_next;
    logic   [31:0]  final_crc;

    logic   [31:0]  crc_calc_1;
    logic   [31:0]  crc_calc_2;
    logic   [31:0]  crc_calc_3;
    logic   [31:0]  crc_calc_4;

    logic   [7:0]   crc_rx_1;
    logic   [7:0]   crc_rx_2;
    logic   [7:0]   crc_rx_3;
    logic   [7:0]   crc_rx_4;

    always_comb begin
        crc_next = crc_reg ^ {24'h0, data_in};
            
        for(int i = 0; i < 8; i++) begin
            crc_next = (crc_next[0]) ? ((crc_next >> 1) ^ POLY_CRC) : (crc_next >> 1);
        end
    end

    // FSM
    typedef enum logic [1:0]
    {  
        IDLE,
        WAIT,
        CRC32_CHECK,
        INIT
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if(!aresetn) begin
            state <= IDLE;
            crc_valid <= 'd0;
            crc_error <= 'd0;
            crc_reg <= INIT_CRC;
        end
        else begin
            case (state)
                IDLE:
                    begin
                        if (!(preamble_sfd_valid && data_valid)) begin
                            state <= IDLE;
                        end else begin
                            state <= WAIT;
                            crc_reg <= crc_next;
                        end
                    end
                WAIT:
                    begin
                        if (data_valid) begin
                            state <= WAIT;
                            crc_reg <= crc_next;
                        end else begin
                            state <= CRC32_CHECK;
                        end
                    end
                CRC32_CHECK:
                    begin
                        state <= INIT;

                        if (crc_calc_4 == {crc_rx_1, crc_rx_2, crc_rx_3, crc_rx_4}) begin
                            crc_valid <= 'd1;
                            crc_error <= 'd0;
                        end else begin
                            crc_valid <= 'd0;
                            crc_error <= 'd1;
                        end
                    end
                INIT:
                    begin
                        state <= IDLE;
                        crc_valid <= 'd0;
                        crc_error <= 'd0;
                        crc_reg <= INIT_CRC;
                    end
            endcase
        end
    end

    assign final_crc = ~crc_reg;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            crc_calc_1 <= 'd0;
            crc_calc_2 <= 'd0;
            crc_calc_3 <= 'd0;
            crc_calc_4 <= 'd0;

            crc_rx_1 <= 'd0;
            crc_rx_2 <= 'd0;
            crc_rx_3 <= 'd0;
            crc_rx_4 <= 'd0;
        end else begin
            if (data_valid) begin
                crc_calc_1 <= final_crc;
                crc_calc_2 <= crc_calc_1;
                crc_calc_3 <= crc_calc_2;
                crc_calc_4 <= crc_calc_3;

                crc_rx_1 <= data_in;
                crc_rx_2 <= crc_rx_1;
                crc_rx_3 <= crc_rx_2;
                crc_rx_4 <= crc_rx_3;
            end
        end
    end

endmodule