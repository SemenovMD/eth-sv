module arb_arp_oper

(
    input   logic       aclk,
    input   logic       aresetn,

    input   logic       arp_resp_start,
    input   logic       arp_rq_start,

    input   logic       arp_data_tx_done,
    output  logic       arp_oper,
    output  logic       arp_tx_start
);

    typedef enum logic [1:0]
    {  
        IDLE,
        RESP_START,
        RQ_START,
        WAIT_ARP_DATA_DONE
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= IDLE;
            arp_tx_start <= 'd0;
            arp_oper <= 'd0;
        end else begin
            case (state)
                IDLE:
                    begin
                        case ({arp_resp_start, arp_rq_start})
                            2'b00: state <= IDLE;
                            2'b01: state <= RQ_START;
                            2'b10: state <= RESP_START;
                            2'b11: state <= RESP_START;
                        endcase
                    end
                RESP_START:
                    begin
                        state <= WAIT_ARP_DATA_DONE;
                        arp_oper <= 'd0;
                        arp_tx_start <= 'd1;
                    end
                RQ_START:
                    begin
                        state <= WAIT_ARP_DATA_DONE;
                        arp_oper <= 'd1;
                        arp_tx_start <= 'd1;
                    end
                WAIT_ARP_DATA_DONE:
                    begin
                        if (!arp_data_tx_done) begin
                            state <= WAIT_ARP_DATA_DONE;
                        end else begin
                            state <= IDLE;
                            arp_tx_start <= 'd0;
                            arp_oper <= 'd0;
                        end
                    end
            endcase
        end
    end

endmodule