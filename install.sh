#!/bin/bash

echo "🚀 Установка VoiceRecogniz Bot в изолированную среду..."

# === Константы ===
BOT_NAME="voicerecogniz_bot"
INSTALL_DIR="$HOME/.bots/$BOT_NAME"
SESSION_NAME="$BOT_NAME"

# === Загрузка .env ===
ENV_FILE="$HOME/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env не найден в $ENV_FILE"
  exit 1
fi
source "$ENV_FILE"

# Проверка токена GitHub
if [[ -z "<REDACTED>" ]]; then
  echo "❌ Не задан GITHUB_TOKEN в .env"
  exit 1
fi

# === Установка зависимостей ===
apt update
apt install -y software-properties-common git screen python-is-python3
add-apt-repository -y ppa:deadsnakes/ppa
apt update
apt install -y python3.12 python3.12-venv python3.12-dev libffi-dev libssl-dev ffmpeg build-essential

# === Клонирование репозитория ===
echo "🌐 Клонируем GitHub репозиторий..."
rm -rf "$INSTALL_DIR"
git clone https://rustamnova:<REDACTED>@github.com/rustamnova/voicerecogniz_bot.git "$INSTALL_DIR"

cd "$INSTALL_DIR" || exit 1

# === Виртуальное окружение ===
python3.12 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# === Подстановка .env, если его нет ===
if [ ! -f ".env" ]; then
  echo "🔐 Копируем .env из корня..."
  cp "$ENV_FILE" .env
fi

# === start.sh ===
echo "⚙️ Создаём start.sh..."
cat <<EOF > start.sh
#!/bin/bash
cd "\$(dirname "\$0")"
source venv/bin/activate
touch log.txt
echo "[\$(date)] Запуск VoiceRecogniz Bot..." >> log.txt
python main.py >> log.txt 2>&1
EOF

chmod +x start.sh

# === Удаление старой screen-сессии ===
echo "🧹 Завершаем старые screen-сессии..."
screen -ls | grep "\\.${SESSION_NAME}" | awk '{print $1}' | xargs -r -n 1 screen -S

# === Запуск в новой screen-сессии ===
echo "📺 Запускаем бота в screen: $SESSION_NAME"
screen -dmS "$SESSION_NAME" "$INSTALL_DIR/start.sh"

echo "✅ Установка завершена!"
echo "🔍 screen -r $SESSION_NAME"
