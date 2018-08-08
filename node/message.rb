require 'securerandom'

class Message
  attr_accessor :uuid
  attr_accessor :originating_port
  attr_accessor :version_number
  attr_accessor :ttl
  attr_accessor :payload

  TTL_DEFAULT = 5

  def initialize(originating_port)
    self.uuid = SecureRandom.hex(10)
    self.version_number = 0
    self.update_favorite_book
    self.ttl = TTL_DEFAULT
    self.payload
  end

end
