require 'faraday'
require 'json'
require 'faraday-cookie_jar'

module Wapir
  class Client
    def initialize(url, options = {})
      raise "You must specify user_agent per https://meta.wikimedia.org/wiki/User-Agent_policy" unless options[:user_agent]
      @conn = Faraday.new(url: url) do |f|
        f.use :cookie_jar
        f.request :url_encoded
        f.adapter Faraday.default_adapter
        f.headers[:user_agent] = "#{options[:user_agent]} BasedOnWapir/#{Wapir::VERSION} (#{Wapir::HOME})"
        f.response :logger if options[:debug]
        yield(f) if block_given?
      end

      @default_languages = "en"
      @default_wikis = "enwiki"
    end

    #raw functions
    def raw_get(request)
      @conn.post('/w/api.php', request)
    end

    def raw_post(request)
      @conn.post('/w/api.php', request)
    end

    #interpret as json
    def get(request)
      request[:format] = :json
      result = raw_get(request)
      JSON.parse(result.body)
    end

    def post(request)
      request[:format] = :json
      result = raw_post(request)
      JSON.parse(result.body)
    end

    def raw_action(action, options, method = :get)
      request = {action: action}.merge!(options)
      if method == :get
        json = get(request)
      else
        json = post(request)
      end
      raise "Returned error: #{json['error']}" if json.has_key?('error')
      STDERR.puts(json['warnings']) if json.has_key?('warnings')
      json
    end

    #logic from https://www.mediawiki.org/wiki/API:Query#Continuing_queries
    def query(request)
      last_continue = {continue: ""}
      loop do
        req = request.merge(last_continue)
        json = raw_action(:query, req)
        yield json['query'] if json.has_key?('query')
        break unless json.has_key?('continue')
        last_continue = json['continue']
      end
    end

    def login(user, password)
      request = {lgname: user, lgpassword: password}
      json = raw_action(:login, request, :post)
      request[:lgtoken] = json["login"]["token"]
      json = raw_action(:login, request, :post)
      json["login"]["result"]
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

    def lister(options, section) 
      if block_given?
        query(options) do |res|
          (res[section] || []).each do |val|
            yield(val)
          end
        end
      else
        res = []
        lister(options, section) { |r| res << r }
        res
      end
    end

    def piped_titles(titles, uniq = true)
      titles = [titles].flatten
      titles = titles.sort.uniq if uniq
      titles.join("|").gsub("\n", ' ')
    end

    #get proper names of articles
    def resolve(titles, options = {})
      normalize = {}
      redirect = {}
      found = Set.new
      query({redirects: "", titles: piped_titles(titles, unique = false) }.merge!(options)) do |res|
        (res["normalized"] || []).each { |r| normalize[r["from"]] = r["to"]}
        (res["redirects"] || []).each { |r|  redirect[r["from"]] = [r["to"], r["tofragment"]]}
        (res["pages"] || []).each { |page| found << page[1]["title"] unless page[1]["missing"]}
      end
      
      titles.map do |t|
        t = normalize[t] || t
        t = redirect[t] || [t, nil]
        found.include?(t[0]) ? t : nil
      end
    end

    def categories_for(titles, options = {}, &block)
      query_array_or_block({prop: "categories", titles: piped_titles(titles), cllimit: "max"}.merge!(options), &block)
    end
    
    def content(titles, options = {}, &block)
      query_array_or_block({prop: "revisions", rvprop: "content", titles: piped_titles(titles)}.merge!(options), &block)
    end

    #singletons
    def backlinks(title, options = {}, &block) 
      lister({list: "backlinks", bltitle: title.gsub("\n", ' '), bllimit: "max"}.merge!(options), "backlinks", &block)
    end
    
    def pages_in_category(title, options = {}, &block)
      lister({list: "categorymembers", cmtitle: title.gsub("\n", ' '), cmlimit: "max"}.merge!(options), "categorymembers", &block)
    end

    #wikibase
    def get_claims(entity, options = {})
      json = raw_action(:wbgetclaims, {entity: entity.gsub("\n", ' ')}.merge!(options))
      json["claims"]
    end
    
    def get_entities_by_title(titles, options = {})
      json = raw_action(:wbgetentities, {sites: @default_wikis, titles: piped_titles(titles), languages: @default_languages}.merge!(options))
      if block_given?
        json["entities"].each { |x| yield x }
      else
        json["entities"]
      end
    end
    
    def get_entities_by_id(ids, options = {})
      json = raw_action(:wbgetentities, {ids: [ids].flatten.join("|"), languages: @default_languages}.merge!(options))
      if block_given?
        json["entities"].each { |x| yield x }
      else
        json["entities"]
      end
    end

    def create_claim(entity, property, value, summary)
      raw_action(:wbcreateclaim, {entity: entity, property: property, snaktype: "value", value: value.to_json, summary: summary, token: csrftoken}, :post)
    end

    def csrftoken
      @csrftoken ||= raw_action(:query, {meta: "tokens"})["query"]["tokens"]["csrftoken"]
      @csrftoken
    end
  end
end
