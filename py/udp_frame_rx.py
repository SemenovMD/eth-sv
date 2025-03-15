import socket
from datetime import datetime

SERVER_IP = '192.168.1.10'
SERVER_PORT = 8080

def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((SERVER_IP, SERVER_PORT))
    
    print(f"Слушаем порт {SERVER_PORT}...")
    
    try:
        while True:
            # Получаем данные и адрес отправителя
            data, addr = sock.recvfrom(1024)
            
            # Формируем запись с временной меткой
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            log_entry = f"[{timestamp}] From {addr}: {data.decode()}\n"
            
            # Вывод в консоль
            print(log_entry.strip())
            
            # Запись в файл
            with open("udp_rx.txt", "a", encoding="utf-8") as f:
                f.write(log_entry)
                
    except KeyboardInterrupt:
        print("\nСервер остановлен")
    finally:
        sock.close()

if __name__ == "__main__":
    main()