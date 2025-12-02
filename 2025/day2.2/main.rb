
def scoreId(id)
  chunkSize = id.length / 2
  while chunkSize > 0 do
    if id.length % chunkSize == 0
      chunks = 0.upto(id.length / chunkSize - 1).collect do |i|
        id[(i * chunkSize)...((i + 1) * chunkSize)]
      end
      return id.to_i if chunks.count(chunks[0]) == chunks.length
    end
    chunkSize -= 1
  end
  0
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