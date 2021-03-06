require 'rubygems'
require 'sinatra'
require 'sinatra/flash'
require 'sinatra/config_file'
require 'haml'
require 'rack/recaptcha'
require 'rest_client'
require 'redis'

require './messages'

$Redis = Redis.new

configure do
  set :server, 'thin'
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :protection, :origin_whitelist => ['https://secure.jid.pl']

  config_file 'config.yml'

  abort "No session secret provided" if settings.session_secret.nil?
  abort "No recaptcha public key provided" if settings.recaptcha['public_key'].nil?
  abort "No recaptcha private key provided" if settings.recaptcha['private_key'].nil?
  abort "No URL provided" if settings.url.nil?
  abort "No OpenFire secret provided" if settings.openfire_secret.nil?

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

  if params[:username].nil?
    logger.send(options[:type], msg[:log])
    flash[options[:type]] = msg[:message]
  else
    logger.send(options[:type], "#{msg[:log].gsub('#USERNAME#', params[:username])}, from IP: #{request.ip}")
    flash[options[:type]] = msg[:message].gsub('#USERNAME#', params[:username])
  end

  redirect "/" if options[:redirect]
end

get '/' do
  haml :index, :format => :html5 
end

post '/register' do
  key = "ip:#{request.ip}:request_count"

  registration_count = $Redis.get(key).to_i

  if registration_count > settings.registration_limit
    show_message(Messages.errors[:limit_exceeded])
    logger.error "Current limit value: #{registration_count}"
    logger.error "Current ttl value: #{$Redis.ttl(key)}"
    halt 400
  end

  show_message(Messages.errors[:empty_username]) if params[:username].length == 0
  show_message(Messages.errors[:invalid_captcha]) unless recaptcha_valid?
  show_message(Messages.errors[:empty_password]) if params[:password].length == 0
  show_message(Messages.errors[:password_too_short]) if params[:password].length < 6
  show_message(Messages.errors[:password_mismatch]) unless params[:password].eql?(params[:passwordrepeat])

  logger.info "Registering new user with username '#{params['username']}'..."

  begin
    result = RestClient.get "#{settings.url}/plugins/userService/userservice", {:params => {
        'secret' => settings.openfire_secret,
        'type' => 'add',
        'username' => params['username'],
        'password' => params['password'],
        'email' => params['email']
      }
    }
  rescue => e
    logger.error e.backtrace.join("\n")
    show_message(Messages.errors[:unknown_error])
  end

  logger.debug "RAW: #{result.strip}"

  show_message(Messages.errors[:user_exists]) if result.include?('UserAlreadyExistsException')
  show_message(Messages.errors[:request_not_authorized]) if result.include?('RequestNotAuthorised')
  show_message(Messages.errors[:shared_group_exception]) if result.include?('SharedGroupException')
  show_message(Messages.errors[:registration_disabled]) if result.include?('UserServiceDisabled')

  if result.downcase.include?('<result>ok</result>')
    show_message(Messages.infos[:user_registered], :type => :info)
    $Redis.set(key, registration_count + 1, :ex => settings.registration_limit_period)
  end

  show_message(Messages.errors[:unknown_error])
end

not_found do
  redirect "/"
end

error do
  redirect "/"
end

