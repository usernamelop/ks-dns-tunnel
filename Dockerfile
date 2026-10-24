FROM golang:alpine AS builder
RUN apk add --no-cache git gcc musl-dev
RUN git clone https://github.com/OutlineFoundation/dnstt /app
WORKDIR /app/dnstt-server
RUN go build

FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/dnstt-server/dnstt-server /usr/local/bin/dnstt-server

WORKDIR /app

RUN echo -e '#!/bin/sh\n\
dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub\n\
echo "========================================="\n\
echo "=== СКОПИРУЙТЕ ЭТОТ КЛЮЧ ДЛЯ КЛИЕНТА ==="\n\
cat server.pub\n\
echo ""\n\
echo "========================================="\n\
# В оригинальной версии флаг -doh работает отлично\n\
exec dnstt-server -doh :10000 -privkey-file server.key t.datatestproject01.tech 127.0.0.1:1080\n\
' > entrypoint.sh && chmod +x entrypoint.sh

EXPOSE 10000

CMD ["./entrypoint.sh"]
