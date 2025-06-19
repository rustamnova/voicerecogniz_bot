from pathlib import Path

voicebot_script_path = Path("/mnt/data/install_voicerecogniz_bot.sh")

voicebot_script = """#!/bin/bash

echo "🚀 Установка VoiceRecogniz Bot..."

# === Переменные ===
GIT_REPO_NAME="voicerecogniz_bot"
PROJECT_DIR="$HOME/$GIT_REPO_NAME"
SESSION_NAME="voicerecogniz_bot"

# === Установка Python 3.12 и зависимостей ===
echo "📦 Устанавливаем зависимости..."
apt update
apt install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt update
apt install -y python3.12 python3.12-venv python3.12-dev screen git build-essential libffi-dev libssl-dev ffmpeg python-is-python3

# === Подготовка проекта ===
echo "🧱 Создаём $PROJECT_DIR"
rm -rf "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR" || exit 1

# === Виртуальное окружение ===
echo "🐍 Создаём виртуальное окружение..."
python3.12 -m venv venv
source venv/bin/activate

# === requirements.txt ===
echo "📄 Создаём requirements.txt..."
cat <<EOF > requirements.txt
aiogram
python-dotenv
openai
EOF

# === Установка Python-зависимостей ===
echo "📚 Устанавливаем Python-библиотеки..."
pip install --upgrade pip
pip install -r requirements.txt

# === main.py ===
echo "📄 Пишем voicerecogniz_bot.py..."
cat <<'PYCODE' > voicerecogniz_bot.py
<REPLACE_WITH_MAIN_CODE>
PYCODE

# === .env ===
echo "🔐 Создаём .env..."
cat <<EOF > .env
BOT_TOKEN=вставь_сюда_токен
OPENAI_API_KEY=вставь_сюда_openai_ключ
EOF

# === start.sh ===
echo "⚙️ Создаём start.sh..."
cat <<'EOS' > start.sh
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
touch log.txt
echo "[`date`] Запуск VoiceRecogniz Bot..." >> log.txt
python main.py >> log.txt 2>&1
EOS
chmod +x start.sh

# === Завершение старых screen-сессий ===
echo "🧹 Удаляем старые screen-сессии '$SESSION_NAME'..."
screen -ls | grep "\\.${SESSION_NAME}" | awk '{print $1}' | xargs -r screen -S {} -X quit

# === Запуск в новой screen-сессии ===
echo "📺 Запускаем VoiceRecogniz бота в новой screen-сессии..."
screen -dmS $SESSION_NAME "$PROJECT_DIR/start.sh"

echo "✅ Бот VoiceRecogniz установлен и запущен!"
echo "📺 Подключиться: screen -r $SESSION_NAME"
"""

# Подставим Python-код (voicerecogniz_bot.py) внутрь скрипта
main_code = Path("main.py").read_text() if Path("main.py").exists() else ""
voicebot_script = voicebot_script.replace("<REPLACE_WITH_MAIN_CODE>", main_code.strip())

# Сохраняем скрипт
voicebot_script_path.write_text(voicebot_script)
voicebot_script_path.name
