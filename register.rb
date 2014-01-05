require 'rubygems'
require 'sinatra'
require 'sinatra/flash'
require 'sinatra/config_file'
require 'haml'
require 'rack/recaptcha'
require 'rest_client'

config_file 'config.yml'

configure do
  set :server, 'thin'
  #set :environment, :production
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :session_secret, settings.session_secret

  use Rack::Recaptcha, :public_key => settings.recaptcha['public_key'], :private_key => settings.recaptcha['private_key']

  enable :sessions
  enable :logging, :dump_errors, :raise_errors, :show_exceptions

  helpers Rack::Recaptcha::Helpers

  logger = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  logger.sync = true

  STDOUT.reopen(logger)
  STDERR.reopen(logger)
end

before do
    logger.level = 0
end

def show_message(msg, options = {})
  options = {
    :type => :error,
    :redirect => true
  }.merge(options)

  logger.send(options[:type], "#{msg['log']}, from IP: #{request.ip}")
  flash[options[:type]] = eval("\"" + msg['message'] + "\"")
  redirect "/" if options[:redirect]
end

get '/' do
  haml :index, :format => :html5 
end

post '/register' do
  show_message(settings.messages['invalid_captcha']) unless recaptcha_valid?
  show_message(settings.messages['empty_password']) if params[:password].length == 0
  show_message(settings.messages['password_too_short']) if params[:password].length < 6
  show_message(settings.messages['password_mismatch']) unless params[:password].eql?(params[:passwordrepeat])

  begin
    result = RestClient.get "#{settings.url}/plugins/userService/userservice", {:params => {
        'secret' => settings.openfire_secret,
        'type' => 'add',
        'username' => params['username'],
        'password' => params['password'],
        'email' => params['email']
      }
    }

    logger.debug "RAW: #{result.strip}"

    show_message(settings.messages['user_exists']) if result.include?('UserAlreadyExistsException')
    show_message(settings.messages['request_not_authorized']) if result.include?('RequestNotAuthorised')
    show_message(settings.messages['shared_group_exception']) if result.include?('SharedGroupException')
    show_message(settings.messages['registration_disabled']) if result.include?('UserServiceDisabled')
    show_message(settings.messages['user_registered'], :type => :info) if result.downcase.include?('<result>ok</result>')
  rescue => e
    show_message(settings.messages['unknown_error'])
    logger.error e.backtrace.join("\n")
  end

  redirect "/"
end

not_found do
  redirect "/"
end

error do
  redirect "/"
end
