require 'rubygems'
require 'json'
require 'time'
require 'pp'

@@repo = 'repo/wiki'
@@date = Time.now.to_i*1000


# wiki utilities

def random
  (1..16).collect {(rand*16).floor.to_s(16)}.join ''
end

def slug title
  title.gsub(/\s/, '-').gsub(/[^A-Za-z0-9-]/, '').downcase()
end

def clean text
  text.gsub(/’/,"'")
end

def url text
  text.gsub(/(http:\/\/)?([a-zA-Z0-9._-]+?\.(net|com|org|edu)(\/[^ )]+)?)/,'[http:\/\/\2 \2]')
end

def domain text
  text.gsub(/((https?:\/\/)(www\.)?([a-zA-Z0-9._-]+?\.(net|com|org|edu|us|cn|dk|au))(\/[^ );]*)?)/,'[\1 \4]')
end

def titalize text
  excluded = %w(the and in of for at to)
  text.gsub(/[\w']+/m) do |word|
      excluded.include?(word) ? word : word.capitalize
  end
end


# journal actions

def create title
  @journal << {'type' => 'create', 'id' => random, 'item' => {'title' => title}, 'date' => @@date}
end

def add item
  @story << item
  @journal << {'type' => 'add', 'id' => item['id'], 'item' => item, 'date' => @@date}
end


# story emiters

def paragraph text
  return if text =~ /^\s*$/
  text.gsub! /\r\n/, "\n"
  add({'type' => 'paragraph', 'text' => text, 'id' => random()})
end

def pagefold text
  text.gsub! /\r\n/, ""
  add({'type' => 'pagefold', 'text' => text, 'id' => random()})
end

def trimx str
  puts str
  "mumble"
end

def markdown text
  lines = text.split /(\r\n)+/m
  lines.each do |line|
    line.gsub! /```(.+?)```/, '<b>\1</b>'
    line.gsub! /`(.+?)`/, '<b>\1</b>'
    line.gsub! /https?:\/\/\S+/, '[\0 \0]'
    line.gsub! /WardCunningham\/\S+?#\d+/, '[https://github.com/\0 \0]'
    line.gsub! /([0-9a-f]{7})[0-9a-f]{9,}/, '[https://github.com/wardcunningham/wiki/commit/\0 \1]'
    line.gsub! /##+/, '<h3>'
    paragraph line
  end
end

def page title
  @story = []
  @journal = []
  create title
  yield
  page = {'title' => title, 'story' => @story, 'journal' => @journal}
  File.open("#{@@repo}/pages/#{slug(title)}", 'w') do |file|
    file.write JSON.pretty_generate(page)
  end
end


# github api json

def issue filename
  head, json =  File.read(filename).split(/\r\n\r\n/m)
  body = JSON.parse json
  body.each do |issue|
    next if issue['pull_request']['patch_url']
    @@date = Time.parse(issue['updated_at']).to_i * 1000
    page titalize issue['title'] do
      pagefold "#{issue['state']} issue ##{issue['number']} by #{issue['user']['login']}"
      markdown issue['body']
      paragraph "See issue in [#{issue['html_url']} github]"
    end
  end
  puts "\n"
  pp body.last
end


issue "#{@@repo}/issues-open"
issue "#{@@repo}/issues-closed"
