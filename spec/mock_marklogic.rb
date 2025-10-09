# Mock MarkLogic implementation for testing
require 'logger'
require 'securerandom'

module MarkLogic
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
  class Connection
    def initialize(host, port)
      @host = host
      @port = port
    end
    
    def self.configure(options)
      # Mock configuration
    end
  end
  
  class Database
    def initialize(name, connection)
      @name = name
      @connection = connection
    end
    
    def collection(name)
      Collection.new(name, self)
    end
    
    def clear
      # Mock clear operation
    end
    
    def exists?
      true
    end
  end
  
  class Collection
    def initialize(name, database)
      @name = name
      @database = database
    end
    
    def find(*args)
      []
    end
    
    def remove
      # Mock remove operation
    end
  end
  
  class ObjectId
    def initialize(id = nil)
      @id = id || SecureRandom.hex(12)
    end
    
    def to_s
      @id
    end
    
    def ==(other)
      other.is_a?(ObjectId) && @id == other.to_s
    end
  end
  
  class Application
    def initialize(name, **options)
      @name = name
      @connection = options[:connection]
    end
    
    def add_index(index)
      # Mock index addition
    end
    
    def stale?
      false
    end
    
    def connection
      @connection
    end
    
    def content_databases
      [Database.new('test-db', @connection)]
    end
    
    def sync
      # Mock sync operation
    end
    
    def drop
      # Mock drop operation
    end
  end
  
  class Cursor
    def initialize(results)
      @results = results
    end
  end
  
  module DatabaseSettings
    class RangeElementIndex
      def initialize(field, options = {})
        @field = field
        @options = options
      end
    end
    
    class RangeFieldIndex
      def initialize(field, options = {})
        @field = field
        @options = options
      end
    end
    
    class RangePathIndex
      def initialize(field, options = {})
        @field = field
        @options = options
      end
    end
  end
end

# Make the mock available globally
require_relative 'mock_marklogic'
