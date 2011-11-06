require 'json'
require 'redis'

pwd = File.dirname(__FILE__)
json = "shared-items.json"
# initialize redis connection
redis = Redis.new
redis.select 1

google_string = String.new

google_snippet = File.readlines(pwd + "/" + json)
google_snippet.each { |lines| google_string = google_string.chomp + lines.chomp }
google_json = JSON.parse(google_string)
item_array = google_json.values_at("items")[0]
item_array.each do |item|
  item_id = item.values_at("id")[0]
  redis.set item_id, item.to_json
end
redis_test = redis.get "tag:google.com,2005:reader/item/0e5c79d3a27b42d4"
puts JSON.parse(redis_test).values_at("id")
