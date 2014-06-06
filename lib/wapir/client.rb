require 'faraday'
require 'json'

module Wapir
  class Client
   def initialize(url, options = {})
      raise "You must specify user_agent per https://meta.wikimedia.org/wiki/User-Agent_policy" unless options[:user_agent]
      @conn = Faraday.new(url: url) do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
        f.headers[:user_agent] = "#{options[:user_agent]} BasedOnWapir/#{Wapir::VERSION} (#{Wapir::HOME})"
        yield(f) if block_given?
      end
    end

    #logic from https://www.mediawiki.org/wiki/API:Query#Continuing_queries
    def query(request)
      request[:action] = :query
      request[:format] = :json
      last_continue = {continue: ""}

      loop do
        req = request.merge(last_continue)
        result = @conn.get('/w/api.php', req)
        json = JSON.parse(result.body)
        
        raise "Returned error: #{json['error']}" if json.has_key?('error')
        STDERR.puts(json['warnings']) if json.has_key?('warnings')
        yield json['query'] if json.has_key?('query')
        break unless json.has_key?('continue')
        last_continue = json['continue']
      end
    end

    def query_array_or_block(q, &block)
      if block
        query(q) { |x| yield x }
      else
        result = []
        query(q) { |x| result << x }
        result
      end
    end


    
    def categories_for(titles, options = {}, &block)
      titles = [titles].flatten.sort.uniq.join("|").gsub("\n", ' ')
      query_array_or_block({prop: "categories", titles: titles, cllimit: "max"}.merge!(options), &block)
    end

    def pages_in_category(title, options = {}, &block)
      query_array_or_block({list: "categorymembers", cmtitle: title.gsub("\n", ' '), cmlimit: "max"}.merge!(options), &block)
    end
  end
end

c = Wapir::Client.new("http://en.wikipedia.org/", user_agent: "WapirTest (#{Wapir::HOME})")
c.categories_for(["Albert Einstein", "Ruby (programming language)"]).each { |x| p x }
#c.pages_in_category('Category:Living people') { |x| x["categorymembers"].each { |y| puts y["title"] } }
#c.category("Category:Living people").
#Wikipedia::Page.all.
#Wikipedia::Category
#Wikipedia::Default
