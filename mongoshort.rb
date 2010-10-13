require 'sinatra'
require 'mongoid'
require 'uri'
require 'digest/md5'
require File.expand_path('models/url')

# If using Basic Authentication, please change the default passwords!
CREDENTIALS = ['mongoshort', 'mongoshort']

configure :development do
  Mongoid.configure do |config|
    name = 'mongoidshort_dev'
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
    config.persist_in_safe_mode = false
  end
  enable :run
end

configure :test do
  Mongoid.configure do |config|
    name = 'mongoidshort_test'
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
    config.persist_in_safe_mode = false
  end
end

configure :production do
  Mongoid.configure do |config|
    name = 'mongoidshort'
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
    config.persist_in_safe_mode = false
  end
end

helpers do
  # Does a few checks for HTTP Basic Authentication.
  def protected!
    auth = Rack::Auth::Basic::Request.new(request.env)

    # Return a 401 error if there's no basic authentication in the request.
    unless auth.provided?
      response['WWW-Authenticate'] = %Q{Basic Realm="Mongoshort URL Shortener"}
      throw :halt, [401, 'Authorization Required']
    end
  
    # Non-basic authentications will be returned as a bad request (400 error).
    unless auth.basic?
      throw :halt, [400, 'Bad Request']
    end

    # The basic checks are okay - Check if the credentials match.
    if auth.provided? && CREDENTIALS == auth.credentials
      return true
    else
      throw :halt, [403, 'Forbidden']
    end
  end
end

get '/' do
  # You can set up an index page (under the /public directory).
  "MongoidShort"
end

get '/:url' do
  url = URL.where(:url_key => params[:url]).first
  if url.nil?
    raise Sinatra::NotFound
  else
    url.last_accessed = Time.now
    url.times_viewed += 1
    url.save
    redirect url.full_url, 301
  end
end

post '/new' do
  protected!
  content_type :json
  
  if !params[:url]
    status 400
    return { :error => "'url' parameter is missing" }.to_json
  end
  
  url = URL.find_or_create(params[:url])
  return url.to_json
end

not_found do
  # Change this URL to wherever you want to be redirected if a non-existing URL key or an invalid action is called.
  redirect "http://#{Sinatra::Application.bind}/"
end
