Region = Struct.new(:width, :height, :presents) do
  def to_s
    inspect
  end

  def inspect
    "<region w=#{width} h=#{height} presents={#{presents.join(' ')}}"
  end

  def area
    width * height
  end
end

Present = Struct.new(:index, :shape) do

  def area
    shape.sum { |row| row.count('#') }
  end

  def to_s
    inspect
  end

  def inspect
    "<present index=#{index} shape={#{shape.collect(&:join).join(' ')}} area=#{area}>"
  end
end

def read_region(line)
  parts = line.match(/(\d+)x(\d+):\s([\d\s]+)/)
  Region.new(parts[1].to_i, parts[2].to_i, parts[3].split(' ').collect(&:to_i))
end

reading_presents = true
reading_header = true
regions = []
present_header_r = /^(\d+):$/
present = nil
presents = []
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
  if reading_presents
    if reading_header
      parts = line.match(present_header_r)
      if parts
        present = Present.new(parts[1], [])
        reading_header = false
      else
        regions << read_region(line)
        reading_presents = false
      end
    else
      if line == ''
        presents << present
        reading_header = true
      else
        present.shape << line.split('')
      end
    end
  else
    regions << read_region(line)
  end
end

possible = 0
regions.each do |region|
  presents_area = region.presents.each_with_index.sum { |count, i| presents[i].area * count }
  possible += 1 if presents_area < region.area
end

puts "possible regions = #{possible}"