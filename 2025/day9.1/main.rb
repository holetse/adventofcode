Tile = Struct.new(:x, :y) do
    def area_between(tile)
      ((x-tile.x).abs + 1) * ((y-tile.y).abs + 1)
    end

    def to_s
        inspect
    end

    def inspect
        "<tile @#{x},#{y}>"
    end
end

def every_pair(objs)
  pairs = []
  unpaired = objs.dup
  while obj = unpaired.pop do
    pairs_for_obj = unpaired.collect { |other| [obj, other] }
    pairs.push(*pairs_for_obj)
  end
  pairs
end

r = /(\d+),(\d+)/
tiles = File.readlines(File.join(__dir__, 'input.txt'), chomp: true).collect do |line|
  match = line.match(r)
  Tile.new(*(match[1..2].collect(&:to_i)))
end

tile_pairs = every_pair(tiles)
tile_areas = tile_pairs.collect { |pair| pair[0].area_between(pair[1]) }.sort!

puts "the largest area = #{tile_areas.last}"