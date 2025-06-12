import socket
import time

DESTINATION_IP = '192.168.1.120'
DESTINATION_PORT = 8080

SERVER_IP = '192.168.188.135'
SERVER_PORT = 8080

sender_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

with open('udp_tx.txt', 'rb') as f:
    data = f.read()

offset = 0
while offset < len(data):
    chunk = data[offset:offset + 1024]
    remainder = len(chunk) % 4
    if remainder != 0:
        padding = 4 - remainder
        chunk += b'\x00' * padding
    sender_sock.sendto(chunk, (DESTINATION_IP, DESTINATION_PORT))
    offset += 1024
sender_sock.close()

print(f'[+] Данные отправлены на {DESTINATION_IP}:{DESTINATION_PORT}')

open('udp_rx.txt', 'wb').close()

receiver_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
receiver_sock.bind((SERVER_IP, SERVER_PORT))
print(f"Слушаем порт {SERVER_PORT}...")

start_time = time.time()
while time.time() - start_time < 5:
    try:
        receiver_sock.settimeout(1)
        data, addr = receiver_sock.recvfrom(1027)
        log_entry = f"From {addr}: {data}\n"
        print(log_entry.strip())
        with open("udp_rx.txt", "ab") as data_file:
            data_file.write(data)
    except socket.timeout:
        continue

receiver_sock.close()
print("Сервер остановлен (прошло 5 секунд).")