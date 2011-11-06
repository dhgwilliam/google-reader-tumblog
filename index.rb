require 'json'

redis = Redis.new

before do 
  # Strip the last / from the path
  request.env['PATH_INFO'].gsub!(/\/$/, '')
end

get '/' do
  @object = JSON.parse(redis.get(redis.randomkey))
  @item = @object.values_at("content")[0].values_at("content")[0]
  @title = @object.values_at("title")[0]
  @url = @object.values_at("alternate")[0][0].values_at("href")[0]
  haml :index    
end

get "/css/:stylesheet.css" do
  content_type "text/css", :charset => "UTF-8"
  sass :"css/#{params[:stylesheet]}"
end 
