require 'socket.so'

class UDPClient
  def initialize(host, port)
    @host = host
    @port = port
  end

  def start
    @socket = UDPSocket.open
    @socket.connect(@host, @port)
    while true
      @socket.send("dude", 0, @host, @port)
      sleep 2
    end
  end
end

client = UDPClient.new("localhost", 4321) # 10.10.129.139 is the IP of UDP server
client.start