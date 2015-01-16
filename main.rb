require 'rubygems'
require 'sinatra'

set :port, 9494

get '/home' do
  "Welcome Home. It's Wednesday. Hey JOhny"

end

get '/beaboss' do
  "Yo son, I got this"
end

get '/thugtemplate' do
  erb :thug

end

get '/birdthug' do
  erb :"user/thuglife"
end