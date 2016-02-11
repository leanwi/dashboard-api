require "tiny_tds"
require "mysql2"
require "json"
require_relative "config"
require_relative "functions"

recordStats = getMetricType "pharos"
# Use credentials to connect to the Pharos MSSQL database
conn = TinyTds::Client.new(username: 'username', password: 'password', host: '127.0.0.1', port: 49240, database: 'pharos')

# Lookup table to convert Pharos branch to library code
library_lookup = {
  'Altoona' => 'al',
  'Amery' => 'am',
  'Balsam Lake' => 'bl',
  'Barron' => 'bn',
  'Bloomer' => 'bb',
  'Cadott' => 'ca',
  'Chippewa Falls' => 'cf',
  'Cumberland' => 'cu',
  'Ellsworth' => 'el',
  'Frederic' => 'fr',
  'Hudson' => 'hu',
  'Ladysmith' => 'la',
  'Luck' => 'lu',
  'Menomonie' => 'me',
  'Milltown' => 'mi',
  'New Richmond' => 'nr',
  'Phillips' => 'ph',
  'Prescott' => 'pr',
  'Rice Lake' => 'rl',
  'River Falls' => 'rf',
  'Roberts' => 'ro',
  'Spring Valley' => 'sv',
  'St. Croix Falls' => 'sc',
  'IFLSTest' => 'if'
}

query = "SELECT [Transaction ID] AS original_id, [Date/Time] AS trans_date, [Branch] AS library_code, [Computer Group] AS computer_group FROM rpt_computer_transactions WHERE [Date/Time] > '01-01-2014' AND [Transaction ID] > '#{recordStats['maxID']}' ORDER BY [Transaction ID];"

uploadData = {type: 'pharos'}
rows = []

result = conn.execute(query)

result.each do |row|
  rows.push({
    original_id: row["original_id"],
    library_code: library_lookup[row["library_code"]],
    action_date: row["trans_date"],
    metrics: {
      group: row["computer_group"],
      day: row["trans_date"].wday,
      hour: row["trans_date"].hour
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
puts "Pharos - #{Time.now.to_s} - Uploaded #{uploaded} actions."

conn.close if conn

