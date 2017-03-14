require './app.rb'
require 'sinatra/activerecord/rake'

namespace :piggy do
  task :configuration do
    puts $config
  end

  desc "Update currencies"
  task :update => :configuration do
    require 'date'
    require 'json'

    Price.where(record_type: 2).each do |p|
      p.record_type = 0
      p.save
    end

    $currencies.each do |curr_id, curr|
      next if curr.title == "USD"

      pair_name = curr.is_stock ? "#{curr.title}:US" : "#{curr.title}:CUR"
      cmdout = `curl "https://www.bloomberg.com/markets/api/bulk-time-series/price/#{pair_name}?timeFrame=1_YEAR" -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:31.0) Gecko/20100101 Firefox/31.0' -H 'X-Requested-With: XMLHttpRequest' -H "Referer: https://www.bloomberg.com/quote/#{pair_name}"`

      latest_price = Price.where(currency_id: curr.id).order(actual_date: :desc).first
      latest_price_date = latest_price ? latest_price.actual_date.to_s : "2010-01-01"

      JSON.parse(cmdout)[0]["price"].each do |dv|
        if dv["date"] >= latest_price_date
          c = Price.find_or_create_by(actual_date: dv["date"], currency_id: curr.id)
          c.rate = curr.is_stock ? dv["value"] : 1.0/dv["value"]
          c.save
        end
      end

      latest_permanent = Price.where(currency_id: curr.id, record_type: 1).order(date: :desc).first
      date = latest_permanent ? latest_permanent.date.next_month : Date.new(2010, 1, 1)
      while date < Date.today do
        p = Price.where(currency_id: curr.id, actual_date: (date)..(date.next_month - 1)).order(actual_date: :asc).first
        if p != nil
          puts "Making record permanent: #{p.inspect}"
          p.date = date
          p.record_type = 1
          p.save
        end
        date = date.next_month
      end

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
