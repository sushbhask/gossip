require 'sinatra'
require 'json'
require './node.rb'

PORT, PEER_PORT = ARGV
set :port, PORT

Thread.abort_on_exception = true # don't want this to fail silently
Thread.new do
  node = Node.get_singleton(PORT)
  if PEER_PORT
    node.bootstrap_from_peer(PEER_PORT)
  end
  loop do
    node = Node.get_singleton(PORT)
    node.update_favorite_book
    sleep 3
  end
end

get '/peers' do
  node = Node.get_singleton(settings.port)
  return {
    "port_number": node.port_number,
    "peers_favorite_books": node.peers_favorite_books,
    "favorite_book": node.favorite_book,
    "version_number": node.version_number,
    "message_history": node.message_history
  }.to_json
end

post '/gossip' do
  incoming_port = request.port
  message = JSON.parse(request.body.read)
  node = Node.get_singleton(settings.port)
  node.receive_message(message)
end

get '/' do
  node = Node.get_singleton(settings.port)
  return {
    "port_number": node.port_number,
    "peers_favorite_books": node.peers_favorite_books,
    "favorite_book": node.favorite_book,
    "version_number": node.version_number,
    "message_history": node.message_history
  }.to_json
end
