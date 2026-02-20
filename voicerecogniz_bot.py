import asyncio
import logging
import logging.handlers
import os
import sys
import tempfile
from datetime import datetime
from shutil import copyfile

from aiogram import F, Bot, Dispatcher
from aiogram.enums import ParseMode
from aiogram.client.default import DefaultBotProperties
from aiogram.types import Message
from aiogram.filters import CommandStart
from aiogram.fsm.storage.memory import MemoryStorage
from dotenv import load_dotenv
from openai import OpenAI

# === Настройки ===
DEBUG = True

# Загрузка переменных из .env
load_dotenv(override=True)
BOT_TOKEN = os.getenv("BOT_TOKEN")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
USER_IDS = list(map(int, os.getenv("USER_IDS", "").split(",")))  # 👈 исправлено

# Логирование
_BASE_DIR = os.path.dirname(os.path.abspath(__file__))
_LOGS_DIR = os.path.join(_BASE_DIR, "logs")
os.makedirs(_LOGS_DIR, exist_ok=True)

_fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")

_worklog_handler = logging.handlers.RotatingFileHandler(
    os.path.join(_LOGS_DIR, "worklog.txt"), maxBytes=10 * 1024 * 1024, backupCount=5, encoding="utf-8"
)
_worklog_handler.setLevel(logging.INFO)
_worklog_handler.setFormatter(_fmt)

_error_handler = logging.handlers.RotatingFileHandler(
    os.path.join(_LOGS_DIR, "errors.txt"), maxBytes=5 * 1024 * 1024, backupCount=3, encoding="utf-8"
)
_error_handler.setLevel(logging.ERROR)
_error_handler.setFormatter(_fmt)

_console_handler = logging.StreamHandler(sys.stdout)
_console_handler.setLevel(logging.INFO)
_console_handler.setFormatter(_fmt)

logging.basicConfig(level=logging.INFO, handlers=[_worklog_handler, _error_handler, _console_handler])


def log_install(msg: str):
    with open(os.path.join(_LOGS_DIR, "install.txt"), "a", encoding="utf-8") as f:
        f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")

# Инициализация OpenAI и бота
client = OpenAI(api_key=OPENAI_API_KEY)
bot = Bot(token=BOT_TOKEN, default=DefaultBotProperties(parse_mode=ParseMode.HTML))
dp = Dispatcher(storage=MemoryStorage())

# === GPT-функция ===
def generate_summary_from_audio(audio_path: str) -> str:
    logging.info(f"📥 Whisper получает файл: {audio_path}")
    with open(audio_path, "rb") as audio_file:
        transcript = client.audio.transcriptions.create(
            model="whisper-1",
            file=audio_file,
            response_format="text",
            language="ru"
        )

    if not transcript or not transcript.strip():
        logging.warning("⚠️ Whisper не распознал текст.")
        return ""

    logging.info(f"📝 Распознанный текст: {transcript[:100]}...")

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

    logging.info("✉️ Отправляем текст в GPT...")
    completion = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.4,
        max_tokens=4000
    )

    return completion.choices[0].message.content.strip()

# === Отправка длинных сообщений (Telegram лимит 4096 символов) ===
async def send_long_message(message: Message, text: str):
    limit = 4096
    if len(text) <= limit:
        await message.reply(text)
        return
    # Разбиваем по абзацам, не разрывая слова
    parts = []
    while len(text) > limit:
        split_at = text.rfind("\n\n", 0, limit)
        if split_at == -1:
            split_at = text.rfind("\n", 0, limit)
        if split_at == -1:
            split_at = limit
        parts.append(text[:split_at])
        text = text[split_at:].lstrip()
    if text:
        parts.append(text)
    for i, part in enumerate(parts):
        if i == 0:
            await message.reply(part)
        else:
            await message.answer(part)

# === Команда /start ===
@dp.message(CommandStart())
async def start_handler(message: Message):
    if message.from_user.id not in USER_IDS:
        logging.warning(f"⛔ Попытка запуска от чужого пользователя: {message.from_user.id}")
        await message.reply("⛔ Вы не авторизованы для использования этого бота.")
        return

    await message.answer("Привет! Перешли мне голосовое сообщение, и я сделаю его краткий конспект.")

# === Обработка голосового ===
@dp.message(F.voice)
async def handle_voice(message: Message):
    if message.from_user.id not in USER_IDS:
        logging.warning(f"⛔ Запрос от неавторизованного пользователя: {message.from_user.id}")
        await message.reply("⛔ Вы не авторизованы для использования этого бота.")
        return

    user_name = message.forward_from.full_name if message.forward_from else "Неизвестный пользователь"
    logging.info(f"🎧 Голосовое от: {user_name}")
    logging.info(f"⏱ Длительность: {message.voice.duration} сек. | 📦 Размер: {message.voice.file_size} байт.")

    # Максимум 10 минут (600 секунд)
    if message.voice.duration > 600:
        await message.reply(f"⚠️ Сообщение слишком длинное ({message.voice.duration} сек). Максимум — 10 минут (600 сек).")
        logging.warning(f"⚠️ Отклонено: аудио длится {message.voice.duration} сек (лимит 600 сек).")
        return

    with tempfile.TemporaryDirectory() as tmpdir:
        audio_path = os.path.join(tmpdir, "voice.ogg")

        try:
            # Скачивание
            file = await bot.get_file(message.voice.file_id)
            file_bytes = await bot.download_file(file.file_path)
            with open(audio_path, "wb") as f:
                f.write(file_bytes.getvalue())
            logging.info(f"📂 Файл сохранён: {audio_path}")

            # Анализ
            summary = generate_summary_from_audio(audio_path)

            if not summary.strip():
                logging.warning("⚠️ GPT вернул пустой результат.")
                if DEBUG:
                    os.makedirs("debug_audio", exist_ok=True)
                    saved_path = f"debug_audio/voice_{message.message_id}.ogg"
                    copyfile(audio_path, saved_path)
                    logging.info(f"🧪 Аудио сохранено для отладки: {saved_path}")

                await message.reply(f"<b>👤 {user_name}</b>\n⚠️ Не удалось распознать сообщение. Попробуй другое.")
            else:
                await send_long_message(message, f"<b>👤 {user_name}</b>\n{summary}")

        except Exception as e:
            logging.exception("❌ Ошибка при обработке голосового:")
            await message.reply(f"<b>👤 {user_name}</b>\n❌ Произошла ошибка. Попробуй позже.")

# === Запуск бота ===
async def main():
    log_install(f"=== Запуск voicerecogniz_bot === (Python {sys.version.split()[0]})")
    logging.info("voicerecogniz_bot запущен")
    try:
        await dp.start_polling(bot)
    finally:
        log_install("=== Остановка voicerecogniz_bot ===")

if __name__ == "__main__":
    asyncio.run(main())
