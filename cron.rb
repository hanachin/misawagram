# -*- coding: utf-8 -*-
require "rubygems"
require "bundler/setup"

require 'json'
require 'haml'
require 'mechanize'

# returns the interpolated URL
def misawa_url(eid)
  "http://jigokuno.com/?eid=#{eid}"
end

agent = Mechanize.new

puts "get misawa top page"
agent.get('http://jigokuno.com/')

puts "get categories"
categories = agent.page.search('//dd//a[contains(@href, "./?cid=")]')
cat_json = categories.map {|c|
  {
    :cid => c["href"][/[0-9]+$/],
    :name => c.text.gsub(/(.*)\([0-9]+\)$/, '\1')
  }
}.to_json
open("categories.json", "w") {|f|
  f.puts cat_json
}

puts "get latest eid"
latest_eid = agent.page.at('//div[@class="entry_area"]//a[contains(@href, "eid")]/@href').value[/[0-9]+/].to_i

if File.exist?("misawa.json")
  misawa = JSON.parse(open('misawa.json') {|f| f.read })
  last_fetch = misawa.map{|m| m["eid"]}.max
else
  misawa = []
  last_fetch = 0
end

entries = []
if last_fetch.to_i >= latest_eid.to_i
  puts "There is no updates."
else
  ((last_fetch + 1)..latest_eid).each do |eid|
    begin
      puts "get information of #{misawa_url(eid)}"
      agent.get(misawa_url(eid))
      
      img = agent.page.at('//div[@class="entry"]//img')
      img_url = if img then img.attributes["src"].value else nil end
      title = agent.page.at('//div[@class="entry_area"]/h2').text
      timestamp = Time.parse(agent.page.at('//ul[@class="state"]/li').text)
      cid = agent.page.at('//ul[@class="state"]//a[contains(@href, "cid")]/@href').value[/[0-9]+/].to_i
      
      if img_url then
        entry = { "eid" => eid, "title" => title, "img_url" => img_url, "timestamp" => timestamp, "cid" => cid }
        entries << entry
      end
    rescue Mechanize::ResponseCodeError => ex
      raise "error at fetching #{eid}" if ex.response_code != '404' 
      puts "entry not found #{eid}"
    rescue
      puts JSON.generate entries
      raise "error at fetching #{eid}"
    end
    
    sleep 2
  end
end

misawa = misawa + entries
open("misawa.json", "w") {|f|
  f.puts JSON.generate (misawa)
}

puts "generate index.html"
# system("haml -E utf-8 index.html.haml index.html")
open("index.html", "w") {|f|
  f.puts Haml::Engine.new(open("index.html.haml"){|f| f.read}).render
}

Dir.mkdir "images" if not File.exist?("images")
Dir.mkdir "thumbs" if not File.exist?("thumbs")

puts "fetch misawa images"
misawa.each do |m|
  if not File.exist?("images/#{m["eid"]}.gif")
    puts "get #{m["img_url"]}"
    f = agent.get m["img_url"]
    f.save "images/#{m["eid"]}.gif"
  end
  if not File.exist?("thumbs/#{m["eid"]}.gif")
    cmd = "convert -crop 100x100+70+50 images/#{m["eid"]}.gif thumbs/#{m["eid"]}.png"
    puts cmd
    system(cmd)
  end
  sleep 1
end
