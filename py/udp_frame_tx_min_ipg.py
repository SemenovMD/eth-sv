import socket

SOURCE_PORT = 5007
DESTINATION_IP = '192.168.1.120'
DESTINATION_PORT = 5005

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(('', SOURCE_PORT))

with open('udp_tx.txt', 'rb') as f:
    data = f.read()

offset = 0
while offset < len(data):
    # Берем порцию данных (максимум 1024 байта)
    chunk = data[offset:offset + 1024]
    
    # Вычисляем необходимое количество байт для выравнивания
    remainder = len(chunk) % 4
    if remainder != 0:
        padding = 4 - remainder
        chunk += b'\x00' * padding  # Добавляем нулевые байты
    
    # Отправляем выровненные данные
    sock.sendto(chunk, (DESTINATION_IP, DESTINATION_PORT))
    offset += 1024  # Смещение всегда увеличиваем на 1024

print(f'[+] Данные отправлены с порта {SOURCE_PORT} на {DESTINATION_IP}:{DESTINATION_PORT}')
sock.close()