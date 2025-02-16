module crc32_rx 

(
    input  logic        aclk,
    input  logic        aresetn,
    input  logic [7:0]  data_in,
    input  logic [7:0]  data_valid,
    input  logic        preamble_sfd_valid,
    output logic        crc_valid
);

    logic           data_valid;
    logic           preamble_sfd_valid_reg;

    logic   [31:0]  crc_reg;
    logic   [31:0]  crc_next;
    logic   [31:0]  final_crc;

    logic   [31:0]  crc_buf_1;
    logic   [31:0]  crc_buf_2;
    logic   [31:0]  crc_buf_3;
    logic   [31:0]  crc_buf_4;

    logic   [7:0]   crc_buf_1_2;
    logic   [7:0]   crc_buf_2_2;
    logic   [7:0]   crc_buf_3_2;
    logic   [7:0]   crc_buf_4_2;

    typedef enum logic 
    {  
        IDLE,
        WAIT
    } state_type;

    state_type state;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            preamble_sfd_valid_reg <= 'd0;
        end else begin
            if (!data_valid) begin
                state <= IDLE;
                preamble_sfd_valid_reg <= 'd0;
            end else begin
                case (state)
                    IDLE:
                        begin
                            if (!preamble_sfd_valid) begin
                                state <= IDLE;
                                preamble_sfd_valid_reg <= 'd0;
                            end else begin
                                state <= WAIT;
                                preamble_sfd_valid_reg <= 'd1;
                            end
                        end
                    WAIT:
                        begin
                            state <= WAIT;
                        end
                endcase
            end
        end
    end

    always_comb begin
        crc_next = crc_reg;
        
        if(data_valid) begin
            crc_next = crc_reg ^ {24'h0, mac_gmii_rxd};
            
            for(int i = 0; i < 8; i++) begin
                crc_next = (crc_next[0]) ? ((crc_next >> 1) ^ 32'hEDB8_8320) : (crc_next >> 1);
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            crc_reg <= 32'hFFFF_FFFF;
        end
        else begin
            if (data_valid && (preamble_sfd_valid_reg || preamble_sfd_valid)) begin
                crc_reg <= crc_next;
            end else begin
                crc_reg <= 32'hFFFF_FFFF;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_buf_1 <= 'd0;
            crc_buf_2 <= 'd0;
            crc_buf_3 <= 'd0;
            crc_buf_4 <= 'd0;
        end else begin
            if (data_valid) begin
                crc_buf_1 <= final_crc;
                crc_buf_2 <= crc_buf_1;
                crc_buf_3 <= crc_buf_2;
                crc_buf_4 <= crc_buf_3;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_buf_1_2 <= 'd0;
            crc_buf_2_2 <= 'd0;
            crc_buf_3_2 <= 'd0;
            crc_buf_4_2 <= 'd0;
        end else begin
            if (data_valid) begin
                crc_buf_1_2 <= mac_gmii_rxd;
                crc_buf_2_2 <= crc_buf_1_2;
                crc_buf_3_2 <= crc_buf_2_2;
                crc_buf_4_2 <= crc_buf_3_2;
            end
        end
    end

    assign final_crc = ~crc_reg;

    always_comb begin
        if (crc_buf_4 == 'd0) begin
            crc_valid = 'd0;
        end else begin
            if (crc_buf_4 == {crc_buf_1_2, crc_buf_2_2, crc_buf_3_2, crc_buf_4_2}) begin
                crc_valid = 'd1;
            end else begin
                crc_valid = 'd0;
            end
        end
    end

endmodule