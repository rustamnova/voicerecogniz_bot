#!/bin/bash
# Установка voicerecogniz_bot.
#
# Скрипт рассчитан на то, что репозиторий уже склонирован и вы находитесь внутри него:
#
#   git clone https://github.com/rustamnova/voicerecogniz_bot.git
#   cd voicerecogniz_bot
#   bash install.sh
#
# Требуется Debian/Ubuntu с sudo либо запуск от root. На других системах поставьте
# зависимости из блока apt вручную и запустите скрипт с SKIP_APT=1.

set -euo pipefail

BOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BOT_DIR"

PYTHON_BIN="${PYTHON_BIN:-python3}"
SKIP_APT="${SKIP_APT:-0}"

echo "📁 Каталог установки: $BOT_DIR"

# ─── Системные зависимости ───────────────────────────────────────────────────
# ffmpeg обязателен: Telegram отдаёт голосовые в OGG/Opus, а Whisper ждёт другой формат.
if [ "$SKIP_APT" != "1" ]; then
    echo "📦 Установка системных зависимостей..."
    SUDO=""
    [ "$(id -u)" -ne 0 ] && SUDO="sudo"
    $SUDO apt-get update -qq
    $SUDO apt-get install -y python3 python3-venv python3-dev git ffmpeg build-essential
    echo "✅ Системные пакеты установлены"
else
    echo "⏭  Пропускаю apt (SKIP_APT=1). Убедитесь, что ffmpeg установлен."
fi

# ─── Python-окружение ────────────────────────────────────────────────────────
echo "🐍 Настройка виртуального окружения..."
"$PYTHON_BIN" -m venv venv
# shellcheck disable=SC1091
source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
echo "✅ Зависимости Python установлены"

# ─── Конфигурация ────────────────────────────────────────────────────────────
if [ ! -f .env ]; then
    cp .env.example .env
    echo
    echo "⚠️  Создан .env из шаблона — заполните его перед запуском:"
    echo "    BOT_TOKEN       токен бота от @BotFather"
    echo "    OPENAI_API_KEY  ключ OpenAI (platform.openai.com/api-keys)"
    echo "    USER_IDS        ваш Telegram ID через запятую (узнать: @userinfobot)"
    echo
    echo "    nano $BOT_DIR/.env"
else
    echo "ℹ️  .env уже существует, не трогаю"
fi

chmod +x start.sh stop.sh restart.sh 2>/dev/null || true

echo
echo "🏁 Установка завершена."
echo "   Запуск:      bash start.sh"
echo "   В фоне:      screen -dmS voicerecogniz_bot ./start.sh"
echo "   Остановка:   bash stop.sh"
