#!/usr/bin/env ruby

############################################################
#
# This script will merge feature branches.
# development-<TIMESTAMP> = master + *_dev *_stg + *_prod
# staging-<TIMESTAMP> = master + *_stg + *_prod
# production-<TIMESTAMP> = master + *_prod
#
# If the cleanup flag is supplied, branches that are merged into master will be deleted from remote & locally.
#
# Requirements:
#  - add 'English' 'colorize' to your gemfile or install them globaly by `gem install <GEM>`
#
# Running examples:
#  - ruby git_merger.rb
#  - ruby git_merger.rb cleanup
############################################################

require 'English'
require 'colorize'

DEV  = '_dev'
STG  = '_stg'
PROD = '_prod'

DELETE_BRANCHES = ARGV[0]=='cleanup'

def log(level, msg)
  case level
  when :error
    puts msg.colorize(:red)
  when :warn
    puts msg.colorize(:yellow)
  when :debug
    puts msg.colorize(:blue)
  when :info
    puts msg.colorize(:green)
  else
    puts msg.colorize(:light_green)
  end
end

def fetch
  `git fetch`
end

def sort_branches
  branches = `git for-each-ref --sort=committerdate refs/heads/ --format='%(refname:short)'`.split.reverse!
  dev = branches.select { |rgx| rgx[/#{DEV}|#{STG}|#{PROD}$/] }
  stg = branches.select { |rgx| rgx[/#{STG}|#{PROD}$/] }
  prod = branches.select { |rgx| rgx[/#{PROD}$/] }
  return { 'production' => prod, 'staging' => stg, 'development' => dev }
end

def current_branch
  return `git status`.split[2]
end

def verify_master
  unless current_branch == 'master'
    log(:error, 'please run this script from master branch!')
    exit
  end
end

def verify_up_to_date
  unless `git status | grep behind` == ''
    log(:error, "local #{current_branch} behind origin/master. run `git pull` to fix.")
    exit
  end
end

def verify_no_pending_changes
  unless `git status --porcelain` == ''
    log(:error, "local #{current_branch} has uncommited changes.")
    exit
  end
end

def delete_old_merged_branches
  rgx = /origin\/(.*?)$/
  old_branches = `git branch -r --merged | grep -v master`.split.map { |s| s[rgx, 1] }.compact
  old_branches.each do |b|
    next if (b.start_with?('KEEP') || b.start_with?('HEAD'))
    log(:debug, "deleting #{b}")
    `git push --delete origin #{b}`
  end
  log(:debug, "deleting locally merged branches")
  `git branch --merged | egrep -v "(^\*|master|KEEP)" | xargs git branch -d`
end

def checkout_to_merger_branch(name)
  b = generate_branch_name(name)
  unless `git branch | grep #{b}`.empty?
    `git branch -D #{b}`
  end
  `git checkout -b #{b}`
  b
end

def checkout_to_master_branch
  `git checkout master`
end

def generate_branch_name(name)
  now = (Time.now).strftime('%Y%m%d%H%M')
  return "#{now}-#{name}"
end

def merge(target_branch, branches_lst)
  branches_lst.each do |b|
    `git merge --no-edit #{b}`
    if $CHILD_STATUS.success?
      log(:debug, "On #{target_branch}: merged #{b}")
    else
      log(:warn, "On #{target_branch}: merging #{b} FAILED")
      `git reset --merge`
      raise "Failed to merge branch #{b}"
    end
  end
end

def run
  verify_master
  verify_up_to_date
  verify_no_pending_changes
  begin
    fetch
    delete_old_merged_branches if DELETE_BRANCHES
    sort_branches
    sort_branches.each do|env|
      next if env[1].empty?
      merge_branch = checkout_to_merger_branch(env[0])
      merge(merge_branch, env[1])
      log(:info, "created #{merge_branch}")
      checkout_to_master_branch
    end
  rescue => e
    log(:error, e)
  ensure
    checkout_to_master_branch
    log(:info, "done")
  end
end

run
