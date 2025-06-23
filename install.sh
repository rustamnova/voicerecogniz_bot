#!/bin/bash

echo "🚀 Установка VoiceRecogniz Bot..."

# === Название и структура ===
BOT_NAME="voicerecogniz_bot"
BOT_ROOT="/root/.bots"
BOT_DIR="$BOT_ROOT/$BOT_NAME"
SESSION_NAME="$BOT_NAME"
ENV_FILE="$BOT_DIR/.env"

# === Ввод .env ===
echo "📥 Вставьте содержимое .env (включая GITHUB_TOKEN, BOT_TOKEN, OPENAI_API_KEY), затем нажмите Ctrl+D:"
mkdir -p "$BOT_DIR"
cat > "$ENV_FILE"
echo "✅ Файл .env сохранён: $ENV_FILE"

# === Загрузка токенов ===
source "$ENV_FILE"
if [[ -z "<REDACTED>" || -z "$BOT_TOKEN" || -z "$OPENAI_API_KEY" ]]; then
  echo "❌ Не все переменные заданы в .env"
  exit 1
fi

# === Проверка GitHub-доступа ===
echo "🔐 Проверка доступа к приватному репозиторию..."
git ls-remote https://rustamnova:<REDACTED>@github.com/rustamnova/$BOT_NAME.git &>/dev/null
if [ $? -ne 0 ]; then
  echo "❌ Ошибка авторизации в GitHub. Проверь GITHUB_TOKEN."
  exit 1
fi

# === Установка зависимостей ===
echo "📦 Установка системных пакетов..."
apt update
apt install -y software-properties-common git screen python-is-python3
add-apt-repository -y ppa:deadsnakes/ppa
apt update
apt install -y python3.12 python3.12-venv python3.12-dev libffi-dev libssl-dev ffmpeg build-essential

# === Клонирование проекта ===
echo "🌐 Клонирование репозитория..."
rm -rf "$BOT_DIR"
git clone https://rustamnova:<REDACTED>@github.com/rustamnova/$BOT_NAME.git "$BOT_DIR" || {
  echo "❌ Ошибка клонирования."
  exit 1
}

cd "$BOT_DIR" || { echo "❌ Ошибка входа в директорию $BOT_DIR"; exit 1; }

# === Установка виртуального окружения ===
echo "🐍 Настройка venv..."
python3.12 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# === Копируем .env в корень проекта ===
cp "$ENV_FILE" "$BOT_DIR/.env"

# === Создание start.sh ===
echo "⚙️ Создание start.sh..."
cat <<EOF > start.sh
#!/bin/bash
cd "\$(dirname "\$0")"
source venv/bin/activate
touch log.txt
echo "[\$(date)] Запуск $BOT_NAME..." >> log.txt
python voicerecogniz_bot.py >> log.txt 2>&1
EOF
chmod +x start.sh

# === Проверка и запуск screen-сессии ===
if screen -list | grep -q "\\.${SESSION_NAME}"; then
  echo "🧹 Завершаем предыдущую screen-сессию $SESSION_NAME"
  screen -S "$SESSION_NAME" -X quit
fi

echo "📺 Запуск screen-сессии $SESSION_NAME..."
screen -dmS "$SESSION_NAME" "$BOT_DIR/start.sh"

echo "✅ Установка завершена! Бот работает в screen-сессии: $SESSION_NAME"
echo "ℹ️ Подключиться: screen -r $SESSION_NAME"
