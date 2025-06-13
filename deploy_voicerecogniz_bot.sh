#!/bin/bash

echo "🚀 Установка VoiceRecogniz Bot..."

GIT_REPO_NAME="voicerecogniz_bot"
PROJECT_DIR="$HOME/$GIT_REPO_NAME"

# Установка системных зависимостей
apt update
apt install -y python3.12 python3.12-venv python3.12-dev screen git build-essential libffi-dev libssl-dev ffmpeg python-is-python3

# Очистка и создание проекта
rm -rf "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR" || exit 1

# Виртуальное окружение
python3.12 -m venv venv
source venv/bin/activate

# Зависимости
cat <<EOF > requirements.txt
aiogram==3.*
openai==1.*
python-dotenv
EOF

pip install --upgrade pip
pip install -r requirements.txt

# Код бота
cat <<'PYCODE' > main.py
import asyncio
import logging
import os
import tempfile
from aiogram import F, Bot, Dispatcher
from aiogram.enums import ParseMode
from aiogram.types import Message
from aiogram.filters import CommandStart
from aiogram.fsm.storage.memory import MemoryStorage
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
BOT_TOKEN = os.getenv("BOT_TOKEN")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")

client = OpenAI(api_key=OPENAI_API_KEY)
bot = Bot(token=BOT_TOKEN, default=ParseMode.HTML)
dp = Dispatcher(storage=MemoryStorage())

def generate_summary_from_audio(audio_path: str) -> str:
    logging.info(f"📥 Отправляем файл в Whisper: {audio_path}")
    with open(audio_path, "rb") as audio_file:
        transcript = client.audio.transcriptions.create(
            model="whisper-1",
            file=audio_file,
            response_format="text",
            language="ru"
        )
    logging.info(f"📝 Распознанный текст: {transcript[:100]}..." if transcript else "⚠️ Whisper не распознал текст.")
    prompt = (
        "Распознай текст голосового сообщения и оформи его в читабельном виде как письменный монолог — "
        "раздели на абзацы, добавь знаки препинания, чтобы текст легко читался, как рассказ или сообщение в мессенджере.\n\n"
        "Затем снизу оформи краткий конспект сказанного в 2–4 предложениях.\n\n"
        "Результат оформи в следующем виде:\n"
        "📝 <b>Текст сообщения:</b>\n<оформленный текст>\n\n"
        "💡 <b>Суть сообщения:</b>\n<краткий вывод>\n\n"
        "Вот текст для обработки:\n"
        f"{transcript}"
    )
    logging.info("✉️ Отправляем текст в GPT для составления конспекта...")
    completion = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.4,
        max_tokens=300
    )
    result = completion.choices[0].message.content.strip()
    logging.info("✅ GPT вернул результат.")
    return result

@dp.message(CommandStart())
async def start_handler(message: Message):
    await message.answer("Привет! Перешли мне голосовое сообщение, и я сделаю его краткий конспект.")

@dp.message(F.voice)
async def handle_forwarded_voice(message: Message):
    user_name = message.forward_from.full_name if message.forward_from else "Неизвестный пользователь"
    logging.info(f"🎧 Обработка голосового от {user_name}")
    if message.voice.duration > 60:
        await message.reply("⚠️ Сообщение длится более 60 секунд. Оно может быть обработано не полностью.")
    with tempfile.TemporaryDirectory() as tmpdir:
        audio_path = os.path.join(tmpdir, "voice.ogg")
        try:
            file = await bot.get_file(message.voice.file_id)
            file_bytes = await bot.download_file(file.file_path)
            with open(audio_path, "wb") as f:
                f.write(file_bytes.getvalue())
            logging.info(f"📂 Файл voice.ogg сохранён в {audio_path}")
            summary = generate_summary_from_audio(audio_path)
            if not summary.strip():
                logging.warning("⚠️ Получен пустой ответ от GPT.")
                await message.reply(f"<b>👤 {user_name}</b>\n⚠️ Не удалось распознать или обработать голосовое сообщение.")
            else:
                await message.reply(f"<b>👤 {user_name}</b>\n{summary}")
        except Exception as e:
            logging.exception("❌ Ошибка при обработке голосового:")
            await message.reply(f"<b>👤 {user_name}</b>\n❌ Произошла ошибка. Попробуй позже.")

async def main():
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
PYCODE

# .env
cat <<EOF > .env
BOT_TOKEN=вставь_сюда_токен
OPENAI_API_KEY=вставь_сюда_ключ
EOF

# Скрипт запуска
cat <<'EOS' > start.sh
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
touch log.txt
python main.py >> log.txt 2>&1
EOS

chmod +x start.sh

# Завершение старой сессии
screen -ls | grep '\.voicerecogniz_bot' | awk '{print $1}' | xargs -r -n 1 -I{} screen -S {} -X quit

# Запуск
screen -dmS voicerecogniz_bot "$PROJECT_DIR/start.sh"

echo "✅ VoiceRecogniz Bot запущен. Подключиться: screen -r voicerecogniz_bot"
