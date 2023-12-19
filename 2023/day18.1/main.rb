Cell = Struct.new(:color, :row, :col, :matrix, :edge, :vertex) do
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
            if [true, false].include?(v)
                v ? '#' : '.'
            else
                v
            end
        end.join('') }.join("\n")
    end
end

class Polygon
    attr_reader :vertices

    Vertex = Struct.new(:x, :y, :color) do
        def point
            [x, y]
        end
    end

    def initialize(*args)
        @vertices = [Vertex.new(0, 0, nil)]
        super(*args)
    end

    def append(x, y, color)
        last = vertices.last
        @vertices.append(Vertex.new(x, y, color))
        @bounds = nil
        @area = nil
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
                col, row = [v.x + (-min_x), span_y - (v.y + (-min_y))] # y-axis flips
                next_col, next_row = [next_v.x + (-min_x), span_y - (next_v.y + (-min_y))]
                vertical = v.x == next_v.x
                @grid.get_cell(row, col).vertex = v
                @grid.get_cell(next_row, next_col).vertex = next_v
                if vertical
                    start, finish = [row, next_row].minmax
                    start.upto(finish) do |i|
                        cell = @grid.get_cell(i, col)
                        cell.color = next_v.color
                        cell.edge = [v, next_v]
                    end
                else
                    start, finish = [col, next_col].minmax
                    start.upto(finish) do |i|
                        cell = @grid.get_cell(row, i)
                        cell.color = next_v.color
                        cell.edge = [v, next_v]
                    end
                end
            end
        end

        @grid
    end

    def area
        return @area if @area
        @area = grid.each.count(&:inside?)
    end

    def visualize(method=:colored?)
        grid.visualize(method)
    end
end

polygon = Polygon.new
point_r = /^(?<dir>[RLDU])\s(?<offset>\d+)\s\(#(?<hex>[a-f0-9]{6})\)$/
File.readlines('input.txt', chomp: true).each do |line|
    point_match = point_r.match(line)
    offset = point_match[:offset].to_i
    point = case point_match[:dir]
    when 'R'
        [offset, 0]
    when 'L'
        [-offset, 0]
    when 'U'
        [0, offset]
    when 'D'
        [0, -offset]
    else
        raise "bad direction: #{line}"
    end
    polygon.append_relative(point[0], point[1], point_match[:hex])
end

puts "Area: #{polygon.area}"