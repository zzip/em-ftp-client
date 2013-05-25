module EventMachine
  module FtpClient
  # Streams large string over a given connection. Streaming begins once the object is
  # instantiated. Typically StringStreamer instances are not reused.
  #
  # Streaming uses buffering in chunks of 16K for strings.
  #
  # based on EventMachine::FileStreamer
  #
    class StringStreamer
      include Deferrable

      # Use mapped streamer for files bigger than 16k
      MappingThreshold = 16384
      # Wait until next tick to send more data when 50k is still in the outgoing buffer
      BackpressureLevel = 50000
      # Send 16k chunks at a time
      ChunkSize = 16384

      # @param [EventMachine::Connection] connection
      # @param [String] string Data to send
      #
      def initialize connection, data, args = {}
        @connection = connection

        @size = data.size

        stream_with_mapping data
      end

      # @private
      def stream_with_mapping data
        @position = 0
        @mapping = data
        stream_one_chunk
      end
      private :stream_with_mapping

      # Used internally to stream one chunk at a time over multiple reactor ticks
      # @private
      def stream_one_chunk
        loop {
          if @position < @size
            if @connection.get_outbound_data_size > BackpressureLevel
              EventMachine::next_tick {stream_one_chunk}
              break
            else
              len = @size - @position
              len = ChunkSize if (len > ChunkSize)

              @connection.send_data( @mapping[@position, len] )

              @position += len
            end
          else
            succeed
            break
          end
        }
      end

    end # StringStreamer
  end # FtpClient
end # EventMachine
