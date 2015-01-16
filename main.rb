require 'rubygems'
require 'sinatra'
require 'pry'

set :port, 9494

get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :name
end

post '/new_player' do
  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  binding.pry
  erb :bet


end

post '/bet' do
  session[:bet] = params[:bet]
  redirect '/game'
end

get '/game' do

end