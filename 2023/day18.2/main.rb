Cell = Struct.new(:color, :row, :col, :matrix, :edge, :vertex, :covered, :included, :included_by, :multi_include) do
    def neighbors
        offsets = [
            [-1, 0], [0, -1], [0, 1], [1, 0]
        ]
        @neighbors ||= offsets.collect { |o| matrix.get_cell(row + o.first, col + o.last) }.compact
    end

    def vertical_edge?
        return false if !edge?
        edge.first.x == edge.last.x
    end

    def horizontal_edge?
        return false if !edge?
        edge.first.y == edge.last.y
    end

    def edge_type
        return '.' if !edge?
        return 'v' if vertical_edge?
        'h'
    end

    def colored?
        !color.nil?
    end

    def edge?
        !!edge
    end

    def vertex?
        !!vertex
    end

    def inside?
        return true if edge?
        return @inside if @inside

        crossed = 0
        is_edge = false
        started_vertex = nil
        started_dir = nil
        matrix.rows[row][0..col].each do |cell|
            if !is_edge && cell.edge?
                is_edge = true
                started_vertex = cell.vertex
                started_dir = matrix.get_cell(row - 1, cell.col)&.edge? ? 1 : -1 if started_vertex
            end
            if is_edge
                if cell.vertex? && started_vertex != cell.vertex
                    ended_dir = matrix.get_cell(row - 1, cell.col)&.edge? ? 1 : -1
                    crossed += 1 if started_dir != ended_dir
                    is_edge = false
                    started_vertex = nil
                    started_dir = nil
                elsif !cell.edge?#!cell.connection_directions.include?([0, 1])
                    crossed += 1 #if  #if started_edge != cell.edge #if ((cell.edge? || cell.vertex?) && started_dir == (cell.edge.first.y <=> cell.edge.last.y) || !cell.vertex?) #!cell.vertex?#if cell.connection_directions.include?([started_dir.first * -1, 0])
                    is_edge = false
                    started_vertex = nil
                    started_dir = nil
                end
            end
        end
        raise "bad edge" if is_edge
        @inside = crossed.odd?
        #crossed.odd?
    end

    def inside_but_not_included
        inside? && !included
    end
    
    def to_s
        inspect
    end

    def inspect
        "<cell #{color}@(#{row}, #{col})>"
    end
end

class Matrix
    include Enumerable

    def initialize(rows, *args)
        @rows = rows.dup.freeze
        super(*args)
    end

    def rows
        @rows
    end

    def cols
        @cols ||= 0.upto(rows[0].length - 1).collect { |i| rows.collect { |r| r[i] } }
    end

    def each
        if block_given?
            rows.each { |r| r.each { |c| yield c } }
        else
            Enumerator.new do |y|
                rows.each { |r| r.each { |c| y << c } }
            end
        end
    end

    def each_row
        rows.each { |r| yield r }
    end

    def each_col
        cols.each { |c| yield c }
    end

    def get_cell(row, col)
        return nil if row < 0 || row > rows.length - 1 || col < 0 || col > cols.length - 1
        rows[row][col]
    end

    def visualize(method = :colored?)
        rows.collect { |r| r.collect(&method).collect do |v|
            if [true, false, nil].include?(v)
                v ? '#' : '.'
            else
                v
            end
        end.join('') }.join("\n")
    end
end

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

        # def direction
        #     vertical_edge? ? (v1.y - v2.y <=> 0) : (v1.x - v2.x <=> 0)
        # end

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
            #edge.range.begin <= range.end && range.begin <= edge.range.end
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

        # def map_range(rng)
        #     mapped_range = nil
        #     remainder = []
        #     if range.cover?(rng)
        #         mapped_range = map(rng.begin)..map(rng.end)
        #     elsif rng.begin < range.begin && rng.end > range.end # begin & end overlap
        #         mapped_range = dst_range
        #         remainder = [rng.begin..(range.begin - 1), (range.end + 1)..rng.end]
        #     elsif rng.begin >= range.begin && rng.end > range.end && rng.begin <= range.end  # end overlap
        #         mapped_range = map(rng.begin)..(dst_range.end)
        #         remainder = [(range.end + 1)..rng.end]
        #     elsif rng.begin < range.begin && rng.end <= range.end && rng.end >= range.begin  # begin overlap
        #         mapped_range = (dst_range.begin)..map(rng.end)
        #         remainder = [rng.begin..(range.begin - 1)]
        #     else
        #         remainder = [rng]
        #     end
    
        #     return mapped_range, remainder
        # end
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

    def point_to_grid(x, y)
        min_x, max_x, min_y, max_y = extent.flatten
        span_y = max_y - min_y
        [span_y - (y - min_y), x - min_x] # y-axis flips
    end

    def grid_to_point(row, col)
        min_x, max_x, min_y, max_y = extent.flatten
        span_y = max_y - min_y
        [ col + min_x, (span_y + min_y) - row]
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

    def grid
        return @grid if @grid
        min_x, max_x, min_y, max_y = extent.flatten
        span_x = max_x - min_x
        span_y = max_y - min_y
        rows = 0.upto(span_y+1).collect do |row|
            0.upto(span_x+1).collect do |col|
                Cell.new(nil, row, col)
            end
        end
        
        @grid = Matrix.new(rows)
        @grid.each do |cell|
            cell.matrix = @grid
        end

        if @vertices.length > 1
            @vertices.each_with_index do |v, vi|
                next_v = @vertices[vi + 1]
                next if next_v.nil?
                row, col = point_to_grid(v.x, v.y)
                next_row, next_col = point_to_grid(next_v.x, next_v.y)
                vertical = v.x == next_v.x
                @grid.get_cell(row, col).vertex = v
                @grid.get_cell(next_row, next_col).vertex = next_v
                if vertical
                    start, finish = [row, next_row].minmax
                    start.upto(finish) do |i|
                        cell = @grid.get_cell(i, col)
                    end
                else
                    start, finish = [col, next_col].minmax
                    start.upto(finish) do |i|
                        cell = @grid.get_cell(row, i)
                    end
                end
            end
        end

        if !@edges.empty?
            @edges.each do |edge|
                edge.range.each do |offset|
                    args = edge.horizontal_edge? ? [span_y - (edge.v1.y + (-min_y)), offset - min_x] : [span_y - (offset + (-min_y)), edge.v1.x - min_x]
                    cell = @grid.get_cell(*args)
                    raise "bad edge #{edge}" if cell.edge
                    cell.edge = [edge.v1, edge.v2]
                end
            end
        end

        # @grid.rows.each_with_index do |row, ri|
        #     row.each_with_index do |cell, ci|
        #         x, y = grid_to_point(ri, ci)
        #         cell.covered = cover?(x, y)
        #     end
        # end

        @grid
    end

    def area
        return @area if @area
        @area = grid.each.count(&:inside?)
    end

    def visualize(method=:colored?)
        grid.visualize(method)
    end

    def area_alg
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

# [:edge_type, :included, :covered, :inside?].each do |viz|
#     html = <<-EOS
# <html>
#     <body style="background: #000; color: #fff">
#         <pre style="position: absolute; top: 0; left: 0; opacity: 0.75">
# #{polygon.visualize(viz)}
#         </pre>
#     </body>
# </html>
# EOS
#     File.write(File.join(__dir__, "out-#{viz}.html"), html)
# end

puts "Area: #{polygon.area_alg}"