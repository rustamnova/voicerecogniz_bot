#!/bin/bash

echo "🚀 Установка VoiceRecogniz Bot..."

# === Определение пользователя ===
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
BOT_NAME="voicerecogniz_bot"
INSTALL_DIR="$USER_HOME/.bots/$BOT_NAME"
SESSION_NAME="$BOT_NAME"
ENV_FILE="$USER_HOME/.env"

# === Запрашиваем токены ===
echo "🔐 Введите необходимые токены:"
read -rp "GITHUB_TOKEN: " GITHUB_TOKEN
read -rp "BOT_TOKEN: " BOT_TOKEN
read -rp "OPENAI_API_KEY: " OPENAI_API_KEY

# === Проверка пустых значений ===
if [[ -z "<REDACTED>" || -z "$BOT_TOKEN" || -z "$OPENAI_API_KEY" ]]; then
  echo "❌ Один из токенов не введён. Прерывание установки."
  exit 1
fi

# === Сохраняем в .env ===
mkdir -p "$(dirname "$ENV_FILE")"
cat <<EOF > "$ENV_FILE"
GITHUB_TOKEN=<REDACTED>
BOT_TOKEN=$BOT_TOKEN
OPENAI_API_KEY=$OPENAI_API_KEY
EOF
echo "✅ Файл .env создан: $ENV_FILE"

# === Тест авторизации GitHub токена ===
echo "🔍 Проверка доступа к приватному репозиторию..."
git ls-remote https://rustamnova:<REDACTED>@github.com/rustamnova/voicerecogniz_bot.git &>/dev/null
if [ $? -ne 0 ]; then
  echo "❌ GITHUB_TOKEN недействителен или нет доступа к репозиторию."
  exit 1
fi

# === Установка системных пакетов ===
echo "📦 Установка зависимостей..."
apt update
apt install -y software-properties-common git screen python-is-python3
add-apt-repository -y ppa:deadsnakes/ppa
apt update
apt install -y python3.12 python3.12-venv python3.12-dev libffi-dev libssl-dev ffmpeg build-essential

# === Клонирование проекта ===
echo "🌐 Клонируем репозиторий..."
rm -rf "$INSTALL_DIR"
git clone https://rustamnova:<REDACTED>@github.com/rustamnova/voicerecogniz_bot.git "$INSTALL_DIR" || { echo "❌ Ошибка при клонировании"; exit 1; }

cd "$INSTALL_DIR" || { echo "❌ Не удалось перейти в $INSTALL_DIR"; exit 1; }

# === Настройка virtualenv ===
echo "🐍 Создаём виртуальное окружение..."
python3.12 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# === Копируем .env в папку проекта ===
cp "$ENV_FILE" "$INSTALL_DIR/.env"

# === Скрипт запуска ===
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

# === Завершение screen-сессии, если была ===
if screen -list | grep -q "\\.${SESSION_NAME}"; then
  echo "🧹 Завершаем старую screen-сессию $SESSION_NAME..."
  screen -S "$SESSION_NAME" -X quit
fi

# === Запуск в новой screen-сессии ===
echo "📺 Запускаем бота в screen: $SESSION_NAME"
screen -dmS "$SESSION_NAME" "$INSTALL_DIR/start.sh"

echo "✅ VoiceRecogniz Bot установлен и работает!"
echo "ℹ️ screen -r $SESSION_NAME"
