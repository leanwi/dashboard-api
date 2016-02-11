# encoding: UTF-8

require "csv"
require "json"
require_relative "config"
require_relative "functions"

usage = "Usage: update-freading.rb <filename> <date YYYY-MM-DD>"

if ARGV[0]
  file = ARGV[0]
else
  puts usage
  exit
end

if ARGV[1]
  date = ARGV[1]
else
  puts usage
  exit
end

rowCount = 0;
uploadData = {type: 'freading'}

# Lookup table to convert barcode patterns in Freading Stats download to library codes
library_key = {
  "28390" => "al",
  "20268" => "am",
  "20286" => "au",
  "20684" => "ba",
  "20340" => "bl",
  "20537" => "bn",
  "26430" => "bo",
  "20868" => "br",
  "22890" => "ca",
  "20924" => "ch",
  "20458" => "cm",
  "20246" => "nr",
  "20646" => "ce",
  "23394" => "cf",
  "20658" => "sa",
  "20263" => "cl",
  "20962" => "co",
  "20644" => "st",
  "20269" => "dp",
  "20755" => "dr",
  "20273" => "el",
  "20639" => "ew",
  "20877" => "fc",
  "20327" => "fr",
  "20568" => "bb",
  "20265" => "gc",
  "20796" => "ha",
  "20749" => "ro",
  "20386" => "hu",
  "2000" => "ec",
  "24720" => "lu",
  "20235" => "me",
  "20825" => "mi",
  "20767" => "og",
  "22940" => "os",
  "24210" => "pf",
  "20442" => "pe",
  "20339" => "ph",
  "20647" => "pl",
  "28262" => "pr",
  "20234" => "rl",
  "29425" => "rf",
  "20532" => "la",
  "20247" => "so",
  "20778" => "sv",
  "20483" => "sc",
  "20822" => "cu",
  "20986" => "tl",
  "20698" => "wo",
  "30340" => "bl",
  "20289" => "ca",
  "64941034" => "cm",
  "32841591" => "nr",
  "22650" => "gc",
  "27620" => "pf",
  "27630" => "pf"
}

rows = []

CSV.foreach(file, {:headers => :first_row}) do |row|
  trans_date = Date.strptime(date)
  if(row['ID'].slice(0,4) === '2000')
    code = "ec"
  else 
    code = library_key[row['ID'].slice(0,5)]
  end
  
  p = {
    library_code: code,
    action_date: trans_date.to_s,
    original_id: 0,
  }
  
  row['times'].to_i.times do |t|
    rowCount += 1
    rows.push(p)
  end  
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
