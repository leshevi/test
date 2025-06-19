#!/bin/bash
# Включаем отладку
set -x

# Переменные
LOCK_FILE="./lock/monitor_test.lock"
PRESENT_FILE="./monitoring_test.state"
LOG_FILE="./monitoring.log"


# Создаем lock-файл если не существует
touch "$LOCK_FILE"

# Блокировка для предотвращения параллельного выполнения
exec 8>"$LOCK_FILE"
flock -n 8 || exit 1

# Проверка наличия процесса test
if pgrep -x "mon.sh" >/dev/null; then
    CURRENT_STATE=1
else
    CURRENT_STATE=0
fi

# Чтение предыдущего состояния
PREVIOUS_STATE=0
[[ -f "$PRESENT_FILE" ]] && PREVIOUS_STATE=$(cat "$PRESENT_FILE")

# Логирование перезапуска процесса
if [[ "$CURRENT_STATE" -eq 1 && "$PREVIOUS_STATE" -eq 0 ]]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S"): Процесс test был перезапущен" >> "$LOG_FILE"
fi

#Логирование запущенного процесса
if [[ "$CURRENT_STATE" -eq 1 && "$PREVIOUS_STATE" -eq 1 ]]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S"): Процесс test продолжает работать" >> "$LOG_FILE"
fi

# Обновление состояния
echo "$CURRENT_STATE" > "$PRESENT_FILE"

# Проверка доступности сервера для запущенного процесса
if [[ "$CURRENT_STATE" -eq 1 ]]; then
    if ! curl -sSf --connect-timeout 10 -o /dev/null "https://test.com/monitoring/test/api" 2>/dev/null; then
        echo "$(date "+%Y-%m-%d %H:%M:%S"): Сервер мониторинга недоступен" >> "$LOG_FILE"
    fi
fi

# Снятие блокировки
flock -u 9
exit 0

# Отключаем отладку
set +x  
