Color.delete_all
Color.create(id: 1, rgb: 'fec878')
Color.create(id: 2, rgb: 'ffcd00')
Color.create(id: 3, rgb: 'd8b525')
Color.create(id: 4, rgb: 'fe9a34')
Color.create(id: 5, rgb: 'f15a24')
Color.create(id: 6, rgb: 'c12f02')
Color.create(id: 7, rgb: '9ac4db')
Color.create(id: 8, rgb: '83ddd2')
Color.create(id: 9, rgb: '00a99d')
Color.create(id: 10, rgb: '29abe2')
Color.create(id: 11, rgb: '0071bc')
Color.create(id: 12, rgb: '1f5d75')
Color.create(id: 13, rgb: 'a6e538')
Color.create(id: 14, rgb: '83a53a')
Color.create(id: 15, rgb: '4d7759')
Color.create(id: 16, rgb: '9fbb9f')
Color.create(id: 17, rgb: '1c9c5a')
Color.create(id: 18, rgb: '584b53')
Color.create(id: 19, rgb: 'f7bcd0')
Color.create(id: 20, rgb: 'ee6492')
Color.create(id: 21, rgb: 'b41b7e')
Color.create(id: 22, rgb: '8e292e')
Color.create(id: 23, rgb: '5133a5')
Color.create(id: 24, rgb: '9577cb')

Group.all.each do |g|
  puts "Working on: #{g.id}"
  g.update!(color_id: (rand(24) + 1) )
end
