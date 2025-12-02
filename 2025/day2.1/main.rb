
def scoreId(id)
  middle = id.length / 2
  if id[0...middle] == id[middle..-1]
    id.to_i
  else
    0
  end
end

id_ranges = File.read('input.txt').strip.split(',').collect do |id_range|
  first, last = id_range.split('-')
  (first..last)
end

total = id_ranges.collect do |range|
  range.collect do |id|
    scoreId(id)
  end
end.flatten.sum

puts "total invalid ids = #{total}"