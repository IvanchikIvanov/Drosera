# Drosera Trap Project

## Структура проекта

- `Trap.sol` - основная логика trap на Solidity
- `drosera.toml` - конфигурационный файл

## Установка Drosera CLI

```bash
curl -L https://app.drosera.io/install | bash
```

## Настройка

1. Установите переменную окружения для приватного ключа:
```bash
export PRIVATE_KEY="your_private_key_here"
```

2. Деплой trap:
```bash
drosera deploy
```

3. Запуск оператора:
```bash
drosera operator start
```

## Описание Trap

Этот trap мониторит контракт `IMockResponse` и срабатывает когда:
- Контракт активен (`isActive()` возвращает `true`)
- Discord имя установлено

При срабатывании trap возвращает Discord имя пользователя. 