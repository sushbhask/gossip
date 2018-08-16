require 'faraday'
require 'singleton'
require 'pry'

class Node
  include Singleton
  INFECTION_FACTOR = 3
  TTL = 5

  attr_accessor :port_number # (effectively my uuid)
  attr_accessor :message_history #list of all messages I've seen before
  attr_accessor :peers_favorite_books # key value store of key port number, value {"version": X, "title": Y}
  attr_accessor :favorite_book # my current favorite favorite_book
  attr_accessor :version_number # the version of my favorite book

  def self.get_singleton(port)
    node = Node.instance
    node.port_number = port
    node.message_history = node.message_history || []
    node.peers_favorite_books = node.peers_favorite_books || {}
    node.favorite_book = node.favorite_book || ""
    node.version_number = node.version_number || 0
    return node
  end

  def gossip_message_to_peers(message, incoming_port)
    eligible_peers = self.peers_favorite_books.keys - [incoming_port]
    peer_ports = eligible_peers.shuffle[0..INFECTION_FACTOR-1]
    peer_ports.each {|port|
      self.gossip_message_to_peer(message, port)
    }
  end

  def gossip_message_to_peer(message, to_port)
    conn = Faraday.new(:url => "http://localhost:#{to_port}/gossip")
    response = conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        :uuid => message["uuid"],
        :payload => message["payload"],
        :version_number => message["version_number"],
        :ttl => message["ttl"],
        :originating_port => message["originating_port"],
      }.to_json
    end
  end

  def receive_message(message)
    # check the message uuid
    # have i received it yet? if so, ignore
    uuid = message["uuid"]
    for message in message_history do
      if message["uuid"] == uuid
        puts "Node #{self.port_number} received duplicate message with uuid #{uuid}."
        return
      end
    end
    # if i haven't received it yet, then check what the latest version of the node favorite i have is
    # if i have a later favorte, then ignore it
    incoming_version = message["version_number"]
    incoming_port = message["originating_port"]
    current_favorite_book = peers_favorite_books[incoming_port]
    current_version = current_favorite_book && current_favorite_book["version_number"]
    if current_version && current_version >= incoming_version
      puts "Node #{self.port_number} already has the latest info for originating port #{incoming_port}."
    end
    # if i don't have the latest favorite, update my store
    peers_favorite_books[incoming_port] = {"version_number": incoming_version, "title": message["payload"]}
    puts "Node #{self.port_number} updated favorite book for node #{incoming_port}."
    # decrement TTL
    message["ttl"] = message["ttl"] - 1
    # if TTL > 0, pass the message on
    if message["ttl"] > 0
      self.gossip_message_to_peers(message, incoming_port)
    end
  end

  # def update_visualizer
  #   # now update the visualization app
  #   response = Unirest.post "localhost:80/",
  #     headers: { "Accept" => "application/json" },
  #     parameters:{  :originating_port => self.port_number,
  #       :peers_favorite_books => self.peers_favorite_books,
  #       :favorite_book => self.favorite_book
  #     }
  # end

  def bootstrap_from_peer(port)
    response = Faraday.get "http://localhost:#{port}/peers"
    self.peers_favorite_books = response["peers_favorite_books"]
    if self.peers_favorite_books.nil?
      self.peers_favorite_books = {}
    end
    self.peers_favorite_books[port] = {
      "version_number": response["version_number"],
      "title": response["favorite_book"]
    }
  end

  def update_favorite_book
    all_books = IO.readlines('books.txt')
    random_book = all_books.sample
    self.favorite_book = random_book
    self.version_number += 1
    self.update_peers
  end

  def update_peers
    peer_ports = self.peers_favorite_books.keys.shuffle[0..INFECTION_FACTOR-1]
    peer_ports.each {|port|
      self.update_peer(port)
    }
  end

  def update_peer(port)
    if port.nil?
      puts "could not update peer - must provide a valid port"
      return
    end
    conn = Faraday.new(:url => "http://localhost:#{port}/gossip")
    response = conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        :uuid => SecureRandom.hex(10),
        :originating_port => self.port_number,
        :version_number => self.version_number,
        :ttl => TTL,
        :payload => {"favorite_book": self.favorite_book}
      }.to_json
    end
  end
end
