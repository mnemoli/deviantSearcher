require 'sinatra'
require 'tilt/erb'
require 'rss'
require 'open-uri'
require 'nokogiri'
require 'json'

set :static, true
set :public_folder, "static"
set :views, "views"

get '/devart' do
  badwords = get_bad_words
  theSearch = get_searchterm
  theOptions = get_search_options
  url = "http://backend.deviantart.com/rss.xml?type=deviation&q=#{theSearch}\+#{theOptions}"
  items = retrieve_items(url)
  erb :devart, :locals => {'feed' => items, 'searchterm' => theSearch, 'badwords' => badwords}
end

def get_bad_words
  return IO.readlines("badwords.txt").each {|l| l.chomp!}
end

def get_random_word
  random_word_api = "http://api.wordnik.com/v4/words.json/randomWord?api_key=a2a73e7b926c924fad7001ca3111acd55af2ffabf50eb4ae5"
  random_word_response = JSON.parse(open(random_word_api).read)
  return random_word_response["word"]
end

def get_searchterm
  return params[:search].empty? ? get_random_word : params[:search].split('+').first
end

def get_search_options
  if not params[:search].empty? then
    @x = params[:search].split('+')
    @x.shift
    return @x.join('+')
  end
end

def retrieve_items(url)

  @feed = Nokogiri::XML(open(url))
  @feed.remove_namespaces!
  @items = []
  @feed.search('item').map do |doc_item|
    @items << {
      "url" => doc_item.at('content/@url').respond_to?("text") ? doc_item.at('content/@url').text : "",
    "thumb" => doc_item.at_xpath('thumbnail[3]/@url').respond_to?("text") ? doc_item.at_xpath('thumbnail[3]/@url').text : "",
    "text" => doc_item.xpath('text').respond_to?("text") ? doc_item.xpath('text').text : "",
    "desc" => doc_item.at('description').text,
    "title" => doc_item.at('title').text,
    'user' => doc_item.xpath('credit').first.text
  }
  end

  return @items
end

get '/' do
    erb :search_form
end

get '/devsearch' do
  redirect to("/devart?search=#{params[:search]}")
end