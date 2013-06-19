# Circular-Mail Library
# =================================================================================================
#      Author: gabor.major@csn.hu
#      Github: https://github.com/goobemaster/ruby-not-magic/circular-mail/
#    Rubygems: http://rubygems.org/gems/circular-mail
# Description: Mass email sending through smtp. Highly configurable, feature rich, robust solution.
#              Follows standards laid out in RFC-2822 (http://tools.ietf.org/html/rfc2822)
# =================================================================================================

module CircularMail

require 'net/smtp'
require 'yaml'

@@config = {'strictness' => true,
           'default_server' => 'mail.server.com',
           'default_port' => 25,
           'default_username' => 'guest',
           'default_password' => '',
           'default_authentication' => 'plain',
           'valid_authentications' => ['plain', 'login', 'cram_md5'],
           'valid_formats' => ['text', 'html'],
           'valid_charsets' => {'us-ascii' => 1..127, 'ascii' => 1..255, 'utf-8' => 1..1114111},
           'default_charset' => 'us-ascii',
           'default_format' => 'text',
           'character_limit' => 998,
           'character_limit_warn' => 78,
           'default_body' => "Dear @1@,\n\nPlease be informed that...\nYour custom string is: '@2@'\n\nKind Regards,\nAnonymous",
           'default_sender' => '',
           'default_sender_email' => 'mail@default.com',
           'email_validation' => /^[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+(?:\.[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/,
           'email_group_validation' => /^<[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+>$/,
           'recipients' => [],
           'attachments' => [],
           'undefined_variable' => '(?!)',
           'default_mail_per_dispatch' => 5,
           'default_wait_after_dispatch' => 3,
           'auto_backup' => true,
           'cr' => 13,
           'lf' => 10,
           'header_date_validation' => /^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), [0-9]{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} (\+|\-)[0-9]{4}$/,
           'valid_header_fields' => ['From', 'Sender', 'Reply-To', 'To', 'Cc', 'Bcc', 'Message-ID', 'Subject', 'Comments', 'Date'],
           'header_address_validation' => /^[a-zA-Z ]*<[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+(?:\.[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?>$/,
           'header_msgid_validation' => /^<([a-zA-Z0-9!#\$%&'\*\+\-\/=\?\^_`\{\}\|~]+\.?)+@([a-zA-Z0-9!#\$%&'\*\+\-\/=\?\^_`\{\}\|~]+\.?)+>$/,
           'header_unstructured_validation' => /^[a-zA-Z0-9!#\$%&'\*\+\-\/=\?\^_`\{\}\|~ \.]+$/,
           'fallback_header_field' => 'comments',
           'fallback_header_body' => ''}

def self.config_has_key?(key)
  @@config.has_key?(key)
end

def self.get_config(key)
  if @@config.has_key?(key)
    return @@config[key]
  else
    return nil
  end
end

def self.set_config(key, value)
  if @@config.has_key?(key)
    return @@config[key] = value
  else
    return nil
  end
end

def self.postmaster_from_yaml(filename)
  if File.exists?(filename)
    o = YAML.load(File.read(filename))
    return
  elsif config('strictness')
    raise "Cannot load object because file '#{filename}' does not exists!"
  end
end

def self.postmaster_from_marshal(filename)
  if File.exists?(filename)
    o = File.open(filename, 'rb') {|f| m = Marshal::load(f)}
    return o
  elsif config('strictness')
    raise "Cannot load object because file '#{filename}' does not exists!"
  end
end

def self.file_timestamp()
  return Time.now.to_s[0..18].gsub(":", "-")
end

def self.mail_timestamp()
  # ex. Thu, 13 Feb 1969 23:32:54 -0330
  return Time.now.strftime('%a, %d %b %Y %H:%M:%S %z')
end

def self.die(message)
  raise message << "
  For more info please visit: https://github.com/goobemaster/ruby-not-magic/circular-mail/"
end

class PostMaster
  public

  attr_accessor :smtp_server
  attr_accessor :smtp_server_port
  attr_accessor :smtp_server_username
  attr_accessor :smtp_server_password
  attr_accessor :smtp_server_authentication
  attr_accessor :message_format
  attr_accessor :message_character_set
  attr_accessor :message_body
  attr_reader :attachments
  attr_reader :recipients
  attr_accessor :mail_per_dispatch
  attr_accessor :wait_after_dispatch
  attr_accessor :sender
  attr_accessor :sender_email

  def config(key)
    if CircularMail::config_has_key?(key)
      return CircularMail::get_config(key)
    else
      return false
    end
  end

  def smtp_server=(server)
    if config('strictness')
      CircularMail::die "SMTP server name '#{server.to_s}' is invalid!" if /^([\w\-]+\.)+\w{2,}$/.match(server.to_s).nil?
    end
    @smtp_server = server.to_s
  end

  def smtp_server_port=(port)
    if config('strictness')
      CircularMail::die "SMTP server port '#{port.to_s}' is invalid!" if (port.to_i < 0 || port.to_i > 65535)
    end
    @smtp_server_port = port.to_i
  end

  def smtp_server_username=(username)
    if config('strictness')
      CircularMail::die "SMTP server username '#{username.to_s}' is invalid!" if /^\S+$/.match(username.to_s).nil?
    end
    @smtp_server_username = username
  end

  def smtp_server_password=(password)
    if config('strictness')
      CircularMail::die "SMTP server username '#{password.to_s}' is invalid!" if /^\S*$/.match(password.to_s).nil?
    end
    @smtp_server_password = password
  end

  def smtp_authentication=(auth_type)
    if config('strictness')
      CircularMail::die "Authentication type '#{auth_type}' is not a valid option!" unless config('valid_authentications').include?(auth_type)
    end
    @smtp_server_authentication = auth_type
  end

  def set_smtp_server(server_and_port, username, password, auth_type)
    self.smtp_server = server_and_port.to_s.split(":")[0]
    self.smtp_server_port = server_and_port.to_s.split(":")[1]
    self.smtp_server_username = username.to_s
    self.smtp_server_password = password.to_s
    self.smtp_server_authentication = auth_type.to_s
  end

  def set_message(format, message)
    self.message_format = format
    if File.exists?(message.to_s)
      self.message_body = File.read(message.to_s)
    else
      self.message_body = message
    end
  end

  def message_character_set=(charset)
    CircularMail::die "Message character set of '#{charset}' is not supported!" unless config('valid_charsets').has_key?(charset.to_s)
  end

  def message_body=(message_body)
    if config('strictness')
      CircularMail::die "Message must be a non-empty string!" if message_body.to_s.length == 0
    end
    @message_body = message_body.to_s
  end

  def message_format=(format)
    CircularMail::die "No such message format exists! Expected: #{config('valid_formats')}" unless config('valid_formats').include?(format.to_s)
    @message_format = format
  end

  def mail_per_dispatch=(secs)
    CircularMail::die 'Mail per dispatch value must be greater than zero!' if secs < 0
    @mail_per_dispatch = secs.to_i
  end

  def wait_after_dispatch=(secs)
    CircularMail::die 'Wait after dispatch value must be greater than zero!' if secs < 0
    @wait_after_dispatch = secs.to_i
  end

  def sender_email=(email)
    if config('strictness')
      CircularMail::die "Email address '#{email}' is invalid!" if config('email_validation').match(email).nil?
    end
    @sender_email = email
  end

  def add_recipient(*args)
    if config('strictness')
      CircularMail::die "Email address '#{args[0]}' already added to recipients list!" if @recipients.include?(args[0])
      CircularMail::die "Email address '#{args[0]}' is invalid!" if config('email_validation').match(args[0]).nil? && config('email_group_validation').match(args[0]).nil?
    end
    message_vars = []
    if args.length > 1
      (2..args.length).each { |var|
        message_vars << args[var - 1]
      }
    end
    @recipients << {args[0] => message_vars}
  end

  def remove_recipient(email)
    if @recipients.include?(email)
      @recipients.keep_if { |address| address != email}
    elsif config('strictness')
      CircularMail::die "Recipient list does not contain email address '#{email}' !"
    end
  end

  def set_message_variable(*args)
    # This method will add the email to recipients list if it does not exists yet!
    unless @recipients.include?(args[0])
      add_recipient(*args)
    else
      # Ok, email exists lets override whatever variables it has
      message_vars = []
      if args.length > 1
        (2..args.length).each { |var|
          message_vars << args[var - 1]
        }
      end
      @recipients[@recipients.index(args[0])] = message_vars
    end
  end
  alias :set_message_variables :set_message_variable

  def add_attachment(filename)
    if @attachments.include?(filename)
      CircularMail::die "Attachment '#{filename}' already added!" if config('strictness')
    else
      CircularMail::die "Attachment file '#{filename}' does not exists!" if config('strictness') && !File.exists?(filename)
      @attachments << filename
    end
  end

  def remove_attachment(filename)
    if @attachments.include?(filename)
      @attachments.keep_if { |file| file != filename}
    elsif config('strictness')
      CircularMail::die "Attachment list does not contain file '#{filename}' !"
    end
  end

  def save_as_yaml(filename)
    CircularMail::die "Cannot save object because file '#{filename}' already exists!" if File.exists?(filename) && config('strictness')
    filename = Dir.getwd() + "/dump #{CircularMail.file_timestamp()}.yaml" unless File.exists?(filename)
    File.open(filename, 'w') { |f| f.write(YAML.dump(self)) }
  end

  def save_as_marshal(filename)
    CircularMail::die "Cannot save object because file '#{filename}' already exists!" if File.exists?(filename) && config('strictness')
    filename = Dir.getwd() + "/dump #{CircularMail.file_timestamp()}.marshal" unless File.exists?(filename)
    File.open(filename, 'w') { |f| f.write(Marshal.dump(self)) }
  end

  # Start sending to all recipients using the standard process
  def send()
    self.save_as_yaml(Dir.getwd() + "/backup #{CircularMail.file_timestamp()}.yaml") if config('auto_backup')

    Net::SMTP.start(@smtp_server, @smtp_server_port, 'localhost', @smtp_server_username, @smtp_server_password, @smtp_server_authentication) do |smtp|
      #smtp.send_message msgstr, 'from@example.com', ['dest@example.com']
    end
  end
  alias :send_all :send

  # Send the message to a single recipient
  # Useful if a recipient is complaining that he did not get the message, due to a spam filter or accidentally deleted the email
  def send_to(email)

  end

  private

  # Args - server_name:port, server_username, server_password, server_authentication
  def initialize(*args)
    case args.length
      when 1
        set_smtp_server(args[0], config('default_username'), config('default_password'), config('default_authentication'))
      when 2
        set_smtp_server(args[0], args[1], config('default_password'), config('default_authentication'))
      when 3
        set_smtp_server(args[0], args[1], args[2], config('default_authentication'))
      when 4
        set_smtp_server(args[0], args[1], args[2], args[3])
      else
        set_smtp_server("#{config('default_server')}:#{config('default_port').to_s}", config('default_username'), config('default_password'), config('default_authentication'))
    end
    self.message_format = config('default_format')
    self.message_body = config('default_body')
    self.message_character_set = config('default_charset')
    self.mail_per_dispatch = config('default_mail_per_dispatch')
    self.wait_after_dispatch = config('default_wait_after_dispatch')
    self.sender_email = config('default_sender_email')
    @recipients = config('recipients')
    @attachments = config('attachments')
    @sender = config('default_sender')
  end

  # static
  # TODO: Load from file and COPY the properties over

  def CircularMail.from_yaml(filename)
    if File.exists?(filename)
      #o = YAML.load(File.read(filename))
    elsif config('strictness')
      CircularMail::die "Cannot load object because file '#{filename}' does not exists!"
    end
  end

  def CircularMail.from_marshal(filename)
    if File.exists?(filename)
      #o = File.open(filename, 'rb') {|f| m = Marshal::load(f)}
    elsif config('strictness')
      CircularMail::die "Cannot load object because file '#{filename}' does not exists!"
    end
  end

end

class Message

end

class Header
  public

  attr_reader :fields

  def initialize(*args)
    case args.length
      when 1

      when 2
    end
    @field = CircularMail::HeaderField
  end
end

class HeaderField
  public

  attr_reader :name
  attr_reader :body

  def set(name, body)
    case name
      when 'From'       # from
        CircularMail::die("Inappropriate value for 'From' header field!") if config('strictness') && config('header_address_validation').match(body).nil?
      when 'Sender'     # sender
        CircularMail::die("Inappropriate value for 'Sender' header field!") if config('strictness') && config('email_validation').match(body).nil?
      when 'Reply-To'   # reply-to
        CircularMail::die("Inappropriate value for 'Reply-To' header field!") if config('strictness') && config('email_validation').match(body).nil?
      when 'To'         # to
        CircularMail::die("Inappropriate value for 'From' header field!") if config('strictness') && config('header_address_validation').match(body).nil?
      when 'Cc'         # cc
        CircularMail::die("Inappropriate value for 'Cc' header field!") if config('strictness') && config('header_address_validation').match(body).nil?
      when 'Bcc'        # bcc
        CircularMail::die("Inappropriate value for 'Bcc' header field!") if config('strictness') && config('header_address_validation').match(body).nil?
      when 'Message-ID' # message-id
        CircularMail::die("Inappropriate value for 'Message-ID' header field!") if config('strictness') && config('header_msgid_validation').match(body).nil?
      when 'Subject'    # subject unstructured
        CircularMail::die("Inappropriate value for 'Subject' header field!") if config('strictness') && config('header_unstructured_validation').match(body).nil?
      when 'Comments'   # comments unstructured
        CircularMail::die("Inappropriate value for 'Comments' header field!") if config('strictness') && config('header_unstructured_validation').match(body).nil?
      when 'Date'       # orig-date
        CircularMail::die("Inappropriate value for 'Message-ID' header field!") if config('strictness') && config('header_date_validation').match(body).nil?
      else
        if config('strictness')
          CircularMail::die("Unsupported header field! Expected: #{config('valid_header_fields')}") unless config('valid_header_fields').include?(name)
        else
          name = config('fallback_header_field')
          body = config('fallback_header_body')
        end
    end
    if config('strictness')
      CircularMail::die("Header field body cannot contain CR, LF characters! (Don't worry, its appended automatically)") if body.include?("\r") || body.include?("\n")
    else
      body.gsub!("\r", "")
      body.gsub!("\n", "")
    end
    @name = name
    @body = body
  end

  def to_s()
    return "#{@name}:#{@body}\r\n"
  end
  alias :get :to_s

  private

  def initialize(name, body)
    self.set(name, body)
  end
end

end