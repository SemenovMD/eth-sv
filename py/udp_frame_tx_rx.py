import socket

# Конфигурация подключения
SERVER_IP = '192.168.1.120'  # Замените на нужный IP
SERVER_PORT = 5005
TIMEOUT = 5  # Таймаут ожидания ответа

# Создаем UDP-сокет
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(TIMEOUT)
print("HP")

try:
    # Отправляем данные
    message = "hello, world"
    sock.sendto(message.encode('utf-8'), (SERVER_IP, SERVER_PORT))
    print(f"Отправлено UDP-сообщение на {SERVER_IP}:{SERVER_PORT}")

    # Получаем ответ (если ожидается)
    data, addr = sock.recvfrom(1024)
    print(f"Получен ответ от {addr}: {data.decode('utf-8')}")

except socket.timeout:
    print("Таймаут: ответ не получен")
except Exception as e:
    print(f"Ошибка: {str(e)}")
finally:
    sock.close()
    print("Сокет закрыт")