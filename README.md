# Drosera-Network

В этом руководстве мы участвуем в тестовой сети Drosera путем:

- Установки CLI
- Настройки уязвимого контракта
- Развертывания Trap в тестовой сети
- Подключения оператора к Trap

## Рекомендуемые системные требования

- 2 ядра CPU
- 4 ГБ ОЗУ
- 20 ГБ дискового пространства
- VPS от $5
- Собственный Ethereum Holesky RPC в Alchemy или QuickNode

## Установка зависимостей

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
```

## Установка Docker

```bash
sudo apt update -y && sudo apt upgrade -y
for pkg in docker.io docker-doc docker-compose podman-docker containerd.io runc; do sudo apt-get remove $pkg; done

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y && sudo apt upgrade -y

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Проверка Docker
sudo docker run hello-world
```

## Настройка Trap

### 1. Настройка окружения

Drosera CLI:
```bash
curl -L https://app.drosera.io/install | bash
source /root/.bashrc
droseraup
```

Foundry CLI:
```bash
curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc
foundryup
```

Bun:
```bash
curl -fsSL https://bun.sh/install | bash
source /root/.bashrc
```

### 2. Развертывание контракта и Trap

```bash
mkdir my-drosera-trap
cd my-drosera-trap
```

Настройка Git:
```bash
git config --global user.email "Github_Email"
git config --global user.name "Github_Username"
```

Инициализация Trap:
```bash
forge init -t drosera-network/trap-foundry-template
```

Компиляция Trap:
```bash
bun install
forge build
```

Развертывание Trap:
```bash
DROSERA_PRIVATE_KEY=xxx drosera apply
```
Замените xxx на приватный ключ вашего EVM кошелька (убедитесь, что на нем есть Holesky ETH)

Если возникают ошибки RPC (#429), используйте:
```bash
DROSERA_PRIVATE_KEY=xxx drosera apply --eth-rpc-url RPC
```
Замените RPC на ваш Ethereum Holesky RPC из Alchemy или QuickNode.

## Запуск операторов с Docker

1. Создайте файл `.env`:
```
ETH_PRIVATE_KEY=your_evm_private_key
ETH_PRIVATE_KEY2=your_2nd_operator_private_key
VPS_IP=your_vps_public_ip
P2P_PORT1=31313
SERVER_PORT1=31314
P2P_PORT2=31315
SERVER_PORT2=31316
```

2. Используйте docker-compose.yaml для запуска операторов:
```bash
docker compose up -d
```

3. Проверка работы:
```bash
docker logs -f drosera-node1
docker logs -f drosera-node2
```

## Полезные команды

Перезапуск операторов:
```bash
docker compose restart
```

Остановка:
```bash
docker compose down -v
```

Whitelisting операторов:
```bash
cd ~/my-drosera-trap
nano drosera.toml
# Добавьте адреса операторов в whitelist
# private_trap = true
# whitelist = ["1st_Operator_Address","2nd_Operator_Address"]

# Обновите конфигурацию
DROSERA_PRIVATE_KEY=xxx drosera apply
``` 