#!/usr/bin/env ruby
# coding: utf-8

# This is the main program.
# 0. it checks dependencies..
if not Dir.exists? "#{ENV['HOME']}/wikipedia/virgo"
  puts "please mount virgo's mediawiki to ~/wikipedia with wikipediaFs"
  exit 1
end
# 1. temp directory existance...
if not Dir.exists? 'data'
  puts "There is no data folder. Creating 'data' directory. Please put there some *.mm (moinmoin) files to convert to *.mw, before running this scrit again."
  exit 1
end
# 2. if there are some moinmoin files, it will convert...
created = []
Dir['data/*.mm'].each do |mm|
  unless File.exists?( mw = mm + '.mw' )
    system("./mm2mw.rb",mm,mw)
    created << mw.gsub(/^data\//,'')
  end
end
# 3. it copies the moin-moin files into the mediawiki...
created.each do |mw|
  puts "copying #{mw} -> virgo wiki..."
  %x{cp data/#{mw} #{ENV['HOME']}/wikipedia/virgo/#{mw}}
end

puts 'ready. You can rename the files on the web site of the mediawiki.'

