#!/usr/bin/env ruby

on_heroku = !ARGV[0].nil?
remote_exist = !ARGV[1].nil?
branch_exist = !ARGV[2].nil?
valid_apps = %w(workships-zim workships workships-staging workships-dev)
if on_heroku
  unless valid_apps.include?(ARGV[0])
    puts "#{ARGV[0]} is invalid heroku app"
    exit
  end
  unless remote_exist || branch_exist
    puts 'please insert remote or branch'
    exit
  end
  prefix = 'heroku repo:'
  postfix = "-a #{ARGV[0]}"
  remote = ARGV[1]
  branch = ARGV[2]
  puts "#{prefix}purge_cache #{postfix}"
  `#{prefix}purge_cache #{postfix}`
  puts "#{prefix}reset #{postfix}"
  `#{prefix}reset #{postfix}`
  puts "git push #{remote} #{branch}:master"
  `git push #{remote} #{branch}:master`
  puts "upgrade keylines in #{ARGV[0]} sucsses"
else
  puts 'please insert heroku app'
end
