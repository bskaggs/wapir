# Wapir

Wapir is a <b>W</b>ikipedia <b>API</b> for <b>R</b>uby.

## Installation

Add this line to your application's Gemfile:

    gem 'wapir'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wapir

## Usage

    require 'wapir'

    #you must provide your own user agent string to connect to the API
    c = Wapir::Client.new("http://en.wikipedia.org/", user_agent: "My Sample App using Wapir (http://example.com)")
    
    #get categories
    c.categories_for(["Albert Einstein", "Ruby (programming language)"]).each { |x| puts x }
    
    #get content
    c.content(["dogs", "cats"]).each { |x| puts x }
    
    #get pages in a category
    c.pages_in_category('Category:Living people') { |y| puts y["title"] }

    #login to make changes or use higher bot limits
    c.login("username", "password")

    #you can connect to other sites
    c = Wapir::Client.new("http://www.wikidata.org/", user_agent: "My Sample App using Wapir (http://example.com)")

## Contributing

1. Fork it ( https://github.com/bskaggs/wapir/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
