require 'json'

redis = Redis.new
redis.select 1

before do 
  # Strip the last / from the path
  request.env['PATH_INFO'].gsub!(/\/$/, '')
end

get '/' do
  @object = JSON.parse(redis.get(redis.randomkey))
  if @object.has_key?("content")
    @item = @object.values_at("content")[0].values_at("content")[0]
  elsif @object.has_key?("summary")
    @item = @object.values_at("summary")[0].values_at("content")[0]
  end  
  @title = @object.values_at("title")[0]
  @url = @object.values_at("alternate")[0][0].values_at("href")[0]
  @id = @object.values_at("id")[0].scan(/[a-zA-Z0-9]+$/)[0]
  haml :index    
end

get '/:key' do
  @object = JSON.parse(redis.get("tag:google.com,2005:reader/item/#{params[:key]}"))
  if @object.has_key?("content")
    @item = @object.values_at("content")[0].values_at("content")[0]
  elsif @object.has_key?("summary")
    @item = @object.values_at("summary")[0].values_at("content")[0]
  end  
  @title = @object.values_at("title")[0]
  @url = @object.values_at("alternate")[0][0].values_at("href")[0]
  @id = @object.values_at("id")[0].scan(/[a-zA-Z0-9]+$/)[0]
  haml :index    
end

get "/css/:stylesheet.css" do
  content_type "text/css", :charset => "UTF-8"
  sass :"css/#{params[:stylesheet]}"
end 
