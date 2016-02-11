require "pg"
require "date"
require "json"
require_relative "config"
require_relative "functions"

recordStats = getMetricType "ils-patron-record"

# Credentials for III Sierra database
conn = PG.connect(host: "127.0.0.1", port: 1032, user: "username", password: "password", sslmode: "require", dbname: "iii")
query = "SELECT rm.id AS original_id, rm.creation_date_gmt AS created_date, pr.home_library_code AS library_code FROM sierra_view.record_metadata AS rm LEFT OUTER JOIN sierra_view.patron_record AS pr ON pr.record_id = rm.id WHERE rm.record_type_code = 'p' AND rm.creation_date_gmt > '#{recordStats['maxDate']}' ORDER BY rm.id"

result = conn.query(query)
uploadData = {type: 'ils-patron-record'}
rows = []

result.each do |row|
  date = DateTime.parse(row["created_date"])
  r = {
    original_id: row["original_id"],
    library_code: row["library_code"],
    action_date: date,
    metrics: {
      day: date.wday,
      hour: date.hour
    }
  }

  rows.push r
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
puts "ILS Patron Records - #{Time.now.to_s} - Uploaded #{uploaded} actions."

conn.close if conn
