(1..12).each do |n|
  Rank.create(id: n, name: "#{n}", color_id: n)
end
