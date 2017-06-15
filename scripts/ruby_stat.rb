#!/home/dev/.rvm/rubies/ruby-2.3.1/bin/ruby

require 'colorize'
require 'awesome_print'
require 'logger'

DEBUG = false
JSLINT_OPTIONS = '--nomen --plusplus --newcap --vars --indent=2 --white'

def info(m)
  puts m.green
end

def error(m)
  puts m.red
end

def warn(m)
  puts m.yellow
end

def blue(m)
  puts m.blue
end

def get_ruby_source_files
  cs = `git status -s | awk '{print $2}' | grep -e '.*\.rb$' | grep 'app\\\|lib'`
  a_cs = cs.split()
  return a_cs
end

def get_ruby_spec_files
  cs = `git status -s | awk '{print $2}' | grep -e '.*\.rb$' | grep spec`
  a_cs = cs.split()
  return a_cs
end

def get_javascript_source_files
  cs = `git status -s | awk '{print $2}' | grep -e '.*\.js$' | grep assets`
  a_cs = cs.split()
  return a_cs
end

def ruby_spec_from_file_name(file_name)
  return "#{file_name[0..-4]}_spec.rb"
end

def js_spec_from_file_name(file_name)
  return "#{file_name[0..-4]}_spec.js"
end

def work_on_ruby_source_files
  a_ruby_source_files = get_ruby_source_files
  unit_testing_ruby_files(a_ruby_source_files)
  rubocoping_ruby_files(a_ruby_source_files)
  return a_ruby_source_files
end

def rubocoping_ruby_files(a_ruby_source_files)
  info "Rubocoping Ruby sources"
  a_ruby_source_files.each do |f|
    file_name = f.split('/').last
    info "  Wroking on #{file_name}:"
    num_of_warnings = DEBUG ? '-1' : `rubocop #{f} | grep app | wc -l`
    info "  Found #{num_of_warnings} warnnings on file: #{file_name}"
  end
end

def unit_testing_ruby_files(a_ruby_source_files)
  info "Unit testing Ruby sources"
  a_ruby_source_files.each do |f|
    file_name = f.split('/').last
    info "  Wroking on #{file_name}:"
    spec_name = ruby_spec_from_file_name(file_name)
    spec_file_location = `find spec -name #{spec_name}`
    spec_file_location = spec_file_location.strip

    if (spec_file_location == '')
      warn "  No spec file for #{file_name}"
      next
    end

    cmd = "rspec #{spec_file_location}  2> /dev/null | grep examples"
    res = DEBUG ? 'debug mode..' : `#{cmd}`
    info "  #{res}"
  end
end

def work_on_rspec_files(a_ruby_source_files)
  info "Checking rspec changes"
  s_ruby_source_files = a_ruby_source_files.join(' ')
  get_ruby_spec_files.each do |f|
    file_name = f.split('/').last
    info "  Wroking on #{file_name}:"
    base_file_name = file_name[0..-9]
    if ( s_ruby_source_files.include?(base_file_name) )
      info "  Skipping: #{file_name}"
      next
    end

    cmd = "rspec #{f}  2> /dev/null | grep examples"
    res = DEBUG ? 'debug mode..' : `#{cmd}`
    info "  #{res}"
  end
end

def run_karam_test(spec_file_location)
  escaped_spec_file_location = spec_file_location.gsub("/","\\/")
  cmd = "sed -i -e 's/REPLACE_WITH_SOURCE/#{escaped_spec_file_location}/' stat-karma.conf.js"
  `#{cmd}`
  res = `karma start stat-karma.conf.js | grep Executed`
  `git checkout -- stat-karma.conf.js`
  return res
end

def work_on_javascript_source_files
  info "Working on Javascript files"
  a_javascript_source_files = get_javascript_source_files
  a_javascript_source_files.each do |f|
    file_name = f.split('/').last
    info "  Wroking on #{file_name}:"
    spec_name = js_spec_from_file_name(file_name)
    info "Spec file name: #{spec_name}"
    spec_file_location = `find spec -name #{spec_name}`
    spec_file_location = spec_file_location.strip

    if (spec_file_location == '')
      warn "  No spec file for #{file_name}"
      next
    end

    res = DEBUG ? 'debug mode..' : run_karam_test(spec_file_location)
    info "  #{res}"
  end
  return a_javascript_source_files
end

def run_jslint_javascript_source_files
  info "Running jslint on Javascript files"
  get_javascript_source_files.each do |f|
    file_name = f.split('/').last
    info "  Wroking on #{file_name}:"
    cmd = "jslint #{JSLINT_OPTIONS} #{f}  | grep 'Line ' | wc -l"
    res = `#{cmd}`
    info "  #{res}"
  end
end

def main
  blue "======================================="
  a_ruby_source_files = work_on_ruby_source_files

  blue "======================================="
  work_on_rspec_files(a_ruby_source_files)

  blue "======================================="
  work_on_javascript_source_files

  blue "======================================="
  run_jslint_javascript_source_files
end


info "ruby_stat running ..."
begin
  main
rescue => e
  error e.message
  error e.backtrace.join('\n')
end
info "ruby_stat done ..."
