module crc32_rx 

(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        data_valid,
    input  logic [7:0]  data_in,
    output logic        crc_ok
);

    logic   [31:0]  crc_reg;
    logic   [31:0]  crc_next;
    logic   [31:0]  final_crc;

    logic   [31:0]  crc_buf_1;
    logic   [31:0]  crc_buf_2;
    logic   [31:0]  crc_buf_3;

    logic   [7:0]   crc_buf_1_2;
    logic   [7:0]   crc_buf_2_2;
    logic   [7:0]   crc_buf_3_2;
    logic   [7:0]   crc_buf_4_2;

    always_comb begin
        crc_next = crc_reg;
        
        if(data_valid) begin
            crc_next = crc_reg ^ {24'h0, data_in};
            
            for(int i = 0; i < 8; i++) begin
                crc_next = (crc_next[0]) ? 
                        ((crc_next >> 1) ^ 32'hEDB8_8320) : 
                        (crc_next >> 1);
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            crc_reg <= 32'hFFFF_FFFF;
        end
        else begin
            crc_reg <= crc_next;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_buf_1 <= 'd0;
            crc_buf_2 <= 'd0;
            crc_buf_3 <= 'd0;
        end else begin
            if (data_valid) begin
                crc_buf_1 <= final_crc;
                crc_buf_2 <= crc_buf_1;
                crc_buf_3 <= crc_buf_2;
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
                crc_buf_1_2 <= data_in;
                crc_buf_2_2 <= crc_buf_1_2;
                crc_buf_3_2 <= crc_buf_2_2;
                crc_buf_4_2 <= crc_buf_3_2;
            end
        end
    end

    assign final_crc = ~crc_reg;
    assign crc_ok = (crc_buf_3 == {crc_buf_1_2, crc_buf_2_2, crc_buf_3_2, crc_buf_4_2});

endmodule
