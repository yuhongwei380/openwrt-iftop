module("luci.controller.iftop", package.seeall)

function index()
    entry({"admin", "network", "iftop"}, firstchild(), _("流量监控"), 60).dependent = false
    entry({"admin", "network", "iftop", "overview"}, template("iftop/overview"), _("流量概览"), 10)
    entry({"admin", "network", "iftop", "charts"}, template("iftop/charts"), _("流量图表"), 20)
    entry({"admin", "network", "iftop", "data"}, call("get_traffic_data")).leaf = true
    entry({"admin", "network", "iftop", "export"}, call("export_data")).leaf = true
end

function get_traffic_data()
    local db = "/usr/share/iftop-data/traffic.db"
    local start_time = tonumber(luci.http.formvalue("start")) or 0
    local end_time = tonumber(luci.http.formvalue("end")) or os.time()
    local granularity = luci.http.formvalue("granularity") or "hour"
    
    local data = {}
    local conn = sqlite3.open(db)
    
    if granularity == "5min" then
        for row in conn:nrows("SELECT * FROM traffic WHERE timestamp BETWEEN "..start_time.." AND "..end_time.." ORDER BY timestamp") do
            table.insert(data, row)
        end
    else
        local interval = granularity == "hour" and 3600 or 86400
        for row in conn:nrows(string.format([[
            SELECT 
                (timestamp / %d) * %d as time_interval,
                src_ip,
                dst_host,
                SUM(rx_bytes) as rx_bytes,
                SUM(tx_bytes) as tx_bytes,
                SUM(total_bytes) as total_bytes
            FROM traffic
            WHERE timestamp BETWEEN %d AND %d
            GROUP BY time_interval, src_ip, dst_host
            ORDER BY time_interval
        ]], interval, interval, start_time, end_time)) do
            table.insert(data, row)
        end
    end
    
    conn:close()
    luci.http.prepare_content("application/json")
    luci.http.write_json(data)
end

function export_data()
    local db = "/usr/share/iftop-data/traffic.db"
    local start_time = tonumber(luci.http.formvalue("start")) or 0
    local end_time = tonumber(luci.http.formvalue("end")) or os.time()
    
    local conn = sqlite3.open(db)
    local csv = "时间戳,源IP,目标域名,上行流量(B),下行流量(B),总流量(B)\n"
    
    for row in conn:nrows("SELECT * FROM traffic WHERE timestamp BETWEEN "..start_time.." AND "..end_time.." ORDER BY timestamp") do
        csv = csv .. string.format("%d,%s,%s,%d,%d,%d\n", 
            row.timestamp, row.src_ip, row.dst_host, 
            row.rx_bytes, row.tx_bytes, row.total_bytes)
    end
    
    conn:close()
    luci.http.header('Content-Disposition', 'attachment; filename="iftop_export_'..os.date("%Y%m%d")..'.csv"')
    luci.http.prepare_content("text/csv")
    luci.http.write(csv)
end
