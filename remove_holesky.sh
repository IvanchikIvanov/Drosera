#!/bin/bash

# Скрипт удаления ноды Holesky
# Полное удаление всех компонентов

echo "🗑️ Начинаю удаление ноды Holesky..."

# Функция для проверки успешности выполнения команды
check_command() {
    if [ $? -ne 0 ]; then
        echo "⚠️ Предупреждение: $1"
    else
        echo "✅ $1"
    fi
}

# Остановка всех связанных сервисов
echo "🛑 Остановка сервисов..."
sudo systemctl stop execution.service 2>/dev/null
check_command "Остановлен execution.service"

sudo systemctl stop consensus.service 2>/dev/null
check_command "Остановлен consensus.service"

sudo systemctl stop validator.service 2>/dev/null
check_command "Остановлен validator.service"

sudo systemctl stop nethermind.service 2>/dev/null
check_command "Остановлен nethermind.service"

sudo systemctl stop lighthouse.service 2>/dev/null
check_command "Остановлен lighthouse.service"

# Отключение автозапуска сервисов
echo "🔒 Отключение автозапуска сервисов..."
sudo systemctl disable execution.service 2>/dev/null
check_command "Отключен автозапуск execution.service"

sudo systemctl disable consensus.service 2>/dev/null
check_command "Отключен автозапуск consensus.service"

sudo systemctl disable validator.service 2>/dev/null
check_command "Отключен автозапуск validator.service"

sudo systemctl disable nethermind.service 2>/dev/null
check_command "Отключен автозапуск nethermind.service"

sudo systemctl disable lighthouse.service 2>/dev/null
check_command "Отключен автозапуск lighthouse.service"

# Удаление файлов сервисов
echo "🗂️ Удаление файлов сервисов..."
sudo rm -f /etc/systemd/system/execution.service
check_command "Удален execution.service"

sudo rm -f /etc/systemd/system/consensus.service
check_command "Удален consensus.service"

sudo rm -f /etc/systemd/system/validator.service
check_command "Удален validator.service"

sudo rm -f /etc/systemd/system/nethermind.service
check_command "Удален nethermind.service"

sudo rm -f /etc/systemd/system/lighthouse.service
check_command "Удален lighthouse.service"

# Перезагрузка systemd
sudo systemctl daemon-reload
check_command "Перезагружен systemd daemon"

# Удаление EthPillar
echo "🏗️ Удаление EthPillar..."
if command -v ethpillar &> /dev/null; then
    sudo rm -f /usr/local/bin/ethpillar
    check_command "Удален EthPillar binary"
fi

# Удаление директорий данных
echo "📁 Удаление директорий данных..."
sudo rm -rf /usr/local/bin/nethermind
check_command "Удалена директория Nethermind"

sudo rm -rf /usr/local/bin/lighthouse
check_command "Удалена директория Lighthouse"

sudo rm -rf /var/lib/nethermind
check_command "Удалена директория данных Nethermind"

sudo rm -rf /var/lib/lighthouse
check_command "Удалена директория данных Lighthouse"

sudo rm -rf ~/.ethereum
check_command "Удалена директория ~/.ethereum"

sudo rm -rf ~/.lighthouse
check_command "Удалена директория ~/.lighthouse"

# Удаление конфигурационных файлов
echo "⚙️ Удаление конфигурационных файлов..."
sudo rm -rf /etc/nethermind
check_command "Удалены конфиги Nethermind"

sudo rm -rf /etc/lighthouse
check_command "Удалены конфиги Lighthouse"

# Удаление логов
echo "📋 Удаление логов..."
sudo rm -rf /var/log/nethermind
check_command "Удалены логи Nethermind"

sudo rm -rf /var/log/lighthouse
check_command "Удалены логи Lighthouse"

# Очистка Docker контейнеров (если использовались)
echo "🐳 Очистка Docker контейнеров..."
if command -v docker &> /dev/null; then
    sudo docker stop $(sudo docker ps -aq --filter "ancestor=nethermind" --filter "ancestor=lighthouse") 2>/dev/null
    sudo docker rm $(sudo docker ps -aq --filter "ancestor=nethermind" --filter "ancestor=lighthouse") 2>/dev/null
    sudo docker rmi nethermind/nethermind lighthouse/lighthouse 2>/dev/null
    check_command "Очищены Docker контейнеры"
fi

# Удаление пользователей (если создавались)
echo "👤 Удаление пользователей..."
if id "nethermind" &>/dev/null; then
    sudo userdel -r nethermind 2>/dev/null
    check_command "Удален пользователь nethermind"
fi

if id "lighthouse" &>/dev/null; then
    sudo userdel -r lighthouse 2>/dev/null
    check_command "Удален пользователь lighthouse"
fi

# Очистка портов (закрытие firewall правил)
echo "🔥 Очистка правил firewall..."
sudo ufw delete allow 8545 2>/dev/null
sudo ufw delete allow 8546 2>/dev/null
sudo ufw delete allow 30303 2>/dev/null
sudo ufw delete allow 9000 2>/dev/null
sudo ufw delete allow 5052 2>/dev/null
check_command "Очищены правила firewall"

# Очистка переменных окружения
echo "🌍 Очистка переменных окружения..."
if [ -f ~/.bashrc ]; then
    sed -i '/export.*NETHERMIND/d' ~/.bashrc
    sed -i '/export.*LIGHTHOUSE/d' ~/.bashrc
    sed -i '/export.*ETH_/d' ~/.bashrc
    check_command "Очищены переменные окружения"
fi

echo ""
echo "🎉 Удаление ноды Holesky завершено!"
echo "💡 Рекомендуется перезагрузить систему для полной очистки:"
echo "   sudo reboot"
echo ""
echo "📊 Освобождено место на диске:"
df -h / 