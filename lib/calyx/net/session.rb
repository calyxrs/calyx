module Calyx::Net
  # Extended information about a connection that has been validated, but may not have been authenticated yet.
  class Session
    # The EventMachine connection.
    attr :connection
    
    # The player's username.
    attr :username
    
    # The player's password.
    attr :password
    
    # The client UID.
    attr :uid
    
    # The ISAAC cipher used for incoming packets.
    attr :in_cipher
    
    # The ISAAC cipher used for outgoing packets.
    attr :out_cipher
    
    attr_accessor :player

    # Creates a new session with validated credentials.
    def initialize(connection, username, password, uid, in_cipher, out_cipher)
      @connection = connection
      @username = username
      @password = password
      @uid = uid
      @in_cipher = in_cipher
      @out_cipher = out_cipher
    end
  end
end
