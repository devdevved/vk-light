#!/data/data/com.termux/files/usr/bin/bash
# Простой скрипт запуска

echo "🤖 Запуск VK Tunnel системы"
echo "📁 Директория: $(pwd)"

# Генерируем новый ключ
echo "🔑 Генерируем новый AES ключ..."
NEW_KEY=$(python -c "import secrets; print(secrets.token_hex(16))")
echo "Новый ключ: $NEW_KEY"

# Обновляем конфиг
sed -i "s/\"aes_key_hex\": *\"[^\"]*\"/\"aes_key_hex\": \"$NEW_KEY\"/" config_light.py
echo "✅ Конфиг обновлен"

# Запускаем сервер в фоне
echo "🔄 Запускаем server.py..."
python server.py &
SERVER_PID=$!
sleep 3

# Запускаем vk-tunnel в фоне и получаем URL
echo "🌐 Запускаем vk-tunnel..."
vk-tunnel --insecure=1 --http-protocol=http --ws-protocol=ws --ws-origin=0 --host=127.0.0.1 --port=8080 > tunnel.log 2>&1 &
TUNNEL_PID=$!
sleep 5

# Извлекаем URL из лога
WSS_URL=$(grep -o "wss://[^ ]*" tunnel.log | head -1)
if [ -z "$WSS_URL" ]; then
    echo "❌ Не удалось получить WSS URL"
    echo "Лог vk-tunnel:"
    cat tunnel.log
    kill $SERVER_PID $TUNNEL_PID
    exit 1
fi

echo "🎯 Получен URL: $WSS_URL"

# Запускаем клиента
echo "🚀 Запускаем client.py..."
python client.py --wss "$WSS_URL" &
CLIENT_PID=$!
sleep 3

echo ""
echo "============================================================="
echo "🎉 СИСТЕМА ЗАПУЩЕНА!"
echo "📡 SOCKS5: 127.0.0.1:1080"
echo "⏹️  Для остановки нажмите Ctrl+C"
echo "============================================================="

# Ждем Ctrl+C
wait

# Останавливаем процессы
kill $SERVER_PID $TUNNEL_PID $CLIENT_PID 2>/dev/null
echo "✅ Процессы остановлены"