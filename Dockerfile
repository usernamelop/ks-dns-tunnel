FROM golang:alpine AS builder
RUN apk add --no-cache git && git clone https://github.com/OutlineFoundation/dnstt /app
WORKDIR /app/dnstt-server
RUN go build

FROM alpine:latest
RUN apk add --no-cache dante-server
COPY --from=builder /app/dnstt-server/dnstt-server /usr/local/bin/dnstt-server

# Настройка безопасного внутреннего SOCKS5-прокси
RUN echo -e 'logoutput: stderr\ninternal: 127.0.0.1 port = 1080\nexternal: eth0\nsocksmethod: none\nclientmethod: none\nclient pass {\n    from: 0.0.0.0/0 to: 0.0.0.0/0\n}\nsocks pass {\n    from: 0.0.0.0/0 to: 0.0.0.0/0\n}' > /etc/sockd.conf

# Запуск DNSTT сервера на порту, который автоматически выдаст Render ($PORT)
CMD dnstt-server -gen-key -pubkey /tmp/server.pub -privkey /tmp/server.priv && \
    echo "=== СКОПИРУЙТЕ ЭТОТ КЛЮЧ ДЛЯ WINDOWS ===" && cat /tmp/server.pub && echo "=========================================" && \
    sockd -D && \
    dnstt-server -tcp :$PORT -privkey /tmp/server.priv t.datatestproject01.tech 127.0.0.1:1080
