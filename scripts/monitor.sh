#!/bin/bash

# Скрипт мониторинга ноды Drosera
# Использование: ./scripts/monitor.sh

echo "=== Drosera Node Status ==="
echo "Time: $(date)"
echo "Server: $(hostname)"
echo "IP: $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo ""

# Проверка директории
if [ ! -d "/root/DROSERA" ]; then
    echo "❌ DROSERA directory not found!"
    exit 1
fi

cd /root/DROSERA

# Docker status
echo "🐳 Docker Status:"
if command -v docker-compose &> /dev/null; then
    docker-compose ps
    CONTAINER_STATUS=$(docker-compose ps | grep "Up" | wc -l)
    if [ "$CONTAINER_STATUS" -eq 0 ]; then
        echo "❌ No containers running!"
    else
        echo "✅ $CONTAINER_STATUS container(s) running"
    fi
else
    echo "❌ Docker Compose not found!"
fi

echo ""
echo "📊 Resource Usage:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo "RAM: $(free -h | awk 'NR==2{printf "%.1f/%.1f GB (%.2f%%)\n", $3/1024/1024, $2/1024/1024, $3*100/$2}')"
echo "Disk: $(df -h / | awk 'NR==2{printf "%s/%s (%s)\n", $3, $2, $5}')"

echo ""
echo "🌐 Network Ports:"
PORTS_OPEN=0
if netstat -tuln | grep -q ":31313"; then
    echo "✅ P2P port 31313 - OPEN"
    PORTS_OPEN=$((PORTS_OPEN + 1))
else
    echo "❌ P2P port 31313 - CLOSED"
fi

if netstat -tuln | grep -q ":31314"; then
    echo "✅ Server port 31314 - OPEN"
    PORTS_OPEN=$((PORTS_OPEN + 1))
else
    echo "❌ Server port 31314 - CLOSED"
fi

echo ""
echo "🔗 Network Connections:"
P2P_CONNECTIONS=$(netstat -an | grep ":31313" | grep "ESTABLISHED" | wc -l)
echo "P2P connections: $P2P_CONNECTIONS"

echo ""
echo "📋 Recent Logs (last 20 lines):"
if command -v docker-compose &> /dev/null; then
    docker-compose logs --tail=20
else
    echo "❌ Cannot show logs - Docker Compose not available"
fi

echo ""
echo "🔍 Error Summary:"
if command -v docker-compose &> /dev/null; then
    ERROR_COUNT=$(docker-compose logs --tail=100 | grep -i "error\|fatal\|panic" | wc -l)
    WARNING_COUNT=$(docker-compose logs --tail=100 | grep -i "warn" | wc -l)
    echo "Errors in last 100 lines: $ERROR_COUNT"
    echo "Warnings in last 100 lines: $WARNING_COUNT"
    
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo ""
        echo "⚠️ Recent Errors:"
        docker-compose logs --tail=100 | grep -i "error\|fatal\|panic" | tail -5
    fi
fi

echo ""
echo "=== Status Summary ==="
if [ "$CONTAINER_STATUS" -gt 0 ] && [ "$PORTS_OPEN" -eq 2 ]; then
    echo "✅ Node Status: HEALTHY"
    exit 0
else
    echo "❌ Node Status: UNHEALTHY"
    exit 1
fi 