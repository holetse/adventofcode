Hailstone = Struct.new(:x, :y, :z, :dx, :dy, :dz) do
    def m
        @m ||= dy / dx
        @m
    end

    def b
        @b ||= y - (m * x)
        @b
    end

    def parallel_to?(stone)
        m == stone.m
    end

    def intersects?(stone)
        !parallel_to?(stone)
    end

    def intersection(stone)
        return nil if parallel_to?(stone)

        ix = (stone.b - b) / (m - stone.m)
        iy = (m * ix) + b

        [ix, iy]
    end

    def in_past?(point)
        if dx.positive?
            point.first < x
        else
            point.first > x
        end
    end
end

def point_in_bound(point, bounds)
    x, y = point
    top_left, bottom_right = bounds
    tl_x, tl_y = top_left
    br_x, br_y = bottom_right

    x >= tl_x && x <= br_x && y <= tl_y && y >= br_y
end

TEST_AREA = [[200000000000000, 400000000000000], [400000000000000, 200000000000000]]

stones_r = /^(?<x>-?\d+),\s+(?<y>-?\d+),\s+(?<z>-?\d+)\s+@\s+(?<dx>-?\d+),\s+(?<dy>-?\d+),\s+(?<dz>-?\d+)$/
stones = []
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    parsed_stone = stones_r.match(line)
    stones.append(Hailstone.new(parsed_stone[:x].to_r, parsed_stone[:y].to_r, parsed_stone[:z].to_r, parsed_stone[:dx].to_r, parsed_stone[:dy].to_r, parsed_stone[:dz].to_r))
end

used_stones = Set.new
intersections = []
stones.each do |a|
    stones.each do |b|
        next if a == b || used_stones.include?(b)
        point = a.intersection(b)
        intersections.append([point, [a,b]]) if !point.nil?
    end
    used_stones.add(a)
end

future_intersections_in_area = intersections.select { |point, stones| point_in_bound(point, TEST_AREA) && !(stones.first.in_past?(point)) && !(stones.last.in_past?(point)) }

puts "Intersecitons: #{future_intersections_in_area.length}"