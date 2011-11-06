require 'json'

redis = Redis.new
redis.select 1

before do 
  # Strip the last / from the path
  request.env['PATH_INFO'].gsub!(/\/$/, '')
end

get '/' do
  @object = get_article((redis.keys("*reader/item/*").sort { |x,y| y <=> x }.take(1)[0]))
  @item = @object.values_at("item")[0]
  @title = @object.values_at("title")[0]
  @url = @object.values_at("url")[0]
  @id = @object.values_at("id")[0]
  haml :index    
end

get '/random' do
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
  @object = JSON.parse(redis.get(redis.keys("*tag:google.com,2005:reader/item/#{params[:key]}")[0]))
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

helpers do
  def get_article(key)
    redis = Redis.new
    redis.select 1
    @object = JSON.parse(redis.get("#{key}"))
    if @object.has_key?("content")
      @item = @object.values_at("content")[0].values_at("content")[0]
    elsif @object.has_key?("summary")
      @item = @object.values_at("summary")[0].values_at("content")[0]
    end  
    @title = @object.values_at("title")[0]
    @url = @object.values_at("alternate")[0][0].values_at("href")[0]
    @id = @object.values_at("id")[0].scan(/[a-zA-Z0-9]+$/)[0]
    return { "item" => @item, "title" => @title, "url" => @url, "id" => @id}
  end

end
