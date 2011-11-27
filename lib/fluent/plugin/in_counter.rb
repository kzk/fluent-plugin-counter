#
# Copyright (C) 2011 Kazuki Ohta
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
module Fluent

class CounterInput < Input
  Plugin.register_input('counter', self)

  config_param :port,            :integer, :default => 1463
  config_param :bind,            :string,  :default => '0.0.0.0'
  config_param :server_type,     :string,  :default => 'nonblocking'
  config_param :is_framed,       :bool,    :default => true
  config_param :body_size_limit, :size,    :default => 32*1024*1024  # TODO default

  def initialize
    require 'thrift'
    $:.unshift File.join(File.dirname(__FILE__), 'thrift')
    require 'counter_types'
    require 'counter_constants'
    require 'counter'
    super
  end

  def configure(conf)
    super
  end

  def start
    $log.debug "listening counter on #{@bind}:#{@port}"

    handler = FluentCounterHandler.new
    processor = Counter::Processor.new handler

    @transport = Thrift::ServerSocket.new @bind, @port
    if @is_framed
      transport_factory = Thrift::FramedTransportFactory.new
    else
      transport_factory = Thrift::BufferedTransportFactory.new
    end

    # 2011/09/29 Kazuki Ohta <kazuki.ohta@gmail.com>
    # This section is a workaround to set strict_read and strict_write option.
    # Ruby-Thrift 0.7 set them both 'true' in default, but this plugin set
    # them both 'false'.
    protocol_factory = Thrift::BinaryProtocolFactory.new
    protocol_factory.instance_eval {|obj|
      def get_protocol(trans) # override
        return Thrift::BinaryProtocol.new(trans,
                                          strict_read=false,
                                          strict_write=false)
      end
    }

    case @server_type
    when 'simple'
      @server = Thrift::SimpleServer.new processor, @transport, transport_factory, protocol_factory
    when 'threaded'
      @server = Thrift::ThreadedServer.new processor, @transport, transport_factory, protocol_factory
    when 'thread_pool'
      @server = Thrift::ThreadPoolServer.new processor, @transport, transport_factory, protocol_factory
    when 'nonblocking'
      @server = Thrift::NonblockingServer.new processor, @transport, transport_factory, protocol_factory
    else
      raise ConfigError, "in_counter: unsupported server_type '#{@server_type}'"
    end
    @thread = Thread.new(&method(:run))
  end

  def shutdown
    @transport.close unless @transport.closed?
    #@thread.join # TODO
  end

  def run
    @server.serve
  rescue
    $log.error "unexpected error", :error=>$!.to_s
    $log.error_backtrace
  end

  class FluentCounterHandler
    def Post(e)
      record = {
        'key' => e.key,
        'value' => e.value
      }
      Engine.emit(e.category, e.timestamp, record)
      return ResultCode::OK
    end
  end
end

end
