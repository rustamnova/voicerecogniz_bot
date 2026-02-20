# VoiceRecogniz — транскрибатор голосовых сообщений

Telegram-бот для расшифровки голосовых сообщений. Использует OpenAI Whisper для транскрипции и GPT для создания структурированного резюме.

## Возможности

- Транскрипция голосовых сообщений (OpenAI Whisper)
- Структурированное резюме через GPT
- Поддержка длинных аудиозаписей
- Сохранение аудио для отладки (DEBUG-режим)
- Защита по списку разрешённых пользователей

## Установка

```bash
git clone https://github.com/rustamnova/voicerecogniz_bot.git /root/.bots/voicerecogniz_bot
cd /root/.bots/voicerecogniz_bot
bash install.sh
```

## Переменные окружения (`.env`)

| Переменная | Описание |
|---|---|
| `BOT_TOKEN` | Токен Telegram-бота |
| `OPENAI_API_KEY` | API-ключ OpenAI (Whisper + GPT) |
| `USER_IDS` | Разрешённые Telegram user ID через запятую |

## Управление

```bash
bash start.sh      # Запуск
bash stop.sh       # Остановка
bash restart.sh    # Перезапуск
screen -r voicerecogniz_bot  # Подключиться к сессии
```

## Использование

Отправьте голосовое сообщение — бот пришлёт транскрипцию и краткое резюме.

## Логи

```
logs/
├── worklog.txt   # Рабочий лог (INFO+)
├── errors.txt    # Ошибки (ERROR+)
└── install.txt   # Запуски и остановки
```
