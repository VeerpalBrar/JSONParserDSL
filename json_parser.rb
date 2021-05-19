require 'net/http'
require 'json'
require 'ostruct'
require 'pp'

class ArrayResponse
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def where(key, method, value)
    result = response.select do |item| 
      item[key].send(method, value)
    end

    ApiResponse.create result
  end

  def get(key)
    result = response.map do |item| 
      item[key]
    end.compact

    ApiResponse.create result
  end
end

class HashResponse
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def where(key, method, value)
    result = response[key].send(method, value)

    ApiResponse.create result
  end

  def get(key)
    ApiResponse.create response[key]
  end
end

class DataResponse
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def method_missing(m, *args)
    raise "Value #{response} has no attribute '#{args[0]}'"
  end
end

class ApiResponse
  def self.create(response)
    return HashResponse.new(response) if response.is_a?(Hash) 
    return ArrayResponse.new(response) if response.is_a?(Array)

    DataResponse.new(response)
  end
end

class JsonParser 
  def self.fetch(url, &block)
    uri = URI(url)
    response = Net::HTTP.get(uri)
    self.new(response).query(&block)
  end

  def initialize(data)
    @data = ApiResponse.create(JSON.parse(data))
  end

  def query(&block)
    instance_eval(&block)
    pp @data.response
  end

  def get(key)
    @data = @data.get(key)
  end

  def where(key, method, value)
    @data = @data.where(key, method, value)
  end

  def method_missing(m, *args)
    raise "'#{m}' is not a valid command"
  end
end

if ARGV[0]
  file_path = ARGV[0]
  eval(File.read(file_path))
else
  puts "Please pass in the file to parse."
  puts "Usage: ruby json_parser.rb <filepath>"
end
