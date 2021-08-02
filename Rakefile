require './app.rb'
require 'open-uri'
require 'sinatra/activerecord/rake'

namespace :piggy do
  task :configuration do
    puts $config
  end

  UAG = "Mozilla/5.0 (X11; Linux x86_64; rv:84.0) Gecko/20100101 Firefox/84.0"

  def get_json_prices(curr)
    puts "#{curr.title}: downloading #{curr.api['url']}"
    response = HTTParty.get(curr.api["url"], headers: {
        "User-Agent" => UAG,
#"Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
"Accept" => "application/json, text/javascript, */*; q=0.01",
"Accept-Language" => "en-US,en;q=0.5",
#"Accept-Encoding" => "gzip, deflate, br",
"Connection" => "keep-alive",
"Upgrade-Insecure-Requests" => "1",
"Pragma" => "no-cache",
"Cache-Control" => "no-cache",
        "Referer" => curr.api["referer"],
        "X-Requested-With" => "XMLHttpRequest"
    })

puts response
    puts "#{curr.title}: parsing..."
    j = JSON.parse(response.body)

    result = {}
    if curr.api["source"] == "investing.com"
      j["candles"].each do |i|
        # i[0] = unixtime * 1000; i[1] = price; i[2] = volume; i[3] = cumulative volume (??)
        result[ Time.at(i[0]/1000).to_date ] = i[1]
      end
    elsif curr.api["source"] == "bloomberg.com"
      j[0]["price"].each do |i|
        # {"date"=>"2016-10-19", "value"=>62.261}
        result[ Date.parse(i["date"]) ] = i["value"].to_f
      end
    end
    return result
  end


  desc "Update currencies"
  task :update => :configuration do
    require 'date'
    require 'json'
    require 'httparty'

    Currency.all.each do |curr|
      next if curr.title == "USD"
      next unless curr.update_regularly
      next unless curr.api # temporarily

      latest_price = Price.where(currency_id: curr.id).order(actual_date: :desc).first
      latest_price_date = latest_price ? latest_price.actual_date : Date.new(2010,1,1)
# это значение actual_date у самого свежего PRICE

      get_json_prices(curr).each do |date, price|
        # обрабатываем только те записи, которые >= latest_price_date
        next unless date >= latest_price_date

        p = Price.find_or_create_by(actual_date: date, currency_id: curr.id)
        p.rate = curr.api["inverse"] ? 1.0/price : price
        p.save
      end

    rescue Exception => e
      puts "Error occurred: #{e}"
      puts "Skipping #{curr.title}"
      next
    end
  end
end
