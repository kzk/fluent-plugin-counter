class Fluent::CounterOutput < Fluent::TimeSlicedOutput
  Fluent::Plugin.register_output('counter', self)

  config_set_default :buffer_type, 'memory'
  config_set_default :time_slice_format, '%Y%m%d%H%M' # minitely

  config_set_default :utc, true
  config_set_default :localtime, false

  config_set_default :flush_interval, 1
  config_set_default :time_slice_wait, 1

  config_param :redis_host, :string, :default => 'localhost'
  config_param :redis_port, :integer, :default => 6379
  config_param :redis_db, :string, :default => '0'

  def initialize
    super
    @storage = RedisStorage.new(@redis_host, @redis_port, @redis_db)
  end

  def configure(conf)
    super
  end

  def start
    super
  end

  def shutdown
    super
  end

  def format(tag, time, record)
    {
      'tag'   => tag,
      'time'  => time,
      'key'   => record['key'],
      'value' => record['value'],
    }.to_msgpack
  end

  def write(chunk)
    h = {}
    chunk.msgpack_each { |record|
      key = ''
      record['key'].each { |k|
        key = key.empty? ? k : (key + ":" + k)
        value = record['value'].to_i
        h[key] = (h.has_key? key) ? (h[key] + value) : value
      }
    }
    @storage.connect { |c|
      h.each { |k, v| @storage.incr(c, chunk.key, k, v) }
    }
  end

  class RedisStorage
    def initialize(host, port, db)
      require 'redis'
      @host = host
      @port = port
      @db = db
    end

    def connect(&block)
      conn = open
      begin
        conn.pipelined { yield conn }
      ensure
        close(conn)
      end
    end

    def open
      Redis.new(:host => @host, :port => @port, :db => @db, :thread_safe => true)
    end

    def close(conn)
      conn.quit
    end

    def incr(conn, time, key, value)
      conn.hincrby time, key, value
    end
  end
end
