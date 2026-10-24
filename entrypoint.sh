#!/bin/sh
sed -i "s/10000/$PORT/g" /etc/xray/config.json
exec xray -config /etc/xray/config.json
