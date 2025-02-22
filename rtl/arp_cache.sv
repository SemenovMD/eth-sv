module arp_cache

(
    input   logic           aclk,
    input   logic           aresetn,

    output  logic   [47:0]  mac_d_addr,
    output  logic   [31:0]  ip_d_addr,

    input   logic   [47:0]  rq_mac_s_addr,
    output  logic   [47:0]  resp_mac_s_addr,
    output  logic   [31:0]  ip_s_addr,

    input   logic           arp_data_done,
    input   logic           crc_valid,
    output  logic           arp_resp_start
);

    assign  ip_d_addr   =   {8'd192, 8'd168, 8'd1, 8'd120};
    assign  mac_d_addr  =   {8'h84, 8'hA0, 8'hDA, 8'hB8, 8'h31, 8'h42};

    assign  ip_s_addr   =   {8'd192, 8'd168, 8'd1, 8'd10};

    typedef enum logic [1:0]
    {  
        WAIT_ARP_DONE,
        WAIT_FCS_DONE,
        ARP_RESP

    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= WAIT_ARP_DONE;
            arp_resp_start <= 'd0;
        end else begin
            case (state)
                WAIT_ARP_DONE:
                    begin
                        if (!arp_data_done) begin
                            state <= WAIT_ARP_DONE;
                        end else begin
                            state <= WAIT_FCS_DONE;
                            resp_mac_s_addr <= rq_mac_s_addr;
                        end
                    end
                WAIT_FCS_DONE:
                    begin
                        if (!crc_valid) begin
                            state <= WAIT_FCS_DONE;
                        end else begin
                            state <= ARP_RESP;
                            arp_resp_start <= 'd1;
                        end
                    end
                ARP_RESP:
                    begin
                        state <= WAIT_ARP_DONE;
                        arp_resp_start <= 'd0;
                    end
            endcase
        end
    end

endmodule