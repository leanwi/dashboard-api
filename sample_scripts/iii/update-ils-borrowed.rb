require "pg"
require "json"
require_relative "config"
require_relative "functions"

recordStats = getMetricType "ils-borrowed"

# Credentials for III Sierra database
conn = PG.connect(host: "127.0.0.1", port: 1032, user: "username", password: "password", sslmode: "require", dbname: "iii")
query = "SELECT ct.id AS original_id, ct.transaction_gmt AS trans_date, sg.location_code AS library FROM sierra_view.circ_trans AS ct LEFT OUTER JOIN sierra_view.statistic_group_myuser AS sg ON ct.stat_group_code_num = sg.code WHERE ct.op_code = 'o' AND sg.location_code <> LEFT(ct.item_location_code, 2) AND ct.id > #{recordStats["maxID"]} ORDER BY ct.id;"

result = conn.query(query)
uploadData = {type: 'ils-borrowed'}
rows = []

result.each do |row|
  rows.push({
    original_id: row["original_id"],
    library_code: row["library"],
    action_date: row["trans_date"],
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
puts "ILS Borrowed - #{Time.now.to_s} - Uploaded #{uploaded} actions."

conn.close if conn
