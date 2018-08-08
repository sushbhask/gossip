class Node
  # attributes of me, a  node:
  # message_history: list of all messages I've seen before
  # peers_favorite_books: key value store of key port number, value {"version": X, "title": Y}
  # favorite_book: my current favorite favorite_book
  # version_number: the version of my favorit book
  # port_number (effectively my uuid)
  attr_accessor :port_number
  attr_accessor :message_history
  attr_accessor :peers_favorite_books
  attr_accessor :favorite_book

  def initialize(port)
    self.originating_port = port
  end

  def receive_message(message)
    # check the message uuid
    # have i received it yet? if so, ignore
    # if i haven't received it yet, then check what the latest version of the node favorite i have is
    # if i have a later favorte, then ignore it
    # if i don't have a later favorite, update my store
  end

  def update_favorite_book
    all_books = IO.readlines('books.txt')
    random_book = all_books.sample
    self.favorite_book = random_book
    self.version_number += 1
  end

end
