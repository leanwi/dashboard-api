require "pg"
require "date"
require "json"
require_relative "config"
require_relative "functions"

recordStats = getMetricType "ils-renewal"

# Credentials for III Sierra database
conn = PG.connect(host: "127.0.0.1", port: 1032, user: "username", password: "password", sslmode: "require", dbname: "iii")
query = "SELECT ct.id AS original_id, ct.transaction_gmt AS trans_date, sg.location_code AS library, ct.stat_group_code_num as stat_group, sg.name AS stat_group_name, LEFT(ct.item_location_code, 2) AS owning_location, ct.item_location_code AS loc_code, mpm.name AS format, ct.itype_code_num AS itype, ct.icode2 AS icode2, ct.pcode4 AS act150, udp4m.name AS act150_loc, ct.patron_home_library_code AS home_library, EXTRACT(YEAR FROM AGE(pr.birth_date_gmt)) AS age, ct.ptype_code AS ptype FROM sierra_view.circ_trans AS ct LEFT OUTER JOIN sierra_view.statistic_group_myuser AS sg ON ct.stat_group_code_num = sg.code LEFT OUTER JOIN sierra_view.bib_record_property AS brp ON ct.bib_record_id = brp.bib_record_id LEFT OUTER JOIN sierra_view.material_property_myuser AS mpm ON brp.material_code = mpm.code LEFT OUTER JOIN sierra_view.user_defined_pcode4_myuser AS udp4m ON udp4m.code = ct.pcode4::text LEFT OUTER JOIN sierra_view.patron_record AS pr ON pr.id = ct.patron_record_id WHERE ct.op_code = 'r' AND ct.id > #{recordStats["maxID"]} ORDER BY ct.id;"

result = conn.query(query)
uploadData = {type: 'ils-renewal'}
rows = []

result.each do |row|
  date = DateTime.parse(row["trans_date"])
  rows.push({
    original_id: row["original_id"],
    library_code: row["library"],
    action_date: date,
    metrics: {
      day: date.wday,
      hour: date.hour,
      statgroup: row["stat_group"],
      statgroupname: row["stat_group_name"],
      owninglocation: row["owning_location"],
      locationcode: row["loc_code"],
      format: row["format"],
      itype: row["itype"],
      act150: row["act150"],
      act150_loc: row["act150_loc"],
      homelibrary: row["home_library"].strip,
      age: row["age"],
      icode2: row["icode2"],
      ptype: row["ptype"]
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
puts "ILS Renewals - #{Time.now.to_s} - Uploaded #{uploaded} actions."

conn.close if conn
