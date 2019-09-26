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

puts last

inc = 0

(1..last).each_with_index do |page, i|
   inc += 50            
   offset = inc.to_s
   begin
      case i 
      when 0
         page = agent.get(url)  
      else
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
         when 1
            text = td.text.strip
            a = td.xpath("a").first
            href = base + a.attributes["href"].value.strip
            human_id = href.gsub(/[^0-9]/, '')
            row += [human_id, text, href]   
         end
      end
      if (row.size > 2)
         boxers << row
      end
   end
   boxers.flush
end

boxers.close
