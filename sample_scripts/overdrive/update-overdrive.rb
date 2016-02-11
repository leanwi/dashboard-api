# encoding: UTF-8

require "csv"
require "json"
require_relative "config"
require_relative "functions"

usage = "Usage: update-overdrive.rb <filename> <format>"

if ARGV[0]
  file = ARGV[0]
else
  puts usage
  exit
end

if ARGV[1]
  format = ARGV[1]
else
  puts usage
  exit
end

rowCount = 0;
uploadData = {type: 'overdrive'}

# Lookup table to convert Overdrive branch label with library code
library_key = {
  "Indianhead Federated - Altoona" => "al",
  "Indianhead Federated - Amery" => "am",
  "Indianhead Federated - Augusta" => "au",
  "Indianhead Federated - Baldwin" => "ba",
  "Indianhead Federated - Balsam Lake" => "bl",
  "Indianhead Federated - Barron" => "bn",
  "Indianhead Federated - Bloomer" => "bb",
  "Indianhead Federated - Boyceville" => "bo",
  "Indianhead Federated - Bruce" => "br",
  "Indianhead Federated - Cadott" => "ca",
  "Indianhead Federated - Cameron" => "cm",
  "Indianhead Federated - Carleton A. Friday Memorial" => "nr",
  "Indianhead Federated - Centuria" => "ce",
  "Indianhead Federated - Chetek" => "ch",
  "Indianhead Federated - Chippewa Falls" => "cf",
  "Indianhead Federated - Clear Lake" => "cl",
  "Indianhead Federated - Colfax" => "co",
  "Indianhead Federated - Cumberland" => "cu",
  "Indianhead Federated - Dresser" => "dr",
  "Indianhead Federated - Eau Claire (LE Phillips)" => "ec",
  "Indianhead Federated - Elk Mound" => "em",
  "Indianhead Federated - Ellsworth" => "el",
  "Indianhead Federated - Elmwood" => "ew",
  "Indianhead Federated - Fall Creek" => "fc",
  "Indianhead Federated - Frederic" => "fr",
  "Indianhead Federated - Glenwood City" => "gc",
  "Indianhead Federated - Hammond" => "ha",
  "Indianhead Federated - Hudson" => "hu",
  "Indianhead Federated - Ladysmith" => "la",
  "Indianhead Federated - Luck" => "lu",
  "Indianhead Federated - Menomonie" => "me",
  "Indianhead Federated - Milltown" => "mi",
  "Indianhead Federated - Ogema" => "og",
  "Indianhead Federated - Osceola" => "os",
  "Indianhead Federated - Park Falls" => "pf",
  "Indianhead Federated - Pepin" => "pe",
  "Indianhead Federated - Phillips" => "ph",
  "Indianhead Federated - Plum City" => "pl",
  "Indianhead Federated - Prescott" => "pr",
  "Indianhead Federated - Rice Lake" => "rl",
  "Indianhead Federated - River Falls" => "rf",
  "Indianhead Federated - Roberts (Hazel Mackin)" => "ro",
  "Indianhead Federated - Sand Creek" => "sa",
  "Indianhead Federated - Somerset" => "so",
  "Indianhead Federated - Spring Valley" => "sv",
  "Indianhead Federated - St. Croix Falls" => "sc",
  "Indianhead Federated - Stanley" => "st",
  "Indianhead Federated - Turtle Lake" => "tl",
  "Indianhead Federated - Woodville" => "wo"
}

rows = []

CSV.foreach(file, {:headers => :first_row}) do |row|
  trans_date = Date.strptime(row['Checked out'], '%m/%d/%Y')
  adv = (row['Bought by'].match(/Adv/)) ? "Yes" : "No"
  
  rows.push ({
    library_code: library_key[row['Branch']],
    action_date: trans_date.to_s,
    original_id: row['Checkout ID'].gsub('-',''),
    metrics: {
      day: trans_date.wday,
      title: row[0],
      creator: row['Creator'],
      audience: row['Audience/Rating'],
      subject: row['Subject'],
      format: format,
      group: row['Format'],
      publisher: row['Publisher'],
      advantage: adv,
      act150: row['Extra 2']
    }    
  })
  rowCount += 1
end

uploadData["rows"] = rows

req = Net::HTTP::Post.new("#{RbConfig.apiBase}/commands/upload")
req["Content-type"] = "application/json"
serverAuth = fetchServerAuth
req["x-access-token"] = serverAuth["token"]
req["x-key"] = serverAuth["user"]["username"]
req.body = uploadData.to_json

res = Net::HTTP.new(RbConfig.apiHost, RbConfig.apiPort).start {|http| http.request(req)}

uploaded = "%s" % [rowCount.to_s.reverse.scan(/\d{1,3}/).join(",").reverse]
puts "Wireless - #{Time.now.to_s} - Uploaded #{uploaded} actions."
