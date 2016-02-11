require 'net/http'
require 'json'
require_relative 'config'

def fetchServerAuth
  data = {username: RbConfig.apiUser, password: RbConfig.apiPass}.to_json
  
  req = Net::HTTP::Post.new("/api/v1/login")
  req["Content-type"] = "application/json"
  req.body = data

  res = Net::HTTP.new(RbConfig.apiHost, RbConfig.apiPort).start {|http| http.request(req)}
  JSON.parse(res.body)
end


def getMetricTypes
  url = "#{RbConfig.apiBase}/status/action-metric-types"

  req = Net::HTTP::Get.new(url)
  req["Content-type"] = "application/json"
  serverAuth = fetchServerAuth
  req["x-access-token"] = serverAuth["token"]
  req["x-key"] = serverAuth["user"]["username"]

  res = Net::HTTP.new(RbConfig.apiHost, RbConfig.apiPort).start {|http| http.request(req)}
  JSON.parse(res.body)
end

def getMetricType name
  url = "#{RbConfig.apiBase}/status/action-metric-types/#{name}"

  req = Net::HTTP::Get.new(url)
  req["Content-type"] = "application/json"
  serverAuth = fetchServerAuth
  req["x-access-token"] = serverAuth["token"]
  req["x-key"] = serverAuth["user"]["username"]

  res = Net::HTTP.new(RbConfig.apiHost, RbConfig.apiPort).start {|http| http.request(req)}

  stats = JSON.parse(res.body)
  stats["maxID"] = 0 if !stats["maxID"]
  stats["maxTimestamp"] = 0 if !stats["maxDate"]
  return stats
end
