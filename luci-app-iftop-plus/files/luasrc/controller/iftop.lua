module("luci.controller.iftop", package.seeall)

function index()
  entry({"admin", "network", "iftop"}, firstchild(), _("流量监控"), 90)
  entry({"admin", "network", "iftop", "status"}, template("iftop/status"), _("实时数据"), 1)
  entry({"admin", "network", "iftop", "graph"}, template("iftop/graph"), _("图表统计"), 2)
  entry({"admin", "network", "iftop", "api", "history"}, call("action_history")).leaf = true
end

function action_history()
  local json = require "luci.jsonc"
  local interval = tonumber(luci.http.formvalue("interval")) or 3600
  local sql = string.format([[
    SELECT (timestamp / %d) * %d AS slot, SUM(bytes_sent + bytes_recv)
    FROM traffic_log
    GROUP BY slot ORDER BY slot ASC;
  ]], interval, interval)
  local result = {}
  local cmd = string.format("sqlite3 -separator ',' /etc/iftop/traffic.db \"%s\"", sql)
  local f = io.popen(cmd)
  for line in f:lines() do
    local ts, total = line:match("([^,]+),([^,]+)")
    table.insert(result, { ts = tonumber(ts), total = tonumber(total) })
  end
  f:close()
  luci.http.prepare_content("application/json")
  luci.http.write(json.stringify(result))
end
