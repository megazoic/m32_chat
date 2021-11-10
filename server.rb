require 'socket'

class UDPServer
  def initialize(port)
    @port = port
    @attendees = []
  end

  def start
    @socket = UDPSocket.new
    @socket.bind("0.0.0.0", @port)
    #AsyncUDPMessage* my_message = new AysncUDPMessage();

    while true
      #packet = @socket.recvfrom(1024)
      #puts packet
      data, from = @socket.recvfrom( 200, 0 )
      dataBytes = data.unpack('C*')
      ip_addr = from[2]
      if @attendees.include?(ip_addr)
        temp = @attendees.map(&:clone)
        temp.delete(ip_addr)
        temp.each do |op|
          @socket.send(data, 0, op, @port)
        end
        temp = []
      else
        #test for sending of tripple v
        if dataBytes[1] & 0b00000011 == 1 && dataBytes[2] == 88 && dataBytes[3] == 86\
          && dataBytes[4] == 21 && dataBytes[5] == 176
          #welcome
          @attendees << ip_addr
          #get wpm from data and build string to reply with
          wpmTemp = dataBytes[1]
          wpmTemp = wpmTemp & 252
          wpmTemp = wpmTemp | 2
          dataOut = []
          dataOut << dataBytes[0]
          dataOut << wpmTemp
          dataOut.concat([152, 100, 165]) # send qrz
          @socket.send(dataOut.pack('C*'), 0, ip_addr, @port) #send qrz
        end
      end
      puts "attendees #{@attendees}"
      puts "reply #{data}"
      puts "from #{from[2]}"
      puts "in int #{data.unpack('C*')}"
      puts "and in hex #{data.unpack('C*').map {|e| e.to_s 16}}"
    end
  end
end
puts "starting server"
server = UDPServer.new(7373)
server.start
