def crc32_ethernet(data):
    crc = 0xFFFFFFFF
    polynomial = 0xEDB88320
    print("\nРасчет CRC32:")
    print("{:<6} {:<8} {:<12} {:<10}".format("Байт", "HEX", "CRC до", "CRC после"))
    print("-" * 45)
    
    for idx, byte in enumerate(data):
        initial_crc = crc
        crc ^= byte
        for _ in range(8):
            if crc & 0x00000001:
                crc = (crc >> 1) ^ polynomial
            else:
                crc >>= 1
            crc &= 0xFFFFFFFF
        
        # Форматирование вывода
        print("{:<6} 0x{:<6x} 0x{:08x} -> 0x{:08x}".format(
            idx + 1,
            byte,
            initial_crc ^ 0xFFFFFFFF,  # Показываем инвертированное начальное значение
            crc ^ 0xFFFFFFFF           # Инвертированное конечное значение
        ))
    
    final_crc = crc ^ 0xFFFFFFFF
    return final_crc

# ================== ARP ПАРАМЕТРЫ ==================
arp_operation = 1
sender_ip = "192.168.1.10"
target_ip = "192.168.1.120"
sender_mac = "84:A9:38:DA:2F:F0"
target_mac = "00:00:00:00:00:00"

# ================== ФУНКЦИИ ==================
def ip_to_bytes(ip):
    return bytes(map(int, ip.split('.')))

def mac_to_bytes(mac):
    return bytes.fromhex(mac.replace(':', ''))

# Формируем ARP-пакет
arp_data = (
    b'\x00\x01' +
    b'\x08\x00' +
    b'\x06' +
    b'\x04' +
    arp_operation.to_bytes(2, 'big') +
    mac_to_bytes(sender_mac) +
    ip_to_bytes(sender_ip) +
    mac_to_bytes(target_mac) +
    ip_to_bytes(target_ip)
)

# ================== СОБИРАЕМ КАДР ==================
ethernet_frame = (
    mac_to_bytes("FF:FF:FF:FF:FF:FF") +
    mac_to_bytes(sender_mac) +
    b'\x08\x06' +
    arp_data +
    b'\x00'*18
)

# ================== РАСЧЕТ И ВЫВОД ==================
print("Размер кадра:", len(ethernet_frame), "байт")
fcs = crc32_ethernet(ethernet_frame)

print("\nРезультат:")
print("-" * 45)
print("Итоговый CRC (little-endian):", fcs.to_bytes(4, 'little').hex('-'))
print("Итоговый CRC (big-endian):   ", fcs.to_bytes(4, 'big').hex('-'))