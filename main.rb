require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'little_code' 

set :port, 9494

helpers do

  SUITS = ["hearts", "spades", "clubs", "diamonds"]
  CARDS = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace']

  def start_game
    session[:deck] = SUITS.product(CARDS).shuffle!
    session[:player_hand] = []
    session[:dealer_hand] = []
    deal_opening_cards(session[:player_hand],session[:dealer_hand], session[:deck])
    session[:player_total] = get_total(session[:player_hand])
    session[:dealer_total] = get_total(session[:dealer_hand])
    session[:next_move] = "Play"
    session[:turn] = true
    check_natural_blackjack(session[:player_total], session[:dealer_total], session[:pay])
    session[:hide_dealer] = true
  end

  def deal_opening_cards(player_hand, dealer_hand, deck)
    2.times {
      player_hand << deck.pop
      dealer_hand << deck.pop}
  end


  def get_total(cards)
    arr = cards.map { |element| element[1] }
    total = 0
    arr.each do |v|
      if v == "Ace"
        total += 11
      else
        total += v.to_i == 0 ? 10 : v.to_i
      end
    end
    arr.select {|element| element == "Ace"}.count.times do
      break if total <= 21
      total -= 10
    end
    total
  end

  def ace_correct(aces, total)
    aces.count.times {
      if total <= 10
        total += 11
      else
        total += 1
      end  
    }
  end

  def compare_totals(player_cards, dealer_cards)
    player_total = get_total(player_cards)
    dealer_total = get_total(dealer_cards)
    if player_total < 22 && player_total > dealer_total
      return "you win!", 2
    elsif dealer_total > 22
      return "the dealer busted, you win!", 2
    elsif player_total == dealer_total
      return "it's a push, you both have #{session[:player_total]}", 1
    elsif player_total > 21
      return "you busted!", 0
    elsif player_total == 21 && player_cards.count == 2
      return "you have a natural blackjack!", 2.5
    elsif dealer_total == 21 && dealer_cards.count == 2
      return "the dealer has a natural blackjack.", 0
    else
      return "the dealer wins.", 0
    end
  end

  def card_image(card)
    "<img id='card' src='/images/cards/#{card[0]}_#{card[1]}.jpg' />"
  end

  def player_bust(total)
    if total > 21
      session[:result] = true
      session[:result_text] = "you busted!"
      session[:turn] = false
    end
  end

  def check_natural_blackjack(player_total, dealer_total, pay)
    if player_total == 21
      redirect '/game/compare'
    elsif dealer_total == 21
      redirect '/game/compare'
    elsif player_total == 21 && dealer_total == 21
      redirect '/game/compare'
    else
    end    
  end

  def clean_up
    session.delete :player_hand
    session.delete :dealer_hand
    session.delete :result
    session.delete :turn
    session.delete :pay
    session.delete :bet_error
  end

  def payout(wallet, payout, bet)
    wallet += bet * payout

    return wallet
  end

  def end_of_hand
    session[:player_name] && session[:wallet] && session[:bet] && session[:result]
  end

end

before do
  # before every page load, all these things will happen
end


get '/' do
  session.clear
  redirect '/new_player'
end

get '/new_player' do
  erb :name
end

post '/new_player' do
  session[:player_name] = params[:player_name]
  session[:all_in] = 0
  redirect '/wallet'
end

get '/wallet' do
  erb :wallet
end

post '/wallet' do
  if params[:wallet].to_i == 0 || params[:wallet].to_i < 1
    @wallet_error = true
    erb :wallet
  else
    session[:wallet] = params[:wallet].to_i
    session[:all_in] += params[:wallet].to_i
    redirect '/bet'
  end
end

get '/bet' do
  erb :bet
end

post '/bet' do

  if params[:bet].to_i > session[:wallet]
    session[:bet_error] = true
    session[:bet_error_text] = "You can't bet more than your wallet of $#{session[:wallet]}."
    redirect '/bet'
  end  
  if params[:bet].to_i <= 0 || params[:bet].to_i < 1
    session[:bet_error] = true
    session[:bet_error_text] = "You need to put in a number greater than 0."
    redirect '/bet'
  else
    session[:bet] = params[:bet].to_i
    session[:wallet] -= params[:bet].to_i
    session[:next_move] = "Start"
    redirect '/game'
  end
end

get '/game' do
  if session[:next_move] == "Start"
    start_game
    erb :game
  else
    erb :game
  end
end


post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  session[:player_total] = get_total(session[:player_hand])
  player_bust(session[:player_total])
  redirect '/game'
end

post '/game/player/stay' do
  session[:turn] = false
  redirect "game/dealer"
end


get '/game/dealer' do
  if session[:dealer_total] > 17
    redirect '/game/compare'
  else
    begin 
      session[:dealer_hand] << session[:deck].pop
      session[:dealer_total] = get_total(session[:dealer_hand])
    end while session[:dealer_total] <= 17
    redirect '/game/compare'
  end
end

get '/game/compare' do
  session[:result_text], session[:pay] = compare_totals(session[:player_hand], session[:dealer_hand])
  session[:result] = true    
  session[:turn] = false
  session[:wallet] = payout(session[:wallet], session[:pay], session[:bet])
  redirect '/game'
end

get '/game/new_hand' do
  clean_up
  if session[:wallet] <= 0
    redirect '/broke'
  else
    redirect '/bet'
  end
end

get '/game/clear' do
  redirect '/'
end

get '/broke' do
  erb :broke
end