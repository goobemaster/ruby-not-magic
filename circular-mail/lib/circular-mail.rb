# encoding: UTF-8

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
           'character_limit_text' => 78,
           'default_body' => "Dear @1@,\n\nPlease be informed that...\nYour custom string is: '@2@'\n\nKind Regards,\nAnonymous",
           'default_subject' => 'Your unique string',
           'default_sender' => '',
           'default_sender_email' => 'mail@default.com',
           'email_validation' => /^[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+(?:\.[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/,
           'email_group_validation' => /^<[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+>$/,
           'recipients' => [],
           'attachments' => [],
           'undefined_variable' => '(?!)',
           'default_mail_per_dispatch' => 5,
           'default_wait_after_dispatch' => 3,
           'auto_backup_postmaster' => true,
           'cr' => 13,
           'lf' => 10,
           'header_date_validation' => /^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), [0-9]{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} (\+|\-)[0-9]{4}$/,
           'valid_header_fields' => ['From', 'Sender', 'Reply-To', 'To', 'Cc', 'Bcc', 'Message-ID', 'Subject', 'Comments', 'Date'],
           'header_address_validation' => /^[a-zA-Z ]*<[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+(?:\.[a-z0-9!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?>$/,
           'header_msgid_validation' => /^<([a-zA-Z0-9!#\$%&'\*\+\-\/=\?\^_`\{\}\|~]+\.?)+@([a-zA-Z0-9!#\$%&'\*\+\-\/=\?\^_`\{\}\|~]+\.?)+>$/,
           'header_unstructured_validation' => /^[a-zA-Z0-9!#\$%&'\*\+\-\/=\?\^_`\{\}\|~ \.]+$/,
           'header_content_type_validation' => /^[a-z]+\/[a-z]+;[ ]*charset=("[a-z\-]+"|[a-z\-]+)$/i,
           'header_content_encoding_validation' => /^7bit|8bit|binary|quoted-printable|base64|ietf-token|x-token$/i,
           'fallback_header_field' => 'comments',
           'fallback_header_body' => ''}

def self.config_has_key?(key)
  @@config.has_key?(key)
end

def self.config(key)
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
    return o
  elsif config('strictness')
    die "Cannot load object because file '#{filename}' does not exists!"
  end
end

def self.postmaster_from_marshal(filename)
  if File.exists?(filename)
    o = File.open(filename, 'rb') {|f| m = Marshal::load(f)}
    return o
  elsif config('strictness')
    die "Cannot load object because file '#{filename}' does not exists!"
  end
end

def self.file_timestamp()
  return Time.now.to_s[0..18].gsub(":", "-")
end

def self.mail_timestamp()
  # ex. Thu, 13 Feb 1969 23:32:54 -0330
  return Time.now.strftime('%a, %d %b %Y %H:%M:%S %z')
end

def self.encode(what, how)
  case how
    when '7bit'
      body = ''
    when '8bit'
      body = ''
    when 'binary'
      body = ''
    when 'quoted-printable'
      return what.split("").pack('M*')
    when 'base64'
      return what.split("").pack('m*')
    when 'ietf-token'
      body = ''
    when 'x-token'
      body = ''
  end
end

def self.check_charset(what, charset)
  case charset
    when 'us-ascii', 'ascii'
      what.scan(/./).map(&:to_i).pack('C*').each_byte { |byte|
        puts byte.to_s
        return false unless config('valid_charsets')[charset].include?(byte)
      }
      return true
    when 'utf-8'
      return what.force_encoding("UTF-8").valid_encoding?
    else
      die "Cannot check this kind of character set on target string!" if config('strictness')
      return nil
  end
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
  attr_accessor :message_subject
  attr_reader :attachments
  attr_reader :recipients
  attr_accessor :mail_per_dispatch
  attr_accessor :wait_after_dispatch
  attr_accessor :sender
  attr_accessor :sender_email

  def smtp_server=(server)
    if CircularMail::config('strictness')
      CircularMail::die "SMTP server name '#{server.to_s}' is invalid!" if /^([\w\-]+\.)+\w{2,}$/.match(server.to_s).nil?
    end
    @smtp_server = server.to_s
  end

  def smtp_server_port=(port)
    if CircularMail::config('strictness')
      CircularMail::die "SMTP server port '#{port.to_s}' is invalid!" if (port.to_i < 0 || port.to_i > 65535)
    end
    @smtp_server_port = port.to_i
  end

  def smtp_server_username=(username)
    if CircularMail::config('strictness')
      CircularMail::die "SMTP server username '#{username.to_s}' is invalid!" if /^\S+$/.match(username.to_s).nil?
    end
    @smtp_server_username = username
  end

  def smtp_server_password=(password)
    if CircularMail::config('strictness')
      CircularMail::die "SMTP server username '#{password.to_s}' is invalid!" if /^\S*$/.match(password.to_s).nil?
    end
    @smtp_server_password = password
  end

  def smtp_authentication=(auth_type)
    if CircularMail::config('strictness')
      CircularMail::die "Authentication type '#{auth_type}' is not a valid option!" unless CircularMail::config('valid_authentications').include?(auth_type)
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

  def set_message(format, subject, message)
    self.message_format = format
    if File.exists?(message.to_s)
      self.message_body = File.read(message.to_s)
    else
      self.message_body = message
    end
    @subject = subject
  end

  def message_character_set=(charset)
    CircularMail::die "Message character set of '#{charset}' is not supported!" unless CircularMail::config('valid_charsets').has_key?(charset.to_s)
    @message_character_set = charset
  end

  def message_body=(message_body)
    if CircularMail::config('strictness')
      CircularMail::die "Message must be a non-empty string!" if message_body.to_s.length == 0
    end
    @message_body = message_body.to_s
  end

  def message_format=(format)
    CircularMail::die "No such message format exists! Expected: #{CircularMail::config('valid_formats')}" unless CircularMail::config('valid_formats').include?(format.to_s)
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
    if CircularMail::config('strictness')
      CircularMail::die "Email address '#{email}' is invalid!" if CircularMail::config('email_validation').match(email).nil?
    end
    @sender_email = email
  end

  def add_recipient(*args)
    if CircularMail::config('strictness')
      CircularMail::die "Email address '#{args[0]}' already added to recipients list!" if @recipients.include?(args[0])
      CircularMail::die "Email address '#{args[0]}' is invalid!" if CircularMail::config('email_validation').match(args[0]).nil? && CircularMail::config('email_group_validation').match(args[0]).nil?
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
    elsif CircularMail::config('strictness')
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
      CircularMail::die "Attachment '#{filename}' already added!" if CircularMail::config('strictness')
    else
      CircularMail::die "Attachment file '#{filename}' does not exists!" if CircularMail::config('strictness') && !File.exists?(filename)
      @attachments << filename
    end
  end

  def remove_attachment(filename)
    if @attachments.include?(filename)
      @attachments.keep_if { |file| file != filename}
    elsif CircularMail::config('strictness')
      CircularMail::die "Attachment list does not contain file '#{filename}' !"
    end
  end

  # Start sending to all recipients using the standard process
  def send()
    self.save_as_yaml(Dir.getwd() + "/backup #{CircularMail.file_timestamp()}.yaml") if CircularMail::config('auto_backup_postmaster')

    Net::SMTP.start(@smtp_server, @smtp_server_port, 'localhost', @smtp_server_username, @smtp_server_password, @smtp_server_authentication) do |smtp|
      #smtp.send_message msgstr, 'from@example.com', ['dest@example.com']
    end
  end
  alias :send_all :send

  # Send the message to a single recipient
  # Useful if a recipient is complaining that he did not get the message, due to a spam filter or accidentally deleted the email
  def send_to(email)

  end

  def save_as_yaml(filename)
    CircularMail::die "Cannot save object because file '#{filename}' already exists!" if File.exists?(filename) && CircularMail::config('strictness')
    filename = Dir.getwd() + "/dump #{CircularMail.file_timestamp()}.yaml" unless File.exists?(filename)
    File.open(filename, 'w') { |f| f.write(YAML.dump(self)) }
  end

  def save_as_marshal(filename)
    CircularMail::die "Cannot save object because file '#{filename}' already exists!" if File.exists?(filename) && CircularMail::config('strictness')
    filename = Dir.getwd() + "/dump #{CircularMail.file_timestamp()}.marshal" unless File.exists?(filename)
    File.open(filename, 'w') { |f| f.write(Marshal.dump(self)) }
  end

  def load_from_yaml(filename)
    if File.exists?(filename)
      o = YAML.load(File.read(filename))
      @smtp_server = o.smtp_server
      @smtp_server_port = o.smtp_server_port
      @smtp_server_username = o.smtp_server_username
      @smtp_server_password = o.smtp_server_password
      @smtp_server_authentication = o.smtp_server_password
      @message_format = o.smtp_server_password
      @message_character_set = o.smtp_server_password
      @message_body = o.smtp_server_password
      @message_subject = o.smtp_server_password
      @attachments = o.smtp_server_password
      @recipients = o.smtp_server_password
      @mail_per_dispatch = o.smtp_server_password
      @wait_after_dispatch = o.smtp_server_password
      @sender = o.smtp_server_password
      @sender_email = o.smtp_server_password
    elsif CircularMail::config('strictness')
      CircularMail::die "Cannot load object because file '#{filename}' does not exists!"
    end
  end

  def load_from_marshal(filename)
    if File.exists?(filename)
      o = File.open(filename, 'rb') {|f| m = Marshal::load(f)}
      @smtp_server = o.smtp_server
      @smtp_server_port = o.smtp_server_port
      @smtp_server_username = o.smtp_server_username
      @smtp_server_password = o.smtp_server_password
      @smtp_server_authentication = o.smtp_server_password
      @message_format = o.smtp_server_password
      @message_character_set = o.smtp_server_password
      @message_body = o.smtp_server_password
      @message_subject = o.smtp_server_password
      @attachments = o.smtp_server_password
      @recipients = o.smtp_server_password
      @mail_per_dispatch = o.smtp_server_password
      @wait_after_dispatch = o.smtp_server_password
      @sender = o.smtp_server_password
      @sender_email = o.smtp_server_password
    elsif CircularMail::config('strictness')
      CircularMail::die "Cannot load object because file '#{filename}' does not exists!"
    end
  end

  private

  # Args - server_name:port, server_username, server_password, server_authentication
  def initialize(*args)
    case args.length
      when 1
        set_smtp_server(args[0], CircularMail::config('default_username'), CircularMail::config('default_password'), CircularMail::config('default_authentication'))
      when 2
        set_smtp_server(args[0], args[1], CircularMail::config('default_password'), CircularMail::config('default_authentication'))
      when 3
        set_smtp_server(args[0], args[1], args[2], CircularMail::config('default_authentication'))
      when 4
        set_smtp_server(args[0], args[1], args[2], args[3])
      else
        set_smtp_server("#{CircularMail::config('default_server')}:#{CircularMail::config('default_port').to_s}", CircularMail::config('default_username'), CircularMail::config('default_password'), CircularMail::config('default_authentication'))
    end
    self.message_format = CircularMail::config('default_format')
    self.message_body = CircularMail::config('default_body')
    self.message_character_set = CircularMail::config('default_charset')
    self.mail_per_dispatch = CircularMail::config('default_mail_per_dispatch')
    self.wait_after_dispatch = CircularMail::config('default_wait_after_dispatch')
    self.sender_email = CircularMail::config('default_sender_email')
    @recipients = CircularMail::config('recipients')
    @attachments = CircularMail::config('attachments')
    @sender = CircularMail::config('default_sender')
    @subject = CircularMail::config('default_subject')
  end
end

class Message
  public

  attr_accessor :header
  attr_accessor :body
  attr_accessor :format
  attr_accessor :character_set
  attr_accessor :attachments

  def format=(format)
    if CircularMail::config('valid_formats').include?(format.to_s)
      @format = format
    else
      @format = CircularMail::config('default_format')
    end
  end

  def character_set=(charset)
    if CircularMail::config('valid_charsets').has_key?(charset.to_s)
      @character_set = charset
    else
      @character_set = CircularMail::config('default_charset')
    end
  end

  def body=(body)
    if CircularMail::config('strictness')
      unless body.empty?
        if @format == 'text'
          char_limit = CircularMail::config('character_limit_text')
        elsif @format == 'html'
          char_limit = CircularMail::config('character_limit')
        end
        body.each_line { |line|
          CircularMail::die("Each line of body text *should not* be longer than #{char_limit} characters!") if line.length > char_limit
        }
      end
    end
    @body = body
  end

  def attachments=(file_list)
    CircularMail::die("Attachment list must be composed of filenames in an array!") unless file_list.kind_of?([])
    @attachments = file_list
  end

  def get()
    if header.fields.length > 0
      if attachments.length == 0
        # TODO: Check for other header fields requirements as well
        CircularMail::die("Date and From header fields must be present in the message as per RFC-2822!") if !header.present?('Date') || !header.present?('From')
        if header.present?('Content-Transfer-Encoding')
          body = CircularMail::encode(@body, header.get_field('Content-Transfer-Encoding'))
        else
          body = @body
        end
        return "#{@header.get()}\r\n\r\n#{body}"
      else
        header.add_field('MIME-Version', '1.0')
        # TODO: Message type VS charset
        header.add_field('Content-Type', '')
        header.add_field('Content-Transfer-Encoding', 'base64')
      end
    else
      CircularMail::die("Cannot generate message, because lack of header fields!") if CircularMail::config('strictness')
      return nil
    end
  end

  private

  def initialize(*args)
    case args.length
      when 1
        self.format = args[0]
        self.character_set = CircularMail::config('default_charset')
        @body = CircularMail::config('default_body')
      when 2
        self.format = args[0]
        self.character_set = args[1]
        @body = CircularMail::config('default_body')
      when 3
        self.format = args[0]
        self.character_set = args[1]
        @body = args[2]
      else
        self.format = CircularMail::config('default_format')
        self.character_set = CircularMail::config('default_charset')
        @body = CircularMail::config('default_body')
    end

    @header = CircularMail::Header.new()
    @attachments = []
  end

end

# Description: This object can store 15 selected header fields, which are mandatory for CircularMail.
#              Validation of field values is happening in this class, rather than in Header. This is due to keep Header clean.
class HeaderField
  public

  attr_reader :name
  attr_reader :body

  def set(name, body)
    case name
      when 'From'       # from
        CircularMail::die("Inappropriate value for 'From' header field!") if CircularMail::config('strictness') && CircularMail::config('header_address_validation').match(body).nil?
      when 'Sender'     # sender
        CircularMail::die("Inappropriate value for 'Sender' header field!") if CircularMail::config('strictness') && CircularMail::config('header_address_validation').match(body).nil?
      when 'Reply-To'   # reply-to
        CircularMail::die("Inappropriate value for 'Reply-To' header field!") if CircularMail::config('strictness') && CircularMail::config('email_validation').match(body).nil?
      when 'To'         # to
        CircularMail::die("Inappropriate value for 'From' header field!") if CircularMail::config('strictness') && CircularMail::config('header_address_validation').match(body).nil?
      when 'Cc'         # cc
        CircularMail::die("Inappropriate value for 'Cc' header field!") if CircularMail::config('strictness') && CircularMail::config('header_address_validation').match(body).nil?
      when 'Bcc'        # bcc
        CircularMail::die("Inappropriate value for 'Bcc' header field!") if CircularMail::config('strictness') && CircularMail::config('header_address_validation').match(body).nil?
      when 'Message-ID' # message-id
        CircularMail::die("Inappropriate value for 'Message-ID' header field!") if CircularMail::config('strictness') && CircularMail::config('header_msgid_validation').match(body).nil?
      when 'Subject'    # subject unstructured
        CircularMail::die("Inappropriate value for 'Subject' header field!") if CircularMail::config('strictness') && CircularMail::config('header_unstructured_validation').match(body).nil?
      when 'Comments'   # comments unstructured
        CircularMail::die("Inappropriate value for 'Comments' header field!") if CircularMail::config('strictness') && CircularMail::config('header_unstructured_validation').match(body).nil?
      when 'Date'       # orig-date
        CircularMail::die("Inappropriate value for 'Message-ID' header field!") if CircularMail::config('strictness') && CircularMail::config('header_date_validation').match(body).nil?
      when 'MIME-Version'
        CircularMail::die("Only MIME 1.0 is supported in CircularMail!") if CircularMail::config('strictness') && body != '1.0'
      when 'Content-Type'
        CircularMail::die("Inappropriate value for 'Content-Type' header field!") if CircularMail::config('strictness') && CircularMail::config('header_content_type_validation').match(body).nil?
      when 'Content-Transfer-Encoding'
        CircularMail::die("Inappropriate value for 'Content-Transfer-Encoding' header field!") if CircularMail::config('strictness') && CircularMail::config('header_content_encoding_validation').match(body).nil?
      when 'Content-ID'
        CircularMail::die("Inappropriate value for 'Content-ID' header field!") if CircularMail::config('strictness') && CircularMail::config('header_msgid_validation').match(body).nil?
      when 'Content-Description'

      else
        if CircularMail::config('strictness')
          CircularMail::die("Unsupported header field! Expected: #{CircularMail::config('valid_header_fields')}") unless CircularMail::config('valid_header_fields').include?(name)
        else
          name = CircularMail::config('fallback_header_field')
          body = CircularMail::config('fallback_header_body')
        end
    end

    if CircularMail::config('strictness')
      CircularMail::die("Header field body cannot contain CR, LF characters! (Don't worry, it will be appended automatically)") if body.include?("\r") || body.include?("\n")
    else
      body.gsub!("\r", "")
      body.gsub!("\n", "")
    end

    @name = name
    @body = body
  end

  def get()
    return "#{@name}:#{@body}\r\n"
  end

  private

  def initialize(name = 'Comments', body = ' ')
    set(name, body)
  end
end

# Description: Basically holds an array of HeaderField objects.
#              You can add, modify, remove fields, then get the whole header as a string by calling to_s (alias: get)
class Header
  public

  attr_reader :fields

  def add_field(name, body)
    CircularMail.die("Although RFC-2822 allows multiple header fields of the same type, it *should* be avoided!") if duplicate_header?(name) && CircularMail::config('strictness')
    field = CircularMail::HeaderField.new(name, body)
    @fields.push(field)
  end

  def modify_field(name, body)
    if @fields.length > 0
      index = @fields.index{ |field| field.name == name}
      @fields[index] = CircularMail::HeaderField.new(name, body) if index > -1 && index < @fields.size
    end
  end

  def remove_field(name)
    if @fields.length > 0
      @fields.keep_if { |field| field.name != name}
    end
  end

  def get()
    head = ""
    if @fields.length > 0
      @fields.each { |field|
        head << field.get()
      }
    end
    return head
  end

  def get_field(name)
    if @fields.length > 0
      @fields.each { |field|
        return field.body if field.name == name
      }
    end
    return nil
  end

  private

  def initialize()
    @fields = []
  end

  def duplicate_header?(name)
    if @fields.length > 0
      @fields.each { |field|
        return true if field.name == name
      }
    end
    false
  end
  alias :present? :duplicate_header?
end

end

puts CircularMail::check_charset("test", "us-ascii")