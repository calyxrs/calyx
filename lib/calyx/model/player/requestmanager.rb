module Calyx::Player
  class RequestManager
    REQUESTS = { :trade => "tradereq", :duel => "duelreq" }
    attr_accessor :request_type
    attr_accessor :request_state
    attr_accessor :trade_state
    attr_accessor :accepted_trade
    attr_accessor :acquaintance
    
    def initialize
      @request_type = nil
      @request_state = :normal
      @trade_state = :none
      @accepted_trade = false
      @acquaintance = nil
    end
  end
end
