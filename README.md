# VoiceRecogniz — транскрибатор голосовых сообщений

Telegram-бот для расшифровки голосовых сообщений. Использует OpenAI Whisper для транскрипции и GPT для создания структурированного резюме.

## Возможности

- Транскрипция голосовых сообщений (OpenAI Whisper)
- Структурированное резюме через GPT
- Поддержка длинных аудиозаписей
- Сохранение аудио для отладки (DEBUG-режим)
- Защита по списку разрешённых пользователей

## Установка

Нужны Python 3.10+, `ffmpeg` и ключ OpenAI.

```bash
git clone https://github.com/rustamnova/voicerecogniz_bot.git
cd voicerecogniz_bot
bash install.sh
```

Скрипт поставит системные зависимости, создаст виртуальное окружение и сделает
`.env` из шаблона. Останется заполнить `.env` и запустить бота.

Если apt недоступен (не Debian/Ubuntu), поставьте `ffmpeg` сами и запустите
`SKIP_APT=1 bash install.sh`.

## Переменные окружения (`.env`)

Шаблон — в [`.env.example`](.env.example).

| Переменная | Описание |
|---|---|
| `BOT_TOKEN` | Токен Telegram-бота, выдаёт [@BotFather](https://t.me/BotFather) |
| `OPENAI_API_KEY` | Ключ OpenAI для Whisper и GPT — [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| `USER_IDS` | Telegram ID пользователей с доступом, через запятую. Свой ID подскажет [@userinfobot](https://t.me/userinfobot) |
| `DEBUG` | `1` — сохранять исходные аудиофайлы для отладки |

Бот отвечает **только** пользователям из `USER_IDS` — это защита от чужих запросов
к вашему платному ключу OpenAI. Оставлять список пустым не стоит.

`.env` внесён в `.gitignore`: не коммитьте его.

## Управление

```bash
bash start.sh      # Запуск
bash stop.sh       # Остановка
bash restart.sh    # Перезапуск
screen -r voicerecogniz_bot  # Подключиться к сессии
```

## Использование

Отправьте голосовое сообщение — бот пришлёт транскрипцию и краткое резюме.

## Команды бота

| Команда | Действие |
|---|---|
| `/start` | Справка |

## Логи

```
logs/
├── worklog.txt   # Рабочий лог (INFO+)
├── errors.txt    # Ошибки (ERROR+)
└── install.txt   # Запуски и остановки
```

## Лицензия

[MIT](LICENSE) — используйте, изменяйте и распространяйте свободно.
