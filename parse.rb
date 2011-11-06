require 'json'
require 'redis'

pwd = File.dirname(__FILE__)
# initialize redis connection
redis = Redis.new

google_string = String.new

google_snippet = File.readlines(pwd + "/reader.json")
google_snippet.each { |lines| google_string = google_string.chomp + lines.chomp }
google_json = JSON.parse(google_string)
item_array = google_json[google_json.keys[0]]
item_array.each do |item|
  item_id = item.values_at("object")[0].values_at("id")
  redis.set item_id[0], item.to_json
end
redis_test = redis.get "tag:google.com,2005:reader/item/b4b4d935e2ce43a6"
puts JSON.parse(redis_test)
