`timescale 1ns/1ps

module tb_eth_rx();

// Parameters
parameter GMII_CLK_PERIOD = 8;  // 125 MHz
parameter AXI_CLK_PERIOD = 10;  // 100 MHz
parameter TEST_PACKETS = 3;

// DUT Signals
logic gmii_rstn;
logic [7:0] gmii_rxd;
logic gmii_rx_dv;
logic gmii_rx_er;
logic gmii_rx_clk;

// Configuration
logic [47:0] mac_d_addr = 48'hAABBCCDDEEFF;
logic [31:0] ip_d_addr = 32'hC0A80101;
logic [47:0] mac_s_addr = 48'h112233445566;
logic [31:0] ip_s_addr = 32'hC0A80102;
logic [15:0] port_s = 16'h0000;
logic [15:0] port_d = 16'h138D;

// Outputs
logic [47:0] rq_mac_s_addr;
logic arp_data_valid;
logic crc_valid;
logic crc_error;

// AXI Interfaces
logic aclk;
logic aresetn;
logic [31:0] m_axis_tdata;
logic m_axis_tvalid;
logic m_axis_tlast;
logic m_axis_tready;

byte crc_buffer[$];
logic calc_crc_enable = 0;

// Instantiate DUT
eth_rx dut (.*);

// Clock Generation
initial begin
    gmii_rx_clk = 0;
    forever #(GMII_CLK_PERIOD/2) gmii_rx_clk = ~gmii_rx_clk;
end

initial begin
    aclk = 0;
    forever #(AXI_CLK_PERIOD/2) aclk = ~aclk;
end

// Test Stimulus
initial begin
    initialize();
    reset();
    
    // Test 1: Normal UDP Packet
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);
    send_udp_packet(1024);

    // Test 2: ARP Packet
    // send_arp_packet();
    
    // Test 3: Corrupted Packet
    // send_corrupted_packet();

    #1000000;

    $display("All tests completed");
    $finish;
end

// Helper Tasks
task initialize();
    gmii_rxd = 0;
    gmii_rx_dv = 0;
    gmii_rx_er = 0;
    m_axis_tready = 1;
endtask

task reset();
    gmii_rstn = 0;
    aresetn = 0;
    #100;
    gmii_rstn = 1;
    aresetn = 1;
    #100;
endtask

// UDP Packet Generation
task send_udp_packet(logic [10:0] length);
    $display("\nSending UDP Packet...");
    
    // Ethernet Header
    send_preamble();
    send_eth_header(16'h0800); // IP
    
    // IP Header
    send_ip_header();
    
    // UDP Header
    send_udp_header(length + 8);
    
    // Payload
    send_payload(length);
    
    // FCS
    send_frame_with_crc();

    repeat (12) @(posedge gmii_rx_clk);
endtask

// ARP Packet Generation
task send_arp_packet();
    $display("\nSending ARP Packet...");
    
    send_preamble();
    send_eth_header(16'h0806); // ARP
    
    // ARP Payload
    for(int i=0; i<28; i++) begin
        case(i)
            0: send_byte(8'h00); // HTYPE
            1: send_byte(8'h01);
            2: send_byte(8'h08); // PTYPE
            3: send_byte(8'h00);
            4: send_byte(8'h06); // HLEN
            5: send_byte(8'h04); // PLEN
            6: send_byte(8'h00); // OPER
            7: send_byte(8'h01);
            default: send_byte(8'hAA);
        endcase
    end
endtask

// Corrupted Packet
task send_corrupted_packet();
    $display("\nSending Corrupted Packet...");
    
    send_preamble();
    send_eth_header(16'h0800);
    send_ip_header();
    send_udp_header(1024 + 8);
    send_payload(1024);
    
    // Intentionally corrupt last byte
    gmii_rx_er = 1;
    send_byte(8'hFF);
    gmii_rx_er = 0;
endtask

// Basic Packet Components
task send_preamble();
    for(int i=0; i<7; i++) send_byte(8'h55);
    send_byte(8'hD5); // SFD
    calc_crc_enable = 1;
endtask

task send_eth_header(logic [15:0] eth_type);
    // Destination MAC
    for(int i=0; i<6; i++) send_byte(mac_d_addr[47-8*i-:8]);
    // Source MAC
    for(int i=0; i<6; i++) send_byte(mac_s_addr[47-8*i-:8]);
    // EtherType
    send_byte(eth_type[15-:8]);
    send_byte(eth_type[7-:8]);
endtask

task send_ip_header();
    // Simplified IP Header
    send_byte(8'h45); // Version + IHL
    send_byte(8'h00); // DSCP
    // Total Length
    send_byte(8'h01);
    send_byte(8'h07);
    // IDP
    send_byte(8'he8);
    send_byte(8'ha7);
    // FLAG_OFFSET
    send_byte(8'h00);
    send_byte(8'h00);
    // TTL
    send_byte(8'h3f);
    // IP_UDP_TYPE
    send_byte(8'h11);
    // IP_HEADER_CHECKSUM
    send_byte(8'h00);
    send_byte(8'h00);
    // Source IP
    for(int i=0; i<4; i++) send_byte(ip_s_addr[31-8*i-:8]);
    // Dest IP
    for(int i=0; i<4; i++) send_byte(ip_d_addr[31-8*i-:8]);
endtask

task send_udp_header(input logic [15:0] length);
    // Source port
    send_byte(8'h13);
    send_byte(8'h8D);
    // Dest port
    send_byte(8'h13);
    send_byte(8'h8D);
    // Length
    send_byte(length[15:8]);
    send_byte(length[7:0]);
    // Checksum
    send_byte(8'h00);
    send_byte(8'h00);
endtask

task send_payload(int words);
    repeat(words) begin
        send_byte($random);
    end
endtask

task automatic calculate_crc(ref byte data[], output logic [31:0] crc);
    logic [31:0] polynomial = 32'hEDB88320;
    crc = 32'hFFFFFFFF;
    
    foreach(data[i]) begin
        crc = crc ^ {24'h0, data[i]};
        
        for(int j = 0; j < 8; j++) begin
            if(crc[0]) begin          // Проверяем МЛАДШИЙ бит
                crc = (crc >> 1) ^ polynomial;
            end else begin
                crc = crc >> 1;
            end
        end
    end
    
    // Финальная инверсия и реверс байт
    crc = ~crc;
    crc = {<<8{crc}};
endtask

task automatic send_frame_with_crc();
    // 1. Сбор данных для CRC (после SFD)
    logic [31:0] calculated_crc;
    byte packet_data[];
    
    // Ждем окончания отправки полезной нагрузки
    wait(crc_buffer.size() > 0); 
    
    // 2. Остановить сбор данных
    calc_crc_enable = 0; // <-- Добавить!
    
    // 3. Рассчитать CRC
    packet_data = new[crc_buffer.size()];
    foreach(crc_buffer[i]) packet_data[i] = crc_buffer[i];
    calculate_crc(packet_data, calculated_crc);
    
    // 4. Отправляем CRC
    for(int i=0; i<4; i++) begin
        automatic logic [7:0] crc_byte = calculated_crc[31-8*i-:8];
        @(posedge gmii_rx_clk);
        gmii_rxd = crc_byte;
    end
    
    // 5. Сброс
    crc_buffer.delete();
    calc_crc_enable = 0;
    @(posedge gmii_rx_clk);
    gmii_rx_dv = 0;
endtask

task send_byte(input logic [7:0] data);
    @(posedge gmii_rx_clk);
    gmii_rxd = data;
    gmii_rx_dv = 1;
    
    if(calc_crc_enable) begin
        crc_buffer.push_back(data);
    end
endtask

endmodule