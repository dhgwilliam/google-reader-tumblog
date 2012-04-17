require 'json'
require 'koala'
require './config'

OAUTH = Koala::Facebook::OAuth.new(API_KEY, APP_SECRET, CALLBACK_URL)

enable :sessions

redis = Redis.new
redis.select 1

before do 
  # Strip the last / from the path
  request.env['PATH_INFO'].gsub!(/\/$/, '')
end

get '/' do
  @start = 0
  @finish = @start + 9 
  @article_array = redis.keys("*reader/item/*").sort { |x,y| y <=> x }.slice(0..9)
  @oauth_url = OAUTH.url_for_oauth_code(:permissions => "publish_stream")
  unless session["access_token"].nil?
    GRAPH = Koala::Facebook::API.new(session["access_token"])
    @uid = GRAPH.get_object("me")["first_name"]
  end
  haml :list
end

get '/login' do
  if params[:code]
     session["code"] = params[:code]
     session["access_token"] = OAUTH.get_access_token(session["code"])
  end
  redirect to('/')
end

get '/logout' do
  session["access_token"] = nil
  redirect to('/')
end

get '/post' do
  
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
  haml :single    
end

get '/popular' do
  @article_array = redis.zrevrange("zlikes", 0, -1)
  @article_array.each do |shortkey|
    @article_array[@article_array.index(shortkey)] = redis.keys("*#{shortkey}")[0]
  end
  haml :popular
end

get '/list/:counter' do
  @start = params[:counter].to_i
  @finish = @start + 9 
  @article_array = redis.keys("*reader/item/*").sort { |x,y| y <=> x }
  if @finish > @article_array.count
    @finish = @article_array.count
  end
  @article_array = @article_array.slice(@start..@finish)
  haml :list
end

get '/like/:key' do
  like_article(params[:key])
  redirect to("#{request.referrer}")
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
  haml :single    
end


get "/css/:stylesheet.css" do
  content_type "text/css", :charset => "UTF-8"
  sass :"css/#{params[:stylesheet]}"
end 


helpers do
  def get_article(key)
    redis = Redis.new
    redis.select 1
    if key.include?("reader")
      @object = JSON.parse(redis.get("#{key}"))
    else
      @object = JSON.parse(redis.get(redis.keys("*#{key}")[0]))
    end
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

  def like_article(key)
    redis = Redis.new
    redis.select 1
    redis.zincrby("zlikes", 1, key)
  end

  def unique_key(longkey)
    return longkey.slice(-16..-1)
  end
      

end
