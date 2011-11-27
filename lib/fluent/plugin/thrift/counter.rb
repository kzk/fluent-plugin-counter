#
# Autogenerated by Thrift
#
# DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
#

require 'thrift'
require 'counter_types'

module Counter
  class Client
    include ::Thrift::Client

    def Post(e)
      send_Post(e)
      return recv_Post()
    end

    def send_Post(e)
      send_message('Post', Post_args, :e => e)
    end

    def recv_Post()
      result = receive_message(Post_result)
      return result.success unless result.success.nil?
      raise ::Thrift::ApplicationException.new(::Thrift::ApplicationException::MISSING_RESULT, 'Post failed: unknown result')
    end

  end

  class Processor
    include ::Thrift::Processor

    def process_Post(seqid, iprot, oprot)
      args = read_args(iprot, Post_args)
      result = Post_result.new()
      result.success = @handler.Post(args.e)
      write_result(result, oprot, 'Post', seqid)
    end

  end

  # HELPER FUNCTIONS AND STRUCTURES

  class Post_args
    include ::Thrift::Struct, ::Thrift::Struct_Union
    E = 1

    FIELDS = {
      E => {:type => ::Thrift::Types::STRUCT, :name => 'e', :class => Event}
    }

    def struct_fields; FIELDS; end

    def validate
    end

    ::Thrift::Struct.generate_accessors self
  end

  class Post_result
    include ::Thrift::Struct, ::Thrift::Struct_Union
    SUCCESS = 0

    FIELDS = {
      SUCCESS => {:type => ::Thrift::Types::I32, :name => 'success', :enum_class => ResultCode}
    }

    def struct_fields; FIELDS; end

    def validate
      unless @success.nil? || ResultCode::VALID_VALUES.include?(@success)
        raise ::Thrift::ProtocolException.new(::Thrift::ProtocolException::UNKNOWN, 'Invalid value of field success!')
      end
    end

    ::Thrift::Struct.generate_accessors self
  end

end
