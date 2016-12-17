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

    history = {}
    lc = Currency.order(date: :desc).take
    lc_date = lc ? lc.date - 7 : Date.new(2010, 1, 1)

    $config['currencies'].each do |curr|

      cmdout = `curl "https://www.bloomberg.com/markets/chart/data/1Y/#{curr.upcase}USD:CUR" -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:31.0) Gecko/20100101 Firefox/31.0' -H 'X-Requested-With: XMLHttpRequest' -H "Referer: https://www.bloomberg.com/quote/#{curr.upcase}USD:CUR"`
      JSON.parse(cmdout)["data_values"].each do |dv|
        date = Time.at(dv[0]/1000).to_date
        if date >= lc_date
          att = {date: date, currency: curr.downcase}
          c = Currency.where(att).take || Currency.new(att)
          c.rate = dv[1]
          c.save
        end
      end

    end
  end
end
