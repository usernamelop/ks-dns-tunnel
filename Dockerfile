FROM golang:alpine AS builder
RUN apk add --no-cache git && git clone https://github.com/OutlineFoundation/dnstt /app
WORKDIR /app/dnstt-server
RUN go build

# Создаем веб-сервер заглушку на Go
RUN echo -e 'package main\nimport (\n\t"fmt"\n\t"net/http"\n\t"os"\n)\nfunc main() {\n\tport := os.Getenv("PORT")\n\thttp.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {\n\t\tfmt.Fprintf(w, "OK")\n\t})\n\thttp.ListenAndServe(":"+port, nil)\n}' > /app/web_server.go
RUN cd /app && go build -o /app/web_server web_server.go

FROM alpine:latest
# Добавляем socat для перевода TCP в UDP внутри контейнера
RUN apk add --no-cache dante-server socat
COPY --from=builder /app/dnstt-server/dnstt-server /usr/local/bin/dnstt-server
COPY --from=builder /app/web_server /usr/local/bin/web_server

# Настройка безопасного внутреннего SOCKS5-прокси
RUN echo -e 'logoutput: stderr\ninternal: 127.0.0.1 port = 1080\nexternal: eth0\nsocksmethod: none\nclientmethod: none\nclient pass {\n    from: 0.0.0.0/0 to: 0.0.0.0/0\n}\nsocks pass {\n    from: 0.0.0.0/0 to: 0.0.0.0/0\n}' > /etc/sockd.conf

# Запуск заглушки на порту 9090 и запуск DNSTT с прямым проксированием на порт хостинга $PORT
CMD web_server & \
    dnstt-server -gen-key -privkey-file /tmp/server.key -pubkey-file /tmp/server.pub && \
    echo "=== СКОПИРУЙТЕ ЭТОТ КЛЮЧ ДЛЯ WINDOWS ===" && cat /tmp/server.pub && echo "=========================================" && \
    dnstt-server -udp :$PORT -privkey-file /tmp/server.key t.datatestproject01.tech 127.0.0.1:1080
