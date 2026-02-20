#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
mkdir -p logs
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [start.sh] Запуск voicerecogniz_bot..." >> logs/install.txt
exec python voicerecogniz_bot.py 2>> logs/errors.txt
