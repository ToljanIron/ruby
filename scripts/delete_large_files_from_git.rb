#! /usr/bin/env ruby

def valid_input(chr)
  %w(y Y n N).include? chr
end

INVALID_INPUT_MSG = "invalid inputs, accepts only 'y', 'Y','n','N'"

str = ` git rev-list master| while read rev; do git ls-tree -lr $rev \
  | cut -c54- | grep -v '^ '; done | sort -u | perl -e '
  while (<>) {
    chomp;
    @stuff=split("\t");
    $sums{$stuff[1]} += $stuff[0];
  }
  print "$sums{$_} $_\n" for (keys %sums);
' | sort -rn`

large_files = str.split.select.each_with_index { |_s, i| i.odd? }

large_files.each do |line|
  path = line[0..-1]
  puts "\nwhould you like to delete history for: #{path}", 'Y/N'
  option = ' '
  until valid_input option[0]
    option = gets
    puts INVALID_INPUT_MSG unless valid_input option[0]
  end
  next if %w(n N).include? option[0]
  cmd = `git filter-branch -f --prune-empty --index-filter 'git rm -rf \
      --cached --ignore-unmatch #{path}' --tag-name-filter cat -- --all`
  puts cmd
end
