require 'socket'

=begin
  UDP server for morserino_32 units to hold net
  datagram will contain bytes that provide version number and serial in first byte
  word per minute in 1st 6 bits of 2nd byte as a decimal then remaining two bits
  are beginning of morse code as dits (01), dahs (10), interword space (00) and
  end of word (11)
  after checkin when op sends 'vvv' their ip address is stored and 'qrz' is sent back
  to acknowledge. From then on any member can send and their word will be broadcast
=end

class UDPServer
  def initialize(port)
    @port = port
    @attendees = []
    @lastSig = Time.now
  end

  def start
    @socket = UDPSocket.new
    @socket.bind("0.0.0.0", @port)

    while true
      data, from = @socket.recvfrom( 200, 0 )
      #if here then someone sent a datagram
      if (Time.now - @lastSig) / 60 > 10
        #empty the attendees array, start over
        @attendees = []
        puts "times up"
      end
      @lastSig = Time.now
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
          #welcome, add to attendees and reply with qrz
          @attendees << ip_addr
          #get wpm from packet data and build string to reply with
          wpmTemp = dataBytes[1]
          wpmTemp = wpmTemp & 252 #mask upper 6 bits leaving remaining as 00
          wpmTemp = wpmTemp | 2 #last two bits of byte need to be 10 for begin ltr q
          dataOut = []
          #get ver and serial number, just add this to response
          dataOut << dataBytes[0]
          dataOut << wpmTemp
          dataOut.concat([152, 100, 165, 192]) # add remainder of q then finish with rz
          @socket.send(dataOut.pack('C*'), 0, ip_addr, @port) #send qrz
        end
      end
    end
  end
end
puts "starting server"
server = UDPServer.new(7373)
server.start
