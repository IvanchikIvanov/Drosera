#!/bin/bash

# Функция для проверки успешности выполнения команды
check_command() {
    if [ $? -ne 0 ]; then
        echo "Ошибка: $1"
        exit 1
    fi
}

# Обновление системы
echo "Обновление системы..."
sudo apt-get update && sudo apt-get upgrade -y
check_command "Ошибка при обновлении системы"

# Установка базовых зависимостей
echo "Установка базовых зависимостей..."
sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano \
    automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev \
    libleveldb-dev tar clang bsdmainutils ncdu unzip -y
check_command "Ошибка при установке базовых зависимостей"

# Удаление старых версий Docker
echo "Удаление старых версий Docker..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    sudo apt-get remove $pkg -y
done

# Установка Docker
echo "Установка Docker..."
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
check_command "Ошибка при установке Docker"

# Тест Docker
echo "Тестирование Docker..."
sudo docker run hello-world
check_command "Ошибка при тестировании Docker"

# Установка Drosera CLI
echo "Установка Drosera CLI..."
curl -L https://app.drosera.io/install | bash
source /root/.bashrc
droseraup
check_command "Ошибка при установке Drosera CLI"

# Установка Foundry
echo "Установка Foundry..."
curl -L https://foundry.paradigm.xyz | bash
export PATH="$PATH:/root/.foundry/bin"
. ~/.bashrc
foundryup
check_command "Ошибка при установке Foundry"

# Проверка установки Foundry
if ! command -v forge &> /dev/null; then
    echo "Forge не установлен корректно. Пробуем исправить PATH..."
    export PATH="$PATH:/root/.foundry/bin"
    if ! command -v forge &> /dev/null; then
        echo "Ошибка: forge все еще не доступен. Попробуйте перезапустить терминал."
        exit 1
    fi
fi

# Установка Bun
echo "Установка Bun..."
curl -fsSL https://bun.sh/install | bash
source /root/.bashrc
check_command "Ошибка при установке Bun"

# Создание и настройка проекта
echo "Создание проекта..."
# Удаляем директорию если она существует
rm -rf my-drosera-trap
mkdir -p my-drosera-trap
cd my-drosera-trap
check_command "Ошибка при создании директории проекта"

# Настройка Git с дефолтными значениями
git config --global user.email "Github_Email"
git config --global user.name "Github_Username"
check_command "Ошибка при настройке Git"

# Клонирование и настройка проекта
echo "Клонирование template..."
git clone https://github.com/drosera-network/trap-foundry-template.git .
check_command "Ошибка при клонировании template"

# Удаляем .git и инициализируем новый репозиторий
rm -rf .git
git init
git add .
git commit -m "Initial commit"
check_command "Ошибка при инициализации git репозитория"

echo "Установка зависимостей и сборка..."
bun install
check_command "Ошибка при установке Bun зависимостей"

# Используем полный путь к forge
/root/.foundry/bin/forge build
check_command "Ошибка при сборке проекта"

echo "Установка завершена успешно!" 