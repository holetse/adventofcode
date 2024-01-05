class Polygon
    attr_reader :vertices
    attr_reader :edges

    Vertex = Struct.new(:x, :y, :color) do
        def point
            [x, y]
        end
    end

    Edge = Struct.new(:v1, :v2) do
        def horizontal_edge?
            v1.y == v2.y
        end
        
        def vertical_edge?
            v1.x == v2.x
        end

        def length
            (vertical_edge? ? (v2.y - v1.y) : (v2.x - v1.x)).abs
        end

        def range
            start_at, end_at = (vertical_edge? ? [v1.y, v2.y] : [v1.x, v2.x]).minmax
            if vertical_edge?
                end_at += 1
            else
                start_at += 1
            end
            (start_at..(end_at - 1))
        end

        def overlap?(edge_or_range)
            other_range = edge_or_range.respond_to?(:range) ? edge_or_range.range : edge_or_range
            other_range.begin <= range.end && range.begin <= other_range.end 
        end

        def overlap(edge_or_range)
            return nil if !overlap?(edge_or_range)
            other_range = edge_or_range.respond_to?(:range) ? edge_or_range.range : edge_or_range
            
            overlap_range = nil
            remainder = []
            if range.cover?(other_range)
                overlap_range = other_range
            elsif other_range.begin < range.begin && other_range.end > range.end # begin & end overlap
                overlap_range = range
                remainder = [other_range.begin..(range.begin - 1), (range.end + 1)..other_range.end]
            elsif other_range.begin >= range.begin && other_range.end > range.end && other_range.begin <= range.end  # end overlap
                overlap_range = other_range.begin..range.end
                remainder = [(range.end + 1)..other_range.end]
            elsif other_range.begin < range.begin && other_range.end <= range.end && other_range.end >= range.begin  # begin overlap
                overlap_range = range.begin..other_range.end
                remainder = [other_range.begin..(range.begin - 1)]
            else
                remainder = [other_range]
            end
    
            return overlap_range, remainder
        end
    end

    def initialize(*args)
        @vertices = [Vertex.new(0, 0, nil)]
        @edges = []
        super(*args)
    end

    def append(x, y, color)
        last = vertices.last
        v = Vertex.new(x, y, color)
        @vertices.append(v)
        @edges.append(Edge.new(last, v)) if last
        @bounds = nil
        @area = nil
        @horizontal_edges = nil
        @vertical_edges = nil
        @horizontal_edge_tbl = nil
        raise "unsupported diagonal: #{x},#{y}" if last && (last.x != x && last.y != y)
        vertices.last
    end

    def append_relative(rel_x, rel_y, color)
        last_x, last_y = (@vertices.last&.point || [0, 0])
        append(last_x + rel_x, last_y + rel_y, color)
    end

    def bounds
        return @bounds if @bounds

        min_x, max_x = vertices.collect(&:x).minmax
        min_y, max_y = vertices.collect(&:y).minmax
        @bounds = [[min_x, min_y], [max_x, max_y]]
    end

    def extent
        [[bounds[0][0], bounds[1][0]], [bounds[0][1], bounds[1][1]]]
    end

    def horizontal_edges
        @horizontal_edges ||= edges.select(&:horizontal_edge?).sort { |a, b| a.v1.y <=> b.v1.y }
    end

    def vertical_edges
        @vertical_edges ||= edges.select(&:vertical_edge?).sort { |a, b| a.v1.x <=> b.v1.x }
    end

    def horizontal_edge_tbl
        @horizontal_edge_tbl ||= horizontal_edges.reduce({}) do |tbl, edge|
            tbl[edge.v1.y] ||= []
            tbl[edge.v1.y].append(edge)
            tbl
        end
    end

    def on_horizontal_edge?(x, y)
        (horizontal_edge_tbl[y] || []).each do |edge|
            return true if edge.range.include?(x)
        end

        return false
    end

    def cover?(x, y)

        return true if on_horizontal_edge?(x, y)

        crossings = 0
        last_crossing = nil
        vertical_edges.each do |edge|
            break if edge.v1.x > x
            if edge.range.include?(y)
                if edge.v1.x == x
                    return true
                else
                    crossings += 1
                    if last_crossing
                        # horizontal edge check between last_crossing..edge
                        horizontal_edge_range = (last_crossing.v1.x..edge.v1.x)
                        found_edges = (horizontal_edge_tbl[y] || []).select do |e|
                            e.overlap?(horizontal_edge_range)
                        end
                        if found_edges.length == 1
                            # need to check curvature direction
                            if !(edge.range.include?(y - 1) && last_crossing.range.include?(y - 1)) && !(edge.range.include?(y + 1) && last_crossing.range.include?(y + 1))
                                crossings -= 1 # we counted an extra edge
                            end
                        elsif found_edges.length > 1
                            raise "bad edge check #{edge}"
                        end
                    end
                    last_crossing = edge
                end
            end
        end

        crossings.odd?
    end

    def area
        area = 0
        vertical_edges.each do |edge|
            remaining = [edge.range]
            while !remaining.empty?
                rng = remaining.pop
                overlap = vertical_edges.find do |e|
                    edge.v1.x < e.v1.x && e.overlap?(rng)
                end

                next if overlap.nil?

                overlap_range, new_remainders = overlap.overlap(rng)
                if on_horizontal_edge?(edge.v1.x + 1, overlap_range.begin)
                    overlap_range = (overlap_range.begin + 1)..(overlap_range.end)
                elsif on_horizontal_edge?(edge.v1.x + 1, overlap_range.end)
                    overlap_range = (overlap_range.begin)..(overlap_range.end - 1)
                end
                
                overlap_area = (overlap.v1.x - (edge.v1.x + 1)) * overlap_range.size
                remaining.append(*new_remainders)
                if cover?(edge.v1.x + 1, overlap_range.begin + (overlap_range.size / 2)) # unless this is an exterior edge, which it could be, even with overlap
                    area += overlap_area
                end
            end

        end

        area + edges.sum(&:length)
    end
end

polygon = Polygon.new
point_r = /^(?<dir>[RLDU])\s(?<offset>\d+)\s\(#(?<hex>[a-f0-9]{6})\)$/
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    point_match = point_r.match(line)
    hex = point_match[:hex]
    offset = hex[0..4].to_i(16)
    point = case hex[-1]
    when '0'
        [offset, 0]
    when '2'
        [-offset, 0]
    when '3'
        [0, offset]
    when '1'
        [0, -offset]
    else
        raise "bad direction: #{line}"
    end
    polygon.append_relative(point[0], point[1], point_match[:hex])
end

puts "Area: #{polygon.area}"