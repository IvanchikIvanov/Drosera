# 🔍 Проверка деплоя на серверах

## SSH подключение к серверам:
```bash
# Подключиться к серверу 1
ssh root@YOUR_SERVER1_IP

# Подключиться к серверу 2  
ssh root@YOUR_SERVER2_IP
```

## Проверка статуса Drosera:
```bash
cd /root/DROSERA

# Статус контейнеров
docker-compose ps

# Логи контейнера (последние 50 строк)
docker-compose logs --tail=50

# Логи в реальном времени
docker-compose logs -f
```

## Проверка портов:
```bash
# Проверка открытых портов
netstat -tuln | grep -E ":31313|:31314"

# Должно показать:
# tcp6  0  0  :::31313  :::*  LISTEN
# tcp6  0  0  :::31314  :::*  LISTEN
```

## Проверка процессов:
```bash
# Процессы Docker
docker ps

# Использование ресурсов
docker stats

# Статус через наш скрипт
./scripts/monitor.sh
```

## Проверка .env файла:
```bash
# Проверить созданные переменные (без показа приватных ключей)
ls -la /root/DROSERA/.env
head -2 /root/DROSERA/.env
```

## Проверка Trap проекта:
```bash
# Проверить создание Trap
ls -la /root/my-drosera-trap/

# Проверить сборку
cd /root/my-drosera-trap
ls -la out/
``` 