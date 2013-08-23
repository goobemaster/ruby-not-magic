# Cucumber feature file to html converter
# Author: gabor.major@csn.hu

require "cgi"

wd = Dir.pwd + '/'
feature_file = wd + ARGV[0]
output_file = File.open(wd + 'feature_to_html_output.html', 'w')
section = ''
ln = 0

# File.delete(output_file) if File.exists?(output_file)
raise 'The given feature file does not exists!' if !File.exists?(feature_file)
output_file.write('<p><b>Filename:</b> ' + ARGV[0] + '</p>')

def line_type?(line)
  return 'tags' if /^ *(@.+){1,}/i.match(line)
  return 'feature' if /^ *Feature:/i.match(line)
  return 'scenario outline' if /^ *Scenario Outline:/i.match(line)
  return 'step' if /^ *(Given|When|Then|And)/i.match(line)
  return 'br' if /^ *$/.match(line)
  return 'example table' if /(\|.*){2,}/.match(line)
  return 'examples' if /^ *Examples:/i.match(line)
  return 'default'
end

def line_number(ln)
  return '<div style="width:40px;display:inline;text-align:right;font-size:10px;margin-right:10px;">' + ln.to_s + '</div>'
end

class String
  def escape
    return CGI::escapeHTML(self.to_s)
  end
  def escape!
    replace(CGI::escapeHTML(self.to_s))
  end
end

File.open(feature_file, 'r') do |f|
  f.each_line do |line|
    ln += 1
    case line_type?(line)
      when 'br'
        output_file.write('<br/>')
      when 'tags'
        output_file.write(line_number(ln) + '<b style="color:darkviolet">' + line.escape + '</b><br/>')
        section = 'tags'
      when 'feature'
        line.escape!
        line.gsub!(/Feature:/i, '<span style="color:blue">Feature:</span>')
        output_file.write(line_number(ln) + '<b>' + line  + '</b><br/>')
        section = 'feature'
      when 'scenario outline'
        line.escape!
        line.gsub!(/Scenario Outline:/i, '<span style="color:blue">Scenario Outline:</span>')
        output_file.write(line_number(ln) + '<b>' + line  + '</b><br/>')
        section = 'scenario'
      when 'step'
        line.escape!
        line.gsub!(/Given/, '<b style="color:blue">Given</b>')
        line.gsub!(/When/, '<b style="color:blue">When</b>')
        line.gsub!(/Then/, '<b style="color:blue">Then</b>')
        line.gsub!(/And/, '<b style="color:blue">And</b>')
        line.gsub!('&lt;', '<b style="color:orange">&lt;')
        line.gsub!('&gt;', '&gt;</b>')
        output_file.write(line_number(ln) + '&nbsp;&nbsp;' + line + '<br/>')
      when 'example table'
        line.escape!
        line.gsub!('&lt;', '<b style="color:orange">&lt;')
        line.gsub!('&gt;', '&gt;</b>')
        output_file.write(line_number(ln) + '<pre style="display:inline">' + line + '</pre>')
      when 'examples'
        output_file.write(line_number(ln) + line.escape.gsub(/Examples:/i, '<b style="color:blue">&nbsp;&nbsp;Examples:</b>') + '<br/>')
      else
        line.escape!
        line.gsub!(/In order to/i, '<b style="color:blue">In order to</b>')
        line.gsub!(/As a/i, '<b style="color:blue">As a</b>')
        line.gsub!(/I want/i, '<b style="color:blue">I want</b>')
        line.gsub!(/I would/i, '<b style="color:blue">I would</b>')
        line.gsub!(/On the/i, '<b style="color:blue">On the</b>')
        line.gsub!(/^ *The/i, '<b style="color:blue">The</b>')
        output_file.write(line_number(ln) + '<i style="color:grey">&nbsp;&nbsp;' + line + '</i><br/>')
    end
  end
end

output_file.close()