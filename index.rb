require 'json'

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
  if session.include?("user")
    @user = session['user']
  else
    @user = "Guest"
  end
  haml :list
end

get '/auth/:provider/callback' do
  content_type 'text/plain'
  $auth_hash = request.env['omniauth.auth'].to_hash rescue "No Data"
  session['user'] ||= $auth_hash.values_at("uid")[0]
  redirect to(request.env['omniauth.origin'])
end

get '/auth/failure' do
  content_type 'text/plain'
  request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
end

get '/whoami' do
  "You are #{session['user']}"
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
    redis.zincrby($auth_user.to_s + ":zlikes", 1, key)
  end

  def unique_key(longkey)
    return longkey.slice(-16..-1)
  end
      

end
