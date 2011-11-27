class Fluent::CounterOutput < Fluent::TimeSlicedOutput
  Fluent::Plugin.register_output('counter', self)

  config_set_default :buffer_type, 'memory'
  config_set_default :time_slice_format, '%Y%m%d%H%M' # minitely

  config_set_default :utc, true
  config_set_default :localtime, false

  config_set_default :flush_interval, 1
  config_set_default :time_slice_wait, 1

  config_param :mongo_host, :string, :default => 'localhost'
  config_param :mongo_port, :integer, :default => 27017
  config_param :mongo_database, :string, :default => 'counter'
  config_param :mongo_collection, :string, :default => 'minutely'

  config_param :redis_host, :string, :default => 'localhost'
  config_param :redis_port, :integer, :default => 6379
  config_param :redis_database, :string, :default => '0'

  def initialize
    super
    @storage = MongoStorage.new(@mongo_host, @mongo_port, @mongo_database, @mongo_collection)
    # @storage = RedisStorage.new(@redis_host, @redis_port, @redis_database)
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

  class CounterStorage
    def connect(&block)
      conn = open
      begin
        yield conn
      ensure
        close(conn)
      end
    end

    def open
    end

    def close
    end
  end

  class MongoStorage < CounterStorage
    def initialize(host, port, db, coll)
      require 'mongo'
      @host = host
      @port = port
      @db = db
      @coll = coll
    end

    def open
      db ||= Mongo::Connection.new(@host, @port).db(@db)
      if db.collection_names.include?(@coll)
        collection = db.collection(@coll)
      else
        arg = { :capped => true, :size => 10000000, :max => 10000000 }
        collection = db.create_collection(@coll, arg)
      end
      collection
    end

    def close(conn)
      conn.db.connection.close
    end

    def incr(conn, time_minute, key, value)
      conn.update(
        { :time => time_minute, :key => key },
        { "$set" => { 'time' => time_minute, 'key' => key },
          "$inc" => { 'value' => value } },
        { :safe => true, :upsert => true })
    end
  end

  class RedisStorage < CounterStorage
    def initialize(host, port, db)
      require 'redis'
      @host = host
      @port = port
      @db = db
    end

    def open
      Redis.new(:host => @host, :port => @port, :db => @db, :thread_safe => true)
    end

    def close(conn)
      conn.quit
    end

    def incr(conn, time_minute, key, value)
      conn.hincrby time_minute, key, value
    end
  end
end
