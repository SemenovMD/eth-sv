import socket
import time
from datetime import datetime

SOURCE_PORT = 1234
DESTINATION_IP = '192.168.1.120'
DESTINATION_PORT = 5005

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(('', SOURCE_PORT))
sock.settimeout(0.1)  # Таймаут для операций с сокетом

def log_rx(data, addr):
    """Запись полученных данных в лог-файл"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
    with open('udp_rx.txt', 'a') as f:
        f.write(f"[{timestamp}] RX from {addr[0]}:{addr[1]}: {data.hex().upper()}\n")

with open('udp_tx.txt', 'rb') as f:
    data = f.read()

offset = 0
while offset < len(data):
    # Отправка TX
    chunk = data[offset:offset + 1024]
    remainder = len(chunk) % 4
    if remainder != 0:
        chunk += b'\x00' * (4 - remainder)
    sock.sendto(chunk, (DESTINATION_IP, DESTINATION_PORT))
    print(f"Sent {len(chunk)} bytes to {DESTINATION_IP}:{DESTINATION_PORT}")
    offset += 1024

    # Прием RX с таймаутом
    try:
        rx_data, addr = sock.recvfrom(1024)
        log_rx(rx_data, addr)
        print(f"Received {len(rx_data)} bytes from {addr}")
    except socket.timeout:
        print("No data received within timeout")
    except Exception as e:
        print(f"Receive error: {str(e)}")

# Дополнительное время для приема оставшихся данных
print("\nWaiting for remaining data...")
try:
    while True:
        rx_data, addr = sock.recvfrom(1024)
        log_rx(rx_data, addr)
        print(f"Late received {len(rx_data)} bytes from {addr}")
except KeyboardInterrupt:
    pass

print(f'\n[+] Данные отправлены с порта {SOURCE_PORT} на {DESTINATION_IP}:{DESTINATION_PORT}')
sock.close()