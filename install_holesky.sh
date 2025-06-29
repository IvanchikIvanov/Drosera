#!/bin/bash

# Скрипт установки ноды Holesky
# Полная автоматическая установка и настройка

echo "🚀 Начинаю установку ноды Holesky..."

# Функция для проверки успешности выполнения команды
check_command() {
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка: $1"
        exit 1
    else
        echo "✅ $1"
    fi
}

# Функция для вывода заголовков
print_header() {
    echo ""
    echo "========================================="
    echo "🔧 $1"
    echo "========================================="
}

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Этот скрипт должен быть запущен с правами root (sudo)"
   exit 1
fi

# Получение IP адреса сервера
SERVER_IP=$(curl -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi
echo "🌐 IP адрес сервера: $SERVER_IP"

print_header "Обновление системы"
apt-get update && apt-get upgrade -y
check_command "Система обновлена"

print_header "Установка базовых зависимостей"
apt-get install -y curl wget git build-essential software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release ufw htop \
    jq unzip tar lz4 make gcc automake autoconf pkg-config libssl-dev
check_command "Базовые зависимости установлены"

print_header "Настройка Firewall"
ufw --force enable
ufw allow ssh
ufw allow 8545  # RPC HTTP
ufw allow 8546  # RPC WebSocket
ufw allow 30303 # P2P Ethereum
ufw allow 9000  # P2P Beacon Chain
ufw allow 5052  # Beacon API
check_command "Firewall настроен"

print_header "Установка Docker"
# Удаление старых версий
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    apt-get remove $pkg -y 2>/dev/null
done

# Установка Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
check_command "Docker установлен"

# Тест Docker
docker run hello-world >/dev/null 2>&1
check_command "Docker протестирован"

print_header "Установка EthPillar"
# Скачивание и установка EthPillar
ETHPILLAR_VERSION=$(curl -s https://api.github.com/repos/ChorusOne/eth-pillar/releases/latest | jq -r .tag_name)
curl -L "https://github.com/ChorusOne/eth-pillar/releases/download/${ETHPILLAR_VERSION}/ethpillar-linux-amd64" -o /usr/local/bin/ethpillar
chmod +x /usr/local/bin/ethpillar
check_command "EthPillar установлен (версия: $ETHPILLAR_VERSION)"

print_header "Установка Nethermind (Execution Client)"
ethpillar install nethermind
check_command "Nethermind установлен"

print_header "Установка Lighthouse (Consensus Client)"
ethpillar install lighthouse
check_command "Lighthouse установлен"

print_header "Настройка Nethermind"
# Создание конфигурации Nethermind
mkdir -p /etc/nethermind
cat > /etc/nethermind/holesky.json << EOF
{
  "Init": {
    "WebSocketsEnabled": true,
    "StoreReceipts": true,
    "IsMining": false,
    "ChainSpecPath": "chainspec/holesky.json",
    "BaseDbPath": "nethermind_db/holesky",
    "LogFileName": "holesky.logs.txt",
    "MemoryHint": 2048000000
  },
  "Network": {
    "DiscoveryPort": 30303,
    "P2PPort": 30303,
    "LocalIp": "0.0.0.0",
    "ExternalIp": "$SERVER_IP"
  },
  "JsonRpc": {
    "Enabled": true,
    "Timeout": 20000,
    "Host": "0.0.0.0",
    "Port": 8545,
    "WebSocketsPort": 8546,
    "EnabledModules": ["Eth", "Subscribe", "Trace", "TxPool", "Web3", "Personal", "Proof", "Net", "Parity", "Health", "Rpc"]
  },
  "Sync": {
    "AncientBodiesBarrier": 11052984,
    "AncientReceiptsBarrier": 11052984,
    "FastSync": true,
    "PivotNumber": 2000000,
    "PivotHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "PivotTotalDifficulty": "0x0",
    "FastBlocks": true,
    "UseGethLimitsInFastBlocks": false,
    "DownloadBodiesInFastSync": true,
    "DownloadReceiptsInFastSync": true
  }
}
EOF

# Создание systemd сервиса для Nethermind
cat > /etc/systemd/system/execution.service << EOF
[Unit]
Description=Nethermind Execution Client (Holesky)
Wants=network-online.target
After=network-online.target
Documentation=https://docs.nethermind.io

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=3
KillSignal=SIGINT
TimeoutStopSec=900
ExecStart=/usr/local/bin/nethermind/Nethermind.Runner --config holesky --JsonRpc.Host 0.0.0.0 --JsonRpc.Port 8545 --JsonRpc.WebSocketsPort 8546
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

check_command "Nethermind настроен"

print_header "Настройка Lighthouse"
# Создание systemd сервиса для Lighthouse
cat > /etc/systemd/system/consensus.service << EOF
[Unit]
Description=Lighthouse Consensus Client (Holesky)
Wants=network-online.target
After=network-online.target execution.service
Documentation=https://lighthouse-book.sigmaprime.io

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=3
KillSignal=SIGINT
TimeoutStopSec=900
ExecStart=/usr/local/bin/lighthouse/lighthouse beacon_node \\
    --network holesky \\
    --datadir /var/lib/lighthouse \\
    --http \\
    --http-address 0.0.0.0 \\
    --http-port 5052 \\
    --execution-endpoint http://127.0.0.1:8545 \\
    --execution-jwt /var/lib/nethermind/keystore/jwt.hex \\
    --checkpoint-sync-url https://holesky.beaconstate.info
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

check_command "Lighthouse настроен"

print_header "Создание директорий данных"
mkdir -p /var/lib/nethermind
mkdir -p /var/lib/lighthouse
mkdir -p /var/lib/nethermind/keystore

# Генерация JWT секрета
openssl rand -hex 32 > /var/lib/nethermind/keystore/jwt.hex
chmod 600 /var/lib/nethermind/keystore/jwt.hex
check_command "JWT секрет создан"

print_header "Запуск сервисов"
systemctl daemon-reload
systemctl enable execution.service
systemctl enable consensus.service

# Запуск Execution Client
systemctl start execution.service
sleep 10
check_command "Execution client запущен"

# Ожидание синхронизации Execution Client (минимум 30 секунд)
echo "⏳ Ожидание инициализации Execution Client..."
sleep 30

# Запуск Consensus Client
systemctl start consensus.service
check_command "Consensus client запущен"

print_header "Проверка статуса сервисов"
echo "📊 Статус Execution Client:"
systemctl status execution.service --no-pager -l

echo ""
echo "📊 Статус Consensus Client:"
systemctl status consensus.service --no-pager -l

print_header "Проверка RPC подключения"
sleep 5
RPC_TEST=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545)
if [[ $RPC_TEST == *"result"* ]]; then
    echo "✅ RPC подключение работает"
    echo "📡 RPC доступен по адресу: http://$SERVER_IP:8545"
else
    echo "⚠️ RPC подключение не готово, может потребоваться время для синхронизации"
fi

print_header "Создание скрипта мониторинга"
cat > /usr/local/bin/holesky-status.sh << 'EOF'
#!/bin/bash
echo "=== Статус ноды Holesky ==="
echo "Время: $(date)"
echo ""

echo "🔧 Статус сервисов:"
systemctl is-active execution.service && echo "✅ Execution Client: Активен" || echo "❌ Execution Client: Неактивен"
systemctl is-active consensus.service && echo "✅ Consensus Client: Активен" || echo "❌ Consensus Client: Неактивен"
echo ""

echo "📊 Использование ресурсов:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo "RAM: $(free -h | awk 'NR==2{printf "%.1f/%.1f GB (%.2f%%)\n", $3/1024/1024, $2/1024/1024, $3*100/$2}')"
echo "Диск: $(df -h / | awk 'NR==2{printf "%s/%s (%s)\n", $3, $2, $5}')"
echo ""

echo "🌐 Сетевые подключения:"
PEERS_ETH=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' http://localhost:8545 2>/dev/null | jq -r .result 2>/dev/null)
if [ "$PEERS_ETH" != "null" ] && [ -n "$PEERS_ETH" ]; then
    echo "📡 Execution peers: $((16#${PEERS_ETH#0x}))"
else
    echo "📡 Execution peers: Недоступно"
fi

BEACON_PEERS=$(curl -s http://localhost:5052/eth/v1/node/peer_count 2>/dev/null | jq -r .data.connected 2>/dev/null)
if [ "$BEACON_PEERS" != "null" ] && [ -n "$BEACON_PEERS" ]; then
    echo "🔗 Beacon peers: $BEACON_PEERS"
else
    echo "🔗 Beacon peers: Недоступно"
fi

echo ""
echo "🔄 Синхронизация:"
SYNC_STATUS=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8545 2>/dev/null | jq -r .result 2>/dev/null)
if [ "$SYNC_STATUS" = "false" ]; then
    echo "✅ Execution Client: Синхронизирован"
else
    echo "🔄 Execution Client: Синхронизация..."
fi

BEACON_SYNC=$(curl -s http://localhost:5052/eth/v1/node/syncing 2>/dev/null | jq -r .data.is_syncing 2>/dev/null)
if [ "$BEACON_SYNC" = "false" ]; then
    echo "✅ Beacon Client: Синхронизирован"
else
    echo "🔄 Beacon Client: Синхронизация..."
fi
EOF

chmod +x /usr/local/bin/holesky-status.sh
check_command "Скрипт мониторинга создан"

print_header "Завершение установки"
echo ""
echo "🎉 Установка ноды Holesky завершена!"
echo ""
echo "📋 Полезные команды:"
echo "   Статус: /usr/local/bin/holesky-status.sh"
echo "   Логи Execution: journalctl -f -u execution.service"
echo "   Логи Consensus: journalctl -f -u consensus.service"
echo "   Перезапуск Execution: sudo systemctl restart execution.service"
echo "   Перезапуск Consensus: sudo systemctl restart consensus.service"
echo ""
echo "🌐 Эндпоинты:"
echo "   RPC HTTP: http://$SERVER_IP:8545"
echo "   RPC WebSocket: ws://$SERVER_IP:8546"
echo "   Beacon API: http://$SERVER_IP:5052"
echo ""
echo "⚠️ Важно: Синхронизация может занять несколько часов!"
echo "💡 Проверьте статус через 10-15 минут: /usr/local/bin/holesky-status.sh" 