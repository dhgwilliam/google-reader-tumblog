require 'rubygems'
require 'sinatra'
require 'bundler'
require 'redis'
require './index'

root_dir = File.dirname(__FILE__)
 
set :environment, ENV['RACK_ENV'].to_sym
set :root,        root_dir
set :app_file,    File.join(root_dir, 'index.rb')
disable :run

Encoding.default_external = Encoding::UTF_8

run Sinatra::Application
