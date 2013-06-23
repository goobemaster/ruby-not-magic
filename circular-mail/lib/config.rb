module CircularMail

@@config = {'strictness' => true,
           'default_server' => 'mail.server.com',
           'default_port' => 25,
           'default_username' => 'guest',
           'default_password' => '',
           'default_authentication' => 'plain',
           'valid_authentications' => ['plain', 'login', 'cram_md5'],
           'valid_formats' => ['text', 'html'],
           'valid_charsets' => {'us-ascii' => 33..126, 'ascii' => 1..255, 'utf-8' => 1..1114111},
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
           'header_content_type_validation' => /^[a-z0-9\-]+\/[a-z0-9\-]+;[ ]*charset=("[a-z0-9\-]+"|[a-z0-9\-]+)$/i,
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

end