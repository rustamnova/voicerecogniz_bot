import asyncio
import logging
import os
import tempfile

from aiogram import F, Bot, Dispatcher
from aiogram.enums import ParseMode
from aiogram.client.default import DefaultBotProperties
from aiogram.types import Message
from aiogram.filters import CommandStart
from aiogram.fsm.storage.memory import MemoryStorage
from dotenv import load_dotenv
from openai import OpenAI

# Загрузка токенов
load_dotenv()
BOT_TOKEN = os.getenv("BOT_TOKEN")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Настройка логирования
logging.basicConfig(level=logging.INFO)

# Инициализация OpenAI и бота
client = OpenAI(api_key=OPENAI_API_KEY)

bot = Bot(
    token=BOT_TOKEN,
    default=DefaultBotProperties(parse_mode=ParseMode.HTML)
)
dp = Dispatcher(storage=MemoryStorage())

# GPT-функция: анализ аудиофайла
def generate_summary_from_audio(audio_path: str) -> str:
    with open(audio_path, "rb") as audio_file:
        # Сначала Whisper распознаёт
        transcript = client.audio.transcriptions.create(
            model="whisper-1",
            file=audio_file,
            response_format="text",
            language="ru"
        )

    # Затем GPT-4 делает краткий конспект
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

    completion = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "user", "content": prompt}
        ],
        temperature=0.4,
        max_tokens=300
    )

    return completion.choices[0].message.content.strip()


# Команда /start
@dp.message(CommandStart())
async def start_handler(message: Message):
    await message.answer("Привет! Перешли мне голосовое сообщение, и я сделаю его краткий конспект.")

# Обработка пересланного голосового
@dp.message(F.voice, F.forward_from)
async def handle_forwarded_voice(message: Message):
    user_name = message.forward_from.full_name

    with tempfile.TemporaryDirectory() as tmpdir:
        audio_path = os.path.join(tmpdir, "voice.ogg")

        # Скачиваем аудиофайл
        file = await bot.get_file(message.voice.file_id)
        file_bytes = await bot.download_file(file.file_path)
        with open(audio_path, "wb") as f:
            f.write(file_bytes.getvalue())

        # Отправляем аудио в GPT и получаем суть
        summary = generate_summary_from_audio(audio_path)

        # Ответ пользователю
        await message.reply(f"<b>👤 {user_name}</b>\n📌 {summary}")

# Запуск бота
async def main():
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
