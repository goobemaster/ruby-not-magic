# encoding: UTF-8

module CircularMail

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
      return [what].pack('A*')
    when 'quoted-printable'
      return [what].pack('M*')
    when 'base64'
      return [what].pack('m*')
    when 'ietf-token'
      body = ''
    when 'x-token'
      body = ''
  end
end

def self.check_charset(what, charset)
  case charset
    when 'us-ascii', 'ascii'
      what.scan(/./).map(&:ord).each { |byte|
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

def self.file_get_contents(filename)
  c = ""
  if File.exists?(filename)
    File.open(filename, 'rb') { |io| c += io.read }
    return c
  else
    return nil
  end
end

def self.file_content_type?(filename)
  ext = File.extname(filename).gsub!(".", "").downcase
  if @@mime.has_key?(ext)
    return @@mime[ext]
  else
    return 'application/octet-stream'
  end
end

def self.die(message)
  raise message << "
  For more info please visit: https://github.com/goobemaster/ruby-not-magic/circular-mail/"
end

end