require 'byebug'                # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri
  
  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    errors.add(:from, 'from does not equal to') if from == to
  end

  def initialize(api_key='')
    @from = @to = 'Kevin Bacon'
    @api_key = api_key
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      # your code here
    end
    # your code here: create the OracleOfBacon::Response object
  end

  def make_uri_from_arguments
    params = "?p=#{api_key}&a=#{CGI.escape(from)}&b=#{CGI.escape(to)}"
    @uri = "http://oracleofbacon.org/cgi-bin/xml#{params}"
  end
      
  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      if ! @doc.xpath('/error').empty?
        parse_error_response
      elsif ! @doc.xpath('/link').empty?
        @type = :graph
        @data = parse_graph_response(@doc)
      elsif ! @doc.xpath('//match').empty?
        @type = :spellcheck 
        @data = parse_spellcheck_response(@doc)
      else
        @type = :unknown
        @data = 'unknown data'
      end
    end
    
    def parse_graph_response(doc)
      actors = doc.xpath('//actor')
      movies = doc.xpath('//movie')
      result = [actors.first.content]
      movies.each_with_index do |movie,i|
        result << movie.content
        result << actors[i+1].content
      end
      result
    end
    
    def parse_spellcheck_response(doc)
      doc.xpath('//match').reduce([]){|r,n| r << n.content; r}
    end
    
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end
  end
end

