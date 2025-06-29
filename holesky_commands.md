# Команды управления нодой Holesky

## 🗑️ Удаление ноды
```bash
# Полное удаление ноды Holesky
sudo bash remove_holesky.sh

# Быстрое удаление (только остановка сервисов)
sudo systemctl stop execution.service consensus.service
sudo systemctl disable execution.service consensus.service
```

## 🚀 Установка ноды
```bash
# Полная автоматическая установка
sudo bash install_holesky.sh

# Ручная установка EthPillar
curl -L https://github.com/ChorusOne/eth-pillar/releases/latest/download/ethpillar-linux-amd64 -o /usr/local/bin/ethpillar
chmod +x /usr/local/bin/ethpillar
```

## 📊 Мониторинг и статус
```bash
# Общий статус ноды
/usr/local/bin/holesky-status.sh

# Статус сервисов
sudo systemctl status execution.service
sudo systemctl status consensus.service

# Логи в реальном времени
sudo journalctl -f -u execution.service
sudo journalctl -f -u consensus.service

# Последние 100 строк логов
sudo journalctl -u execution.service -n 100
sudo journalctl -u consensus.service -n 100
```

## 🔄 Управление сервисами
```bash
# Запуск
sudo systemctl start execution.service
sudo systemctl start consensus.service

# Остановка
sudo systemctl stop execution.service
sudo systemctl stop consensus.service

# Перезапуск
sudo systemctl restart execution.service
sudo systemctl restart consensus.service

# Автозапуск
sudo systemctl enable execution.service
sudo systemctl enable consensus.service

# Отключение автозапуска
sudo systemctl disable execution.service
sudo systemctl disable consensus.service
```

## 🌐 Проверка RPC
```bash
# Проверка блока
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545

# Проверка синхронизации
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545

# Количество пиров
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545

# Проверка Beacon API
curl http://localhost:5052/eth/v1/node/health
curl http://localhost:5052/eth/v1/node/syncing
```

## 🔧 Конфигурация
```bash
# Основные файлы конфигурации
/etc/systemd/system/execution.service
/etc/systemd/system/consensus.service
/etc/nethermind/holesky.json

# Директории данных
/var/lib/nethermind/
/var/lib/lighthouse/

# JWT файл
/var/lib/nethermind/keystore/jwt.hex
```

## 🔥 Firewall
```bash
# Открыть порты
sudo ufw allow 8545  # RPC HTTP
sudo ufw allow 8546  # RPC WebSocket
sudo ufw allow 30303 # P2P Ethereum
sudo ufw allow 9000  # P2P Beacon
sudo ufw allow 5052  # Beacon API

# Закрыть порты
sudo ufw delete allow 8545
sudo ufw delete allow 8546
sudo ufw delete allow 30303
sudo ufw delete allow 9000
sudo ufw delete allow 5052
```

## 💾 Резервное копирование
```bash
# Остановить сервисы перед бэкапом
sudo systemctl stop execution.service consensus.service

# Создать архив данных
sudo tar -czf holesky_backup_$(date +%Y%m%d).tar.gz \
  /var/lib/nethermind \
  /var/lib/lighthouse \
  /etc/systemd/system/execution.service \
  /etc/systemd/system/consensus.service

# Восстановить из архива
sudo tar -xzf holesky_backup_YYYYMMDD.tar.gz -C /
sudo systemctl daemon-reload
sudo systemctl start execution.service consensus.service
```

## 🚨 Устранение неполадок
```bash
# Проверка места на диске
df -h

# Проверка использования памяти
free -h

# Проверка процессов
ps aux | grep -E "(nethermind|lighthouse)"

# Проверка портов
netstat -tulpn | grep -E "(8545|8546|30303|9000|5052)"

# Очистка логов
sudo journalctl --vacuum-time=7d

# Пересборка systemd
sudo systemctl daemon-reload
```

## 📈 Производительность
```bash
# Мониторинг ресурсов
htop
iotop
nethogs

# Размер базы данных
du -sh /var/lib/nethermind/
du -sh /var/lib/lighthouse/

# Статистика сети
ss -tuln
``` 