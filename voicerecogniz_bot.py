import asyncio
import logging
import os
import tempfile
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
load_dotenv()
BOT_TOKEN = os.getenv("BOT_TOKEN")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
USER_ID = int(os.getenv("USER_ID", "0"))

# Логирование
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)

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
        max_tokens=300
    )

    return completion.choices[0].message.content.strip()

# === Команда /start ===
@dp.message(CommandStart())
async def start_handler(message: Message):
    if message.from_user.id != USER_ID:
        logging.warning(f"⛔ Попытка запуска от чужого пользователя: {message.from_user.id}")
        await message.reply("⛔ Вы не авторизованы для использования этого бота.")
        return

    await message.answer("Привет! Перешли мне голосовое сообщение, и я сделаю его краткий конспект.")

# === Обработка голосового ===
@dp.message(F.voice)
async def handle_voice(message: Message):
    if message.from_user.id != USER_ID:
        logging.warning(f"⛔ Запрос от неавторизованного пользователя: {message.from_user.id}")
        await message.reply("⛔ Вы не авторизованы для использования этого бота.")
        return

    user_name = message.forward_from.full_name if message.forward_from else "Неизвестный пользователь"
    logging.info(f"🎧 Голосовое от: {user_name}")
    logging.info(f"⏱ Длительность: {message.voice.duration} сек. | 📦 Размер: {message.voice.file_size} байт.")

    if message.voice.duration > 60:
        await message.reply("⚠️ Сообщение длится более 60 секунд. Оно может быть обработано не полностью.")
        logging.info("⚠️ Предупреждение: длительное аудио.")

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
                await message.reply(f"<b>👤 {user_name}</b>\n{summary}")

        except Exception as e:
            logging.exception("❌ Ошибка при обработке голосового:")
            await message.reply(f"<b>👤 {user_name}</b>\n❌ Произошла ошибка. Попробуй позже.")

# === Запуск бота ===
async def main():
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
