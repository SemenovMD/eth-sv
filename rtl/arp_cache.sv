module arp_cache

(
    input   logic           aclk,
    input   logic           aresetn,
    
    input   logic   [47:0]  mac_s_addr_in,
    output  logic   [47:0]  mac_s_addr_out,
    
    input   logic           arp_oper,
    input   logic           arp_data_done,
    input   logic           crc_valid,
    output  logic           arp_resp_start,
    input   logic           arp_resp_end,
    output  logic           arp_rq_start
);

    logic   [31:0]  count;

    typedef enum logic [1:0]
    {  
        WAIT_ARP_DONE,
        WAIT_FCS_DONE,
        ARP_RESP

    } state_type_arp;

    state_type_arp state_arp;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_arp <= WAIT_ARP_DONE;
            arp_resp_start <= 'd0;
        end else begin
            case (state_arp)
                WAIT_ARP_DONE:
                    begin
                        if (!arp_data_done) begin
                            state_arp <= WAIT_ARP_DONE;
                        end else begin
                            state_arp <= WAIT_FCS_DONE;
                            mac_s_addr_out <= mac_s_addr_in;
                        end
                    end
                WAIT_FCS_DONE:
                    begin
                        if (!crc_valid) begin
                            state_arp <= WAIT_FCS_DONE;
                        end else begin
                            if (!arp_oper) begin
                                state_arp <= ARP_RESP;
                                arp_resp_start <= 'd1;
                            end else begin
                                state_arp <= WAIT_ARP_DONE;
                            end
                        end
                    end
                ARP_RESP:
                    begin
                        if (!arp_resp_end) begin
                            state_arp <= ARP_RESP;
                        end else begin
                            state_arp <= WAIT_ARP_DONE;
                            arp_resp_start <= 'd0;
                        end
                    end
            endcase
        end
    end

    typedef enum logic
    {
        COUNT,
        START_RQ
    } state_type_timer;

    state_type_timer state_timer;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_timer <= START_RQ;
            count <= 'd0;
            arp_rq_start <= 'd0;
        end else begin
            case (state_timer)
                START_RQ:
                    begin
                        state_timer <= COUNT;
                        arp_rq_start <= 'd1;
                    end
                COUNT:
                    begin
                        if (!count[31]) begin
                            count <= count + 1;
                        end else begin
                            state_timer <= START_RQ;
                            count <= 'd0;
                        end

                        arp_rq_start <= 'd0;
                    end
            endcase
        end
    end

endmodule