module EventMachine
  module FtpClient
    class DataConnection < Connection
      include Deferrable

      def initialize( timeout = 5)
        set_pending_connect_timeout timeout
      end

      def on_connect(&blk); @on_connect = blk; end
      def on_file_sent(&blk); @on_file_sent = blk; end
      def on_stream_sent(&blk); @on_stream_sent = blk; end
      def on_disconnect(&blk); @on_disconnect = blk; end

      def stream(&blk); @stream = blk; end

      def post_init
        @buf = ''
      end

      def connection_completed
        @on_connect.call(self) if @on_connect
      end

      def receive_data(data)
        @buf += data
        if @stream
          @stream.call(@buf)
          @buf = ''
        end
      end

      def send_file(filename)
        streamer = EventMachine::FileStreamer.new(self, filename)
        streamer.callback{
          # file was sent successfully
          @on_file_sent.call(self) if @on_file_sent
          close_connection_after_writing
        }
      end

      def send_stream(data)
        streamer = EventMachine::FtpClient::StringStreamer.new(self, data)
        streamer.callback{
          # data was sent successfully
          @on_stream_sent.call(self) if @on_stream_sent
          close_connection_after_writing
        }
      end

      def unbind
        @on_disconnect.call(self) if @on_disconnect
        succeed(@buf)
      end
    end
  end
end
