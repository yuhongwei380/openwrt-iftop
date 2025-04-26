#!/bin/bash
DB="/etc/iftop/traffic.db"
mkdir -p /etc/iftop

# 初始化数据库
sqlite3 "$DB" <<EOF
CREATE TABLE IF NOT EXISTS traffic_log (
  timestamp INTEGER,
  src_ip TEXT,
  dst_ip TEXT,
  domain TEXT,
  bytes_sent INTEGER,
  bytes_recv INTEGER
);
EOF

while true; do
  TS=$(date +%s)
  iftop -t -s 60 -n -N -P | awk -v ts=$TS '
    /^ / && $1 ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {
      gsub(/[^0-9\.]/, "", $1); gsub(/[^0-9\.]/, "", $3);
      src=$1; dst=$3;
      sent=$5; recv=$7;
      if (sent ~ /K/) sent_val=sent*1024;
      else if (sent ~ /M/) sent_val=sent*1024*1024;
      else sent_val=sent;
      if (recv ~ /K/) recv_val=recv*1024;
      else if (recv ~ /M/) recv_val=recv*1024*1024;
      else recv_val=recv;
      printf("INSERT INTO traffic_log (timestamp, src_ip, dst_ip, domain, bytes_sent, bytes_recv) VALUES (%d, \"%s\", \"%s\", \"-\", %d, %d);\n", ts, src, dst, sent_val, recv_val)
    }
  ' | sqlite3 "$DB"
done
