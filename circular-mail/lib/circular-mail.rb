# encoding: UTF-8

# Circular-Mail Library 0.0.1
# =================================================================================================
#      Author: gabor.major@csn.hu
#      Github: https://github.com/goobemaster/ruby-not-magic/circular-mail/
#    Rubygems: http://rubygems.org/gems/circular-mail
# Description: Mass email sending through smtp. Highly configurable, feature rich, robust solution.
#              Follows standards laid out in RFC-2822 (http://tools.ietf.org/html/rfc2822)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# =================================================================================================

$LOAD_PATH << './'

module CircularMail

require 'net/smtp'
require 'yaml'
require 'digest/md5'
require 'mime.rb'
require 'config.rb'
require 'common.rb'

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
    unless @recipients.include?(args[0])   #TODO: fix me! Need to look for email address INSIDE hash!
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
    messages_sent = 0
    messages_dispatch = 0

    Net::SMTP.start(@smtp_server, @smtp_server_port, 'localhost', @smtp_server_username, @smtp_server_password, @smtp_server_authentication) do |smtp|
      message_index = 0
      message_body_personal = ""

      @recipients.each { |recipient|
        message_index += 1
        to_email = ""

        recipient.each { |mail, vars|
          to_email = mail
          var_index = 0
          message_body_personal = @message_body
          if vars.length > 0
            vars.each { |var_value|
              var_index += 1
              message_body_personal = message_body_personal.gsub("@#{var_index.to_s}@", var_value)
            }
          else
            message_body_personal = @message_body
          end
        }

        message = CircularMail::Message.new(@message_format, @message_character_set, message_body_personal)
        message.attachments = @attachments
        message.header.add_field('From', "#{@sender}<#{@sender_email}>")
        message.header.add_field('Sender', "#{@sender}<#{@sender_email}>")
        message.header.add_field('Reply-To', @sender_email)
        message.header.add_field('To', "<#{to_email}>")
        message.header.add_field('Subject', @subject)
        message.header.add_field('Comments', 'This email was generated and posted by the CircularMail ruby library. Author is not responsible for body content!')
        message.header.add_field('Date', CircularMail::mail_timestamp())
        $message_id = Digest::MD5.hexdigest(message_body_personal)
        message.header.add_field('Message-ID', "<CircularMail@#{$message_id}>")

        full_message = message.get()

        smtp.send_message full_message, @sender_email, to_email

        messages_sent += 1
        messages_dispatch += 1
        if messages_dispatch == @mail_per_dispatch
          sleep @wait_after_dispatch
          messages_dispatch = 0
        end
      }
    end
    return messages_sent
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
    unless CircularMail::check_charset(body, @character_set)
      CircularMail::die("Message body contains one or more characters which are not part of '#{@character_set}' !") if CircularMail::config('strictness')
    end
    @body = body
  end

  def attachments=(file_list)
    CircularMail::die("Attachment list must be composed of filenames in an array!") if file_list.class.to_s != "Array"
    @attachments = file_list
  end

  def get()
    if @header.fields.length > 0
      CircularMail::die("Date and From header fields must be present in the message as per RFC-2822!") if !@header.present?('Date') || !@header.present?('From')
      @header.add_field('Content-Transfer-Encoding', 'base64') unless header.present?('Content-Transfer-Encoding')
      message_body = CircularMail::encode(@body, @header.get_field('Content-Transfer-Encoding'))

      if @format == 'text'
        content_type = 'text/plain'
      else
        content_type = 'text/html'
      end

      if @attachments.length == 0
        @header.add_field('Content-Type', "#{content_type};charset=#{@character_set}")
        return "#{@header.get()}\r\n#{message_body}"
      else
        @header.add_field('MIME-Version', '1.0')
        @header.add_field('Content-Type', "multipart/mixed; boundary=#{$message_id}")
        message_body = "Content-Type:#{content_type}\r\nContent-Transfer-Encoding:base64\r\n\r\n#{message_body}--#{$message_id}"
        return "#{@header.get()}\r\n--#{$message_id}\r\n#{message_body}\r\n#{attachments_body()}"
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

  def attachments_body()
    attachment_body = ""
    index = 0
    @attachments.each { |filename|
      if File.exists?(filename)
        index += 1
        a_body = CircularMail::encode(CircularMail::file_get_contents(filename), 'base64')
        a_header = CircularMail::Header.new()
        a_header.add_field('Content-Type', "#{CircularMail::file_content_type?(filename)};charset=#{@character_set}")
        a_header.add_field('Content-Transfer-Encoding', 'base64')
        a_header.add_field('Content-Disposition', "attachment;filename=\"#{File.basename(filename)}\"")
        attachment_body << "#{a_header.get()}\r\n#{a_body}"
        if index != @attachments.length
          attachment_body << "--#{$message_id}\r\n"
        else
          attachment_body << "--#{$message_id}--"
        end
      end
    }
    return attachment_body
  end

end

# Description: This object can store 16 selected header fields, which are mandatory for CircularMail.
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
        CircularMail::die("Inappropriate value for 'To' header field!") if CircularMail::config('strictness') && CircularMail::config('header_address_validation').match(body).nil?
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
        CircularMail::die("Inappropriate value for 'Content-Description' header field!") if CircularMail::config('strictness') && !CircularMail::check_charset(body, 'us-ascii')
      when 'Content-Disposition'
        CircularMail::die("Inappropriate value for 'Content-Disposition' header field!") if CircularMail::config('strictness') && !CircularMail::check_charset(body, 'us-ascii')
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

  def remove_all_fields()
    @fields = []
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

  def duplicate_header?(name)
    if @fields.length > 0
      @fields.each { |field|
        return true if field.name == name
      }
    end
    false
  end
  alias :present? :duplicate_header?

  private

  def initialize()
    @fields = []
  end
end

end