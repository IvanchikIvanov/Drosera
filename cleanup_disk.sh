#!/bin/bash

# Скрипт очистки диска после удаления Holesky
echo "🧹 Начинаю очистку диска..."

# Функция для показа использования диска
show_disk_usage() {
    echo "📊 Текущее использование диска:"
    df -h
    echo ""
}

echo "📊 Использование диска ДО очистки:"
show_disk_usage

# Очистка Docker
echo "🐳 Очистка Docker..."
if command -v docker &> /dev/null; then
    # Остановка всех контейнеров
    docker stop $(docker ps -aq) 2>/dev/null
    
    # Удаление всех контейнеров
    docker rm $(docker ps -aq) 2>/dev/null
    
    # Удаление всех образов
    docker rmi $(docker images -q) 2>/dev/null
    
    # Полная очистка Docker
    docker system prune -a --volumes -f
    
    echo "✅ Docker очищен"
else
    echo "⚠️ Docker не найден"
fi

# Очистка логов системы
echo "📋 Очистка системных логов..."
journalctl --vacuum-time=1d
journalctl --vacuum-size=100M
echo "✅ Системные логи очищены"

# Очистка APT кеша
echo "📦 Очистка APT кеша..."
apt-get clean
apt-get autoclean
apt-get autoremove -y
echo "✅ APT кеш очищен"

# Очистка временных файлов
echo "🗂️ Очистка временных файлов..."
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/cache/*
echo "✅ Временные файлы очищены"

# Очистка старых ядер
echo "🔧 Очистка старых ядер..."
apt-get autoremove --purge -y
echo "✅ Старые ядра удалены"

# Поиск и удаление больших файлов
echo "🔍 Поиск больших файлов..."
echo "Топ 20 самых больших файлов:"
find / -type f -size +100M 2>/dev/null | head -20 | while read file; do
    size=$(du -h "$file" 2>/dev/null | cut -f1)
    echo "  $size - $file"
done

# Очистка логов приложений
echo "📝 Очистка логов приложений..."
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
find /var/log -type f -name "*.log.*" -delete
echo "✅ Логи приложений очищены"

# Очистка кеша пользователя
echo "👤 Очистка кеша пользователя..."
rm -rf ~/.cache/*
rm -rf /root/.cache/*
echo "✅ Кеш пользователя очищен"

# Очистка старых файлов snap (если есть)
if command -v snap &> /dev/null; then
    echo "📱 Очистка старых snap пакетов..."
    snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
        snap remove "$snapname" --revision="$revision" 2>/dev/null
    done
    echo "✅ Старые snap пакеты удалены"
fi

# Очистка директорий данных блокчейна (если остались)
echo "⛓️ Очистка остатков блокчейн данных..."
rm -rf /var/lib/nethermind* 2>/dev/null
rm -rf /var/lib/lighthouse* 2>/dev/null
rm -rf /var/lib/ethereum* 2>/dev/null
rm -rf ~/.ethereum* 2>/dev/null
rm -rf ~/.lighthouse* 2>/dev/null
echo "✅ Остатки блокчейн данных удалены"

# Очистка Docker overlay2 (если директория существует)
echo "🐳 Дополнительная очистка Docker overlay2..."
if [ -d "/var/lib/docker/overlay2" ]; then
    systemctl stop docker 2>/dev/null
    rm -rf /var/lib/docker/overlay2/*
    systemctl start docker 2>/dev/null
    echo "✅ Docker overlay2 очищен"
fi

# Очистка на дополнительном диске
echo "💾 Очистка дополнительного диска /mnt/volume_ams3_01..."
if [ -d "/mnt/volume_ams3_01" ]; then
    # Остановка Docker если работает с этого диска
    systemctl stop docker 2>/dev/null
    
    # Удаление Docker данных с дополнительного диска
    rm -rf /mnt/volume_ams3_01/docker/* 2>/dev/null
    
    # Удаление других больших файлов
    find /mnt/volume_ams3_01 -type f -size +10M -delete 2>/dev/null
    
    echo "✅ Дополнительный диск очищен"
fi

# Финальная очистка
echo "🔄 Финальная очистка..."
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

echo ""
echo "📊 Использование диска ПОСЛЕ очистки:"
show_disk_usage

echo ""
echo "🎉 Очистка диска завершена!"
echo "💡 Рекомендуется перезагрузить систему:"
echo "   sudo reboot" 