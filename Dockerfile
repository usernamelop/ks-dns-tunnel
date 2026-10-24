FROM golang:alpine AS builder
RUN apk add --no-cache git && git clone https://github.com/OutlineFoundation/dnstt /app
WORKDIR /app/dnstt-server
RUN go build

# Создаем комбо-сервер: веб-заглушка на $PORT + HTTP-прокси на порту 1080
RUN echo -e 'package main\nimport (\n\t"fmt"\n\t"net/http"\n\t"net/http/httputil"\n\t"os"\n)\nfunc main() {\n\tgo func() {\n\t\tproxy := &httputil.ReverseProxy{Director: func(req *http.Request) {}}\n\t\thttp.ListenAndServe(":1080", proxy)\n\t}()\n\tport := os.Getenv("PORT")\n\thttp.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {\n\t\tfmt.Fprintf(w, "OK")\n\t})\n\thttp.ListenAndServe(":"+port, nil)\n}' > /app/web_server.go
RUN cd /app && go build -o /app/web_server web_server.go

FROM alpine:latest
COPY --from=builder /app/dnstt-server/dnstt-server /usr/local/bin/dnstt-server
COPY --from=builder /app/web_server /usr/local/bin/web_server

# Запуск комбо-сервера и привязка DNSTT к внутреннему HTTP-прокси
CMD web_server & \
    dnstt-server -gen-key -privkey-file /tmp/server.key -pubkey-file /tmp/server.pub && \
    echo "=== СКОПИРУЙТЕ ЭТОТ КЛЮЧ ДЛЯ WINDOWS ===" && cat /tmp/server.pub && echo "=========================================" && \
    dnstt-server -udp :$PORT -privkey-file /tmp/server.key t.datatestproject01.tech 127.0.0.1:1080

