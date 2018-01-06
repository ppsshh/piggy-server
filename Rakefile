require './app.rb'
require 'sinatra/activerecord/rake'

namespace :piggy do
  task :configuration do
    puts $config
  end

  UAG = "Mozilla/5.0 (X11; Linux x86_64; rv:56.0) Gecko/20100101 Firefox/56.0"

  def get_json_prices(curr)
    puts "#{curr.title}: downloading #{curr.api['url']}"
    response = HTTParty.get(curr.api["url"], headers: {
        "User-Agent" => UAG,
        "Referer" => curr.api["referer"],
        "X-Requested-With" => "XMLHttpRequest"})
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

    $currencies.each do |curr_id, curr|
      next if curr.title == "USD"
#      next unless curr.update_regularly
      next unless curr.api # temporarily

      Price.where(currency: curr, record_type: 2).each do |p|
        p.record_type = 0
        p.save
      end

      latest_price = Price.where(currency_id: curr.id).order(actual_date: :desc).first
      latest_price_date = latest_price ? latest_price.actual_date : Date.new(2010,1,1)
# это значение actual_date у самого свежего PRICE

      begin
        prices = get_json_prices(curr)
      rescue Exception => e
        puts "Error occurred: #{e}"
        puts "Skipping #{curr.title}"
        next
      end

      prices.each do |date,price|
        # обрабатываем только те записи, которые >= latest_price_date
        next unless date >= latest_price_date

        p = Price.find_or_create_by(actual_date: date, currency_id: curr.id)
        p.rate = curr.api["inverse"] ? 1.0/price : price
        p.save
      end

      latest_permanent = Price.where(currency_id: curr.id, record_type: 1).order(date: :desc).first
# date - это всегда первое число месяца
      date = latest_permanent ? latest_permanent.date.next_month : Date.new(2010, 1, 1)
      while date < Date.today do
# находится самая ПЕРВАЯ запись PRICE за месяц (YYYY,MM,01...YYYY,MM,30)
        p = Price.where(currency_id: curr.id, actual_date: (date)..(date.next_month - 1)).order(actual_date: :asc).first
        if p != nil
          puts "Making record permanent: #{p.inspect}"
          p.date = date
          p.record_type = 1
          p.save
        end
        date = date.next_month
      end

# меняем тип (на = 2) для самого свежего курса; и зачем-то присваеваем date=actual_date
      p = Price.where(currency_id: curr.id).order(actual_date: :desc).first
      if p.record_type != 1
        p.record_type = 2
        p.date = p.actual_date
        p.save
      end
    end
  end

  desc "Recalculate anchors"
  task :recalc => :configuration do
    include PiggyHelpers
    recalculate_anchors
  end
end
