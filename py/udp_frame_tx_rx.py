import socket
import time  # Добавляем модуль для работы с задержкой

DESTINATION_IP = '192.168.1.120'
DESTINATION_PORT = 8080

SERVER_IP = '192.168.1.10'
SERVER_PORT = 8080

# Создаем отдельный сокет для отправки данных
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
    offset += 1024  # Корректное смещение, так как chunk берется из исходных данных
sender_sock.close()

print(f'[+] Данные отправлены на {DESTINATION_IP}:{DESTINATION_PORT}')

# Очистка файла перед началом приема данных
open('udp_rx.txt', 'wb').close()

# Создаем отдельный сокет для приема данных
receiver_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
receiver_sock.bind((SERVER_IP, SERVER_PORT))
print(f"Слушаем порт {SERVER_PORT}...")

# Запускаем таймер на 5 секунд
start_time = time.time()
while time.time() - start_time < 5:  # Работаем 5 секунд
    try:
        # Устанавливаем таймаут для recvfrom, чтобы не блокировать выполнение навсегда
        receiver_sock.settimeout(1)  # Таймаут 1 секунда
        data, addr = receiver_sock.recvfrom(1027)
        log_entry = f"From {addr}: {data}\n"
        print(log_entry.strip())  # Вывод в консоль
        with open("udp_rx.txt", "ab") as data_file:
            data_file.write(data)  # Запись сырых данных в файл
    except socket.timeout:
        # Если данных нет в течение таймаута, продолжаем цикл
        continue

# Закрываем сокет через 5 секунд
receiver_sock.close()
print("Сервер остановлен (прошло 5 секунд).")