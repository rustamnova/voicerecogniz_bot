#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
mkdir -p logs
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ▶️ Запуск voicerecogniz_bot..." >> logs/worklog.txt
python voicerecogniz_bot.py 2>> logs/errors.txt
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏹ voicerecogniz_bot остановлен (exit $?)" >> logs/worklog.txt
