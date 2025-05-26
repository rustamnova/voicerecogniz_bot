import asyncio
import logging
import os
import tempfile

from aiogram import F
from aiogram.enums import ParseMode
from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.types import Message
from aiogram.filters import CommandStart
from aiogram.fsm.storage.memory import MemoryStorage
from dotenv import load_dotenv
from pydub import AudioSegment
import openai
import torch
import whisper

# Загрузка токенов из .env
load_dotenv()
BOT_TOKEN = os.getenv("BOT_TOKEN")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

openai.api_key = OPENAI_API_KEY

# Логирование
logging.basicConfig(level=logging.INFO)

# Инициализация бота и whisper
bot = Bot(
    token=BOT_TOKEN,
    default=DefaultBotProperties(parse_mode=ParseMode.HTML)
)

dp = Dispatcher(storage=MemoryStorage())
model = whisper.load_model("base" if not torch.cuda.is_available() else "medium")


# Конвертация .oga в .wav
def convert_to_wav(oga_path: str, wav_path: str):
    audio = AudioSegment.from_file(oga_path)
    audio.export(wav_path, format="wav")


# Распознавание речи
def speech_to_text(wav_path: str) -> str:
    result = model.transcribe(wav_path, language="ru")
    return result.get("text", "").strip()


# Генерация краткого конспекта
def generate_summary(text: str) -> str:
    prompt = (
        "Проанализируй следующий текст голосового сообщения и сделай краткий деловой конспект. "
        "Выдели суть и не повторяй лишние детали.\n\n"
        f"Текст сообщения:\n{text}"
    )
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.4,
        max_tokens=200,
    )
    return response.choices[0].message.content.strip()


# Обработка команды /start
@dp.message(CommandStart())
async def start_handler(message: Message):
    await message.answer("Привет! Перешли мне голосовое сообщение, и я сделаю из него краткий конспект.")


# Обработка пересланного голосового сообщения
@dp.message(F.voice, F.forward_from)
async def handle_forwarded_voice(message: Message):
    user_name = message.forward_from.full_name

    with tempfile.TemporaryDirectory() as tmpdir:
        oga_path = os.path.join(tmpdir, "voice.oga")
        wav_path = os.path.join(tmpdir, "voice.wav")

        # Скачиваем голосовое сообщение
        file = await bot.get_file(message.voice.file_id)
        with open(oga_path, "wb") as f:
            file_bytes = await bot.download_file(file.file_path)
            f.write(file_bytes.getvalue())

        # Конвертируем и распознаём
        convert_to_wav(oga_path, wav_path)
        transcribed_text = speech_to_text(wav_path)

        # Анализируем с помощью GPT
        summary = generate_summary(transcribed_text)

        # Отправляем результат
        await message.reply(f"<b>👤 {user_name}</b>\n📌 {summary}")


# Запуск бота
async def main():
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
