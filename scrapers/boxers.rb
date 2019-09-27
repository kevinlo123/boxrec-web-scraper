#!/usr/bin/env ruby

require 'csv'
require 'mechanize'

agent = Mechanize.new{ |agent| agent.history.max_size=0 }
agent.user_agent = 'Mozilla/5.0'
base = "http://boxrec.com"
division = ARGV[0]
search_url = "https://boxrec.com/en/ratings?Rpy%5Bcountry%5D=&Rpy%5Bdivision%5D=#{division}&Rpy%5Bsex%5D=M&Rpy%5Bstance%5D=&Rpy%5Bstatus%5D=a&r_go=&offset="
path = '//table[@id="ratingsResults"]/tbody/tr'
boxers = CSV.open("./csv/boxers_#{division}.csv","w")
url = search_url

begin
  page = agent.get(url)
rescue
  print "  -> error, retrying\n"
  retry
end

a = page.parser.xpath('//div[@class="pagerElement"]')[-2].text
a.gsub!("[","")
a.gsub!("]","")
last = a.to_i
inc = 0

(1..last).each_with_index do |page, i|

   begin
      case i 
      when 0
         page = agent.get(url)  
      else
         inc += 50            
         offset = inc.to_s
         page = agent.get(url + offset)           
      end
   rescue
      print "  -> error, retrying\n"
      retry
   end

   page.parser.xpath(path).each do |tr|
      row = [division]
      tr.xpath("td").each_with_index do |td, j|
         case j
         when 0
            rank = td.xpath("span").first
            unless rank.nil?
               row += [rank]  
            end               
         when 1
            name = td.text.strip
            a = td.xpath("a").first
            href = base + a.attributes["href"].value.strip
            human_id = href.gsub(/[^0-9]/, '')
            row += [human_id, name, href]   
         when 2 
            points = td.text.strip
            row += [points]
         when 4
            age = td.text.strip
            row += [age]
         when 5
            wins = td.xpath("span").first
            losses = td.xpath("span")[1]
            draws = td.xpath("span").last
            row += [wins, losses, draws]
         when 6
            puts td   
         end
      end
      if (row.size > 2)
         boxers << row
      end
   end
   boxers.flush
end

boxers.close
