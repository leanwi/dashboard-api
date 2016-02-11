require "mysql2"
require "json"
require_relative "config"
require_relative "functions"

recordStats = getMetricType "wireless"
maxid = recordStats['maxID']

# Credentials for MySQL database holding wireless sessions
con1 = Mysql2::Client.new(host: "127.0.0.1", username: "username", password: "password", database: "wireless")
s1 = "SELECT id, session_date, library, ssid, mac, sn, ap FROM sessions WHERE id > #{maxid} ORDER BY id;"
result = con1.query(s1)
uploadData = {type: 'wireless'}
rows = []

result.each do |row|
  rows.push({
    original_id: row["id"],
    library_code: row["library"],
    action_date: row["session_date"],
    metrics: {
      mac: row["mac"],
      sn: row["sn"],
      ap: row["ap"],
      ssid: row["ssid"],
      day: row["session_date"].wday,
      hour: row["session_date"].hour
    }
  })
end

uploadData['rows'] = rows

req = Net::HTTP::Post.new("#{RbConfig.apiBase}/commands/upload")
req["Content-type"] = "application/json"
serverAuth = fetchServerAuth
req["x-access-token"] = serverAuth["token"]
req["x-key"] = serverAuth["user"]["username"]
req.body = uploadData.to_json

res = Net::HTTP.new(RbConfig.apiHost, RbConfig.apiPort).start {|http| http.request(req)}

uploaded = "%s" % [result.count.to_s.reverse.scan(/\d{1,3}/).join(",").reverse]
puts "Wireless - #{Time.now.to_s} - Uploaded #{uploaded} actions."

con1.close
