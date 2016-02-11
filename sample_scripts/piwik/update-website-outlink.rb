require "mysql2"
require "json"
require_relative "config"
require_relative "functions"

recordStats = getMetricType "website-outlink"
maxid = recordStats['maxID']

# Lookup table to convert Piwik Site name to library code
library_lookup = {
  'Altoona' => 'al',
  'Amery' => 'am',
  'Augusta' => 'au',
  'Baldwin' => 'ba',
  'Balsam Lake' => 'bl',
  'Barron' => 'bn',
  'Bloomer' => 'bb',
  'Boyceville' => 'bo',
  'Bruce' => 'br',
  'Cadott' => 'ca',
  'Cameron' => 'cm',
  'Centuria' => 'ce',
  'Chetek' => 'ch',
  'Chippewa Falls' => 'cf',
  'Clear Lake' => 'cl',
  'Colfax' => 'co',
  'Cornell' => 'cn',
  'Cumberland' => 'cu',
  'Deer Park' => 'dp',
  'Dresser' => 'dr',
  'Ellsworth' => 'el',
  'Elmwood' => 'ew',
  'Fairchild' => 'fa',
  'Fall Creek' => 'fc',
  'Frederic' => 'fr',
  'Glenwood City' => 'gc',
  'Hammond' => 'ha',
  'Hawkins' => 'hk',
  'Hudson' => 'hu',
  'Ladysmith' => 'la',
  'Luck' => 'lu',
  'Milltown' => 'mi',
  'New Richmond' => 'nr',
  'Ogema' => 'og',
  'Osceola' => 'os',
  'Park Falls' => 'pf',
  'Pepin' => 'pe',
  'Phillips' => 'ph',
  'Plum City' => 'pl',
  'Prescott' => 'pr',
  'Roberts' => 'ro',
  'Sand Creek' => 'sa',
  'Somerset' => 'so',
  'Spring Valley' => 'sv',
  'St. Croix Falls' => 'sc',
  'Stanley' => 'st',
  'Turtle Lake' => 'tl',
  'Woodville' => 'wo'
}

# Credentials to connect to Piwik Mysql database
con1 = Mysql2::Client.new(host: "127.0.0.1", username: "username", password: "password", database: "piwik", database_timezone: :utc, application_timezone: :local)
s1 = "SELECT idlink_va, site.name AS library, lo.name AS pageurl, action.server_time FROM log_link_visit_action AS action JOIN site AS site ON site.idsite = action.idsite JOIN log_visit AS visit ON visit.idvisit = action.idvisit JOIN log_action AS lo ON lo.idaction = action.idaction_url WHERE idlink_va > #{maxid} AND lo.type = 2 AND site.idsite NOT IN (1,3) ORDER BY idlink_va"
result = con1.query(s1)
uploadData = {type: 'website-outlink'}
rows = []

result.each do |row|
  rows.push({
    original_id: row["idlink_va"],
    library_code: "#{library_lookup[row["library"]]}",
    action_date: row["server_time"],
    metrics: {
      page_url: row["pageurl"],
      day: row["server_time"].wday,
      hour: row["server_time"].hour
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
puts "Website Outlink - #{Time.now.to_s} - Uploaded #{uploaded} actions."

con1.close
