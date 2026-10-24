FROM golang:alpine AS builder
RUN apk add --no-cache git && git clone https://github.com/OutlineFoundation/dnstt /app
WORKDIR /app/dnstt-server
RUN go build

FROM alpine:latest
RUN apk add --no-cache dante-server
COPY --from=builder /app/dnstt-server/dnstt-server /usr/local/bin/dnstt-server

# Настройка безопасного внутреннего SOCKS5-прокси
RUN echo -e 'logoutput: stderr\ninternal: 127.0.0.1 port = 1080\nexternal: eth0\nsocksmethod: none\nclientmethod: none\nclient pass {\n    from: 0.0.0.0/0 to: 0.0.0.0/0\n}\nsocks pass {\n    from: 0.0.0.0/0 to: 0.0.0.0/0\n}' > /etc/sockd.conf

# Запуск DNSTT сервера с флагами генерации под синтаксис Outline
CMD dnstt-server -gen-key -privkey-file /tmp/server.key -pubkey-file /tmp/server.pub && \
    echo "=== СКОПИРУЙТЕ ЭТОТ КЛЮЧ ДЛЯ WINDOWS ===" && cat /tmp/server.pub && echo "=========================================" && \
    sockd -D && \
    dnstt-server -udp :$PORT -privkey-file /tmp/server.key t.datatestproject01.tech 127.0.0.1:1080
