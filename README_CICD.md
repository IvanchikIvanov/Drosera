# CI/CD Setup для Drosera Nodes

## 🚀 Настройка GitHub Actions

### 1. GitHub Secrets

Добавь в **Settings** → **Secrets and variables** → **Actions**:

#### Серверы:
```
SERVER1_HOST = IP_первого_сервера
SERVER1_USER = root
SERVER2_HOST = IP_второго_сервера
SERVER2_USER = root
SSH_PRIVATE_KEY = приватный_SSH_ключ_для_всех_серверов
```

#### Приватные ключи Drosera:
```
DROSERA_PRIVATE_KEY_SERVER1 = 0x123abc...
DROSERA_PRIVATE_KEY_SERVER2 = 0x456def...
```



#### RPC настройки:
```
HOLESKY_RPC_URL = https://ваш-holesky-rpc.com
BACKUP_RPC_URL = https://ethereum-holesky-rpc.publicnode.com
```

#### Git настройки:
```
GITHUB_EMAIL = your-email@example.com
GITHUB_USERNAME = your-username
```

#### Уведомления (опционально):
```
DISCORD_WEBHOOK = https://discord.com/api/webhooks/...
```

### 2. Создание SSH ключей

#### Создать один SSH ключ (выполни на любом компьютере):
```bash
# Создать SSH ключ
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy -N ""

# Показать приватный ключ (скопируй в GitHub Secret SSH_PRIVATE_KEY)
cat ~/.ssh/github_deploy

# Показать публичный ключ (скопируй на все серверы)
cat ~/.ssh/github_deploy.pub
```

#### Добавить публичный ключ на ВСЕ серверы:
```bash
# На каждом сервере (Сервер 1, Сервер 2, и т.д.)
cat ~/.ssh/github_deploy.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 3. Использование

#### Автоматический деплой:
- Push в `main` или `develop` → автоматический деплой на оба сервера

#### Ручной деплой:
- **Actions** → **Deploy Drosera Nodes** → **Run workflow**
- Выбери сервер: `server1`, `server2` или `both`

#### Мониторинг:
- Health checks каждые 15 минут автоматически
- Уведомления в Discord при проблемах

## 📊 Мониторинг

### Локальный мониторинг на сервере:
```bash
chmod +x scripts/monitor.sh
./scripts/monitor.sh
```

### Логи контейнера:
```bash
cd /root/DROSERA
docker-compose logs -f
```

### Статус сервисов:
```bash
cd /root/DROSERA
docker-compose ps
```

## 🔧 Troubleshooting

### Перезапуск контейнера:
```bash
cd /root/DROSERA
docker-compose restart
```

### Полный перезапуск:
```bash
cd /root/DROSERA
docker-compose down
docker-compose up -d
```

### Проверка портов:
```bash
netstat -tuln | grep -E ":31313|:31314"
```

## 🎯 Файлы в репозитории

- `.github/workflows/deploy.yml` - основной pipeline деплоя
- `.github/workflows/health-check.yml` - мониторинг здоровья нод
- `scripts/monitor.sh` - скрипт локального мониторинга
- `docker-compose.yaml` - конфигурация с переменными окружения

## ✅ Готово!

После push этих файлов в GitHub, CI/CD pipeline будет готов к работе! 