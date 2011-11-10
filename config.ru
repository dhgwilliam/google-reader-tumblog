require 'rubygems'
require 'sinatra'
require 'bundler'
require 'redis'
require 'omniauth'
require 'omniauth-google-oauth2'
require './index'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

root_dir = File.dirname(__FILE__)
ENV['GOOGLE_KEY'] = "327827470050.apps.googleusercontent.com"
ENV['GOOGLE_SECRET'] = "mPD7j6EeVpIquqn435jVsIZm"
 
set :environment, ENV['RACK_ENV'].to_sym
set :root,        root_dir
set :app_file,    File.join(root_dir, 'index.rb')
disable :run
enable :sessions

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_KEY'], ENV['GOOGLE_SECRET'], {
    :scope => 'https://www.googleapis.com/auth/plus.me'
  }
end

run Sinatra::Application
