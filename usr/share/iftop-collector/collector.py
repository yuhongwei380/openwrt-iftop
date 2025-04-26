#!/usr/bin/env python3
import os
import re
import sqlite3
from datetime import datetime
from subprocess import Popen, PIPE

DB_PATH = '/usr/share/iftop-data/traffic.db'
IFTOP_CMD = ['iftop', '-i', 'br-lan', '-t', '-s', '5']

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS traffic
                 (timestamp INTEGER, src_ip TEXT, dst_host TEXT, 
                  rx_bytes INTEGER, tx_bytes INTEGER, total_bytes INTEGER)''')
    conn.commit()
    conn.close()

def parse_iftop(output):
    pattern = r'(\S+)\s+=>\s+(\S+).*?(\d+)([KM]?)B\s+(\d+)([KM]?)B\s+(\d+)([KM]?)B'
    matches = re.findall(pattern, output)
    
    records = []
    for match in matches:
        src_ip, dst_host, rx, rx_unit, tx, tx_unit, total, total_unit = match
        rx_bytes = int(rx) * (1024 if rx_unit == 'K' else 1024*1024 if rx_unit == 'M' else 1)
        tx_bytes = int(tx) * (1024 if tx_unit == 'K' else 1024*1024 if tx_unit == 'M' else 1)
        total_bytes = int(total) * (1024 if total_unit == 'K' else 1024*1024 if total_unit == 'M' else 1)
        
        # Resolve IP to hostname if possible
        dst_host = dst_host if not re.match(r'\d+\.\d+\.\d+\.\d+', dst_host) else \
                   resolve_hostname(dst_host) or dst_host
        
        records.append((src_ip, dst_host, rx_bytes, tx_bytes, total_bytes))
    return records

def resolve_hostname(ip):
    try:
        import socket
        return socket.gethostbyaddr(ip)[0]
    except:
        return None

def main():
    init_db()
    process = Popen(IFTOP_CMD, stdout=PIPE, stderr=PIPE)
    output, _ = process.communicate()
    records = parse_iftop(output.decode())
    
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    timestamp = int(datetime.now().timestamp())
    
    for src_ip, dst_host, rx, tx, total in records:
        c.execute("INSERT INTO traffic VALUES (?, ?, ?, ?, ?, ?)",
                 (timestamp, src_ip, dst_host, rx, tx, total))
    
    # Clean up old data (retain 30 days by default)
    c.execute("DELETE FROM traffic WHERE timestamp < ?", 
             (timestamp - 30*24*60*60,))
    
    conn.commit()
    conn.close()

if __name__ == '__main__':
    main()
