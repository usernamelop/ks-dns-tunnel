FROM golang:alpine AS builder
RUN apk add --no-cache git gcc musl-dev
RUN git clone https://github.com/OutlineFoundation/dnstt /app
WORKDIR /app/dnstt-server
RUN go build

FROM alpine:latest
RUN apk add --no-cache ca-certificates python3
COPY --from=builder /app/dnstt-server/dnstt-server /usr/local/bin/dnstt-server

WORKDIR /app

# Скрипт запуска: генерирует ключи, выводит публичный ключ в логи, 
# запускает веб-заглушку для Render на $PORT и сам DNSTT-сервер в режиме DoH на порту 8080
RUN echo -e '#!/bin/sh\n\
dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub\n\
echo "========================================="\n\
echo "=== СКОПИРУЙТЕ ЭТОТ КЛЮЧ ДЛЯ КЛИЕНТА ==="\n\
cat server.pub\n\
echo ""\n\
echo "========================================="\n\
# Запускаем простейший веб-сервер на Python, чтобы Render проходил Health Check\n\
python3 -m http.server $PORT &\n\
# Запускаем DNSTT в режиме DoH на порту 8080 (его мы пробросим в Render)\n\
exec dnstt-server -doh :8080 -privkey-file server.key t.datatestproject01.tech 127.0.0.1:1080\n\
' > entrypoint.sh && chmod +x entrypoint.sh

EXPOSE 8080

CMD ["./entrypoint.sh"]
