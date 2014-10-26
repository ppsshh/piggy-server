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
    $config['currencies'].each do |src_cur, dst_cur_array|
      dst_cur_array.each do |dst_cur|

        cmdout = `curl "http://www.bloomberg.com/markets/chart/data/1Y/#{dst_cur.upcase}#{src_cur.upcase}:CUR" -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:31.0) Gecko/20100101 Firefox/31.0' -H 'X-Requested-With: XMLHttpRequest' -H "Referer: http://www.bloomberg.com/quote/#{dst_cur.upcase}#{src_cur.upcase}:CUR"`
puts cmdout
        JSON.parse(cmdout)["data_values"].each do |dv|
          date = Time.at(dv[0]/1000).to_date.to_s
          history[date] = {} unless history[date]
          history[date][dst_cur.downcase.to_sym] = dv[1]
        end

      end
    end
    puts history
  end
end
