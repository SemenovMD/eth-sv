module arp_cache

(
    input   logic           aclk,
    input   logic           aresetn,

    // Configuration Interface
    input   logic   [47:0]  mac_config_addr_in,
    input   logic   [31:0]  ip_config_addr_in,

    output  logic   [47:0]  mac_config_addr_out,
    output  logic   [31:0]  ip_config_addr_out,

    //////////////////////////////////////////////////////////
    // RX
    //////////////////////////////////////////////////////////

    // Ethernet Header
    input   logic   [47:0]  rx_mac_s_addr,
    output  logic           rx_mac_s_addr_valid,
    
    // ARP data
    input   logic   [47:0]  arp_mac_s_addr,
    input   logic   [31:0]  arp_ip_s_addr,
    input   logic           arp_mac_s_addr_valid,

    // IP Header
    input   logic   [31:0]  rx_ip_s_addr,
    output  logic           rx_ip_s_addr_valid,

    //////////////////////////////////////////////////////////
    // TX
    //////////////////////////////////////////////////////////

    input   logic   [47:0]  tx_mac_d_addr,
    input   logic   [31:0]  tx_ip_d_addr,
    input   logic           tx_valid,
    output  logic           tx_ready,
    output  logic           tx_error
);

    logic   [1:0]   index;

    logic   [47:0]  mac_addr_cache    [0:3];
    logic   [31:0]  ip_addr_cache     [0:3];

    assign mac_config_addr_out = mac_config_addr_in;
    assign ip_config_addr_out = ip_config_addr_in;

    //////////////////////////////////////////////////////////
    // RX
    //////////////////////////////////////////////////////////

    // Ethernet Header
    always_comb  begin
        case (rx_mac_s_addr)
            mac_addr_cache[0]:  rx_mac_s_addr_valid = 'd1;
            mac_addr_cache[1]:  rx_mac_s_addr_valid = 'd1;
            mac_addr_cache[2]:  rx_mac_s_addr_valid = 'd1;
            mac_addr_cache[3]:  rx_mac_s_addr_valid = 'd1;
            default:            rx_mac_s_addr_valid = 'd0;
        endcase
    end

    // IP Header
    always_comb  begin
        case (rx_ip_s_addr)
            ip_addr_cache[0]:   rx_ip_s_addr_valid = 'd1;
            ip_addr_cache[1]:   rx_ip_s_addr_valid = 'd1;
            ip_addr_cache[2]:   rx_ip_s_addr_valid = 'd1;
            ip_addr_cache[3]:   rx_ip_s_addr_valid = 'd1;
            default:            rx_ip_s_addr_valid = 'd0;
        endcase
    end

    // FSM
    typedef enum logic 
    {  
        IDLE,
        WRITE
    } state_type;

    state_type state;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state <= IDLE;
            index <= 'd0;
        end else begin
            case (state)
                IDLE:
                    begin
                        if (!arp_mac_s_addr_valid) begin
                            state <= IDLE;
                        end else begin
                            case ({arp_mac_s_addr, arp_ip_s_addr})
                                {mac_addr_cache[0], ip_addr_cache[0]}:  state <= IDLE;
                                {mac_addr_cache[1], ip_addr_cache[1]}:  state <= IDLE;
                                {mac_addr_cache[2], ip_addr_cache[2]}:  state <= IDLE;
                                {mac_addr_cache[3], ip_addr_cache[3]}:  state <= IDLE;
                                default:                                state <= WRITE;
                            endcase
                        end
                    end
                WRITE:
                    begin
                        state <= IDLE;
                        index <= index + 1;
                        mac_addr_cache[index] <= arp_mac_s_addr;
                        ip_addr_cache[index] <= arp_ip_s_addr;
                    end
            endcase
        end
    end

    //////////////////////////////////////////////////////////
    // TX
    //////////////////////////////////////////////////////////

endmodule