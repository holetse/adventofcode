require 'matrix'


Cell = Struct.new(:value, :row, :col, :matrix, :reachable) do
    def start?
        value == 'S'
    end

    def ground?
        value == '.' || start?
    end

    def rock?
        value == '#'
    end

    def reachable?
        !!reachable
    end

    def neighbors
        offsets = [
            [-1, 0], [0, -1], [0, 1], [1, 0]
        ]
        @neighbors ||= offsets.collect { |o| matrix.get_cell(row + o.first, col + o.last) }.compact
    end
    
    def to_s
        inspect
    end

    def inspect
        "<cell #{value}@(#{row}, #{col})>"
    end
end

class CellMatrix
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

    def visualize(method = :value, options = {})
        rows.collect { |r| r.collect(&method).collect do |v|
            if [true, false].include?(v)
                v ? '#' : '.'
            else
                v
            end
        end.join('') }.join("\n")
    end

    def label_figure(figure)
        row_inner_margin = 2
        row_outer_margin = 1
        col_inner_margin = 1
        col_outer_margin = 1
        rows = figure.split("\n")
        rows_length_digits = rows.length.to_s.length
        columns_length = rows.max {|a, b| a.length <=> b.length}.length
        columns_length_digits = columns_length.to_s.length
        row_header_len = rows_length_digits + row_inner_margin + row_outer_margin
        
        header_rows = Array.new(columns_length_digits + col_inner_margin + col_outer_margin, ' ' * row_header_len)
        0.upto(columns_length - 1) do |col|
            digits = col.digits
            padded_digits = digits.reverse + Array.new(columns_length_digits - digits.length, ' ')
            header_rows.each_with_index do |row, ri|
                if ri < col_outer_margin || ri >= col_outer_margin + columns_length_digits
                    header_rows[ri] += ' '
                else
                    header_rows[ri] += padded_digits.pop.to_s
                end
            end
        end
        header_rows.join("\n") + "\n" + rows.each_with_index.collect do |row, i|
            i_str = i.to_s
            (' ' * row_outer_margin) + (' ' * (rows_length_digits - i_str.length)) + i_str + (' ' * row_inner_margin) + row
        end.join("\n")
    end
end

class Garden < CellMatrix
    def wander_from(starting_points)
        ending_points = Set.new
        starting_points.each do |cell|
            ending_points.merge(cell.neighbors.select(&:ground?))
        end
        ending_points
    end

    def wander(steps)
        start = each.find(&:start?)
        visited = Set.new([start])
        1.upto(steps) do |step|
            visited = wander_from(visited)
        end
        visited.to_a
    end
end

class SparseGarden
    def initialize(garden, *args)
        @tile = Garden.new(garden.rows)
        start_cell = @tile.find(&:start?)
        @origin = [0, 0]
        tile_length = @tile.rows.length
        tile_width = @tile.cols.length
        @dimensions = [tile_length, tile_width]
        @start = [(tile_width - 1) / 2, (tile_length - 1) / 2]


        super(*args)
    end

    def coordinates_to_grid(x, y)
        row = -(y + (@origin.first + 1)) % @dimensions.first
        col = (x + @origin.last) % @dimensions.last

        [row, col]
    end

    def neighbors_coordinates(x, y)
        offsets = [
            [-1, 0], [0, -1], [0, 1], [1, 0]
        ]

        offsets.collect { |dx, dy| [x + dx, y + dy] }
    end

    def get_cell(x, y, limit = false)
        return nil if limit && (x < @origin[0] || x >= @dimensions[0] || y < @origin[1] || y >= @dimensions[1])
        row, col = coordinates_to_grid(x, y)
        @tile.get_cell(row, col)
    end

    def wander_from(starting_points, limit = false)
        ending_points = Set.new
        starting_points.each do |x, y|
            neighbors = neighbors_coordinates(x, y).select { |coords| get_cell(*coords, limit)&.ground? }
            ending_points.merge(neighbors)
        end
        ending_points
    end

    def wander(steps, start = @start, limit = false)
        visited = Set.new([start])
        visited_at = {}
        1.upto(steps) do |step|
            old_visited = visited
            visited = wander_from(visited, limit)
            break if old_visited == visited
        end
       visited.to_a
    end

    def wander_fast(steps, start = @start, limit = false)
        visited = Set.new()
        visited_at = {}
        remaining = [[start, 0]]
        while (node, taken = remaining.shift) && taken <= steps
            x, y = node
            neighbors = neighbors_coordinates(x, y).select { |coords| get_cell(*coords, limit)&.ground? }
            neighbors.each do |n|
                if !visited.include?(n)
                    visited.add(n)
                    visited_at[n] = taken
                    remaining.append([n, taken + 1])
                end
            end
        end

        Hash[visited_at.select{ |p, b| b.odd? != steps.to_i.odd? }.to_a]
    end

    def wander_fast_cumulative(steps, start = @start, limit = false)
        visited = Set.new()
        remaining = [[start, 0]]
        steps = Array(steps).collect(&:to_i)
        results = []
        visited_at = {}
        count_even = 0
        count_odd = 0
        while (node, taken = remaining.shift)
            if taken > steps.first
                results.append(steps.first.odd? ? count_even : count_odd)
                steps.shift
                raise "out of steps" if steps.empty?
            end
            x, y = node
            neighbors = neighbors_coordinates(x, y).select { |coords| get_cell(*coords, limit)&.ground? }
            neighbors.each do |n|
                if !visited.include?(n)
                    visited.add(n)
                    visited_at[n] = taken
                    if taken.odd?
                        count_odd += 1
                    else
                        count_even += 1
                    end
                    remaining.append([n, taken + 1]) if taken + 1 <= steps.last
                end
            end
        end

        results.append(steps.first.odd? ? count_even : count_odd)

        results
    end

    def wander_far(steps, start = @start) 
        h, w = @dimensions
        n = (steps - start.first) / w.to_r
        
        raise 'general solution does not apply' if w != h || n.denominator != 1

        p = ->(s, n) { wander_fast(n, s, true).length }
        rem = steps - (n * w)
        st = w - 1
        sa = w + rem - 1
        sb = rem - 1

        quads = [[0, 0], [0, h - 1], [w - 1, 0], [w - 1, h - 1]]

        a = quads.collect { |s| p.call(s, sa) }.sum
        b = quads.collect { |s| p.call(s, sb) }.sum
        t = p.call([0, start[1]], st) + p.call([start[0], 0], st) + p.call([w - 1, start[1]], st) + p.call([start[0], h - 1], st)

        o = p.call(start, 3 * w)
        e = p.call(start, (3 * w) + 1)

        ((n - 1) * (n - 1) * o) + (n * n * e) + ((n - 1) * a) + (n * b) + t
    end

    def wander_poly(steps)
        h, w = @dimensions
        n = (steps - @start.first) / w.to_r
        
        raise 'poly solution does not apply' if w != h || n.denominator != 1
        
        @constants ||= calculate_poly_constants
        a, b, c = @constants

        (a * (steps * steps)) + (b * steps) + c
    end

    def calculate_steps(n)
        h, w = @dimensions
        (n * w) + @start.first
    end

    def calculate_poly_constants(ns=[1, 2, 3, 4])
        h, w = @dimensions

        raise 'poly solution does not apply' if w != h || @start.first != @start.last

        steps = ns.collect do |n|
            calculate_steps(n)
        end
        reached = wander_fast_cumulative(steps, @start)

        polynomial_regression(steps, reached, 2)
    end

    def polynomial_regression(x, y, degree)
        rows = x.map do |i|
            (0..degree).map { |power| (i ** power).to_r }
        end
        mx = Matrix.rows(rows)
        my = Matrix.columns([y])
        ((mx.transpose * mx).inv * mx.transpose * my).transpose.row(0).to_a.reverse
    end
    
    def visualize(points, start=@start, window=[points.collect(&:first).minmax, points.collect(&:last).minmax], margin=1)
        min_x, max_x = window.first
        min_y, max_y = window.last

        (max_y + margin).downto(min_y - margin).collect do |y|
            (min_x - margin).upto(max_x + margin).collect do |x|
                if x == start.first && y == start.last
                    'S'
                elsif points.include?([x, y])
                    'O'
                else
                    cell = get_cell(x, y)
                    cell.rock? ? '#' : '.'
                end
            end.join('')
        end.join("\n")
    end
end

rows = []
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    rows.append(line.split('').each_with_index.collect { |c, i| Cell.new(c, rows.length, i) })
end

garden = Garden.new(rows)
garden.each do |cell|
    cell.matrix = garden
end

gardens = SparseGarden.new(garden)


puts "Reachable: #{gardens.wander_far(26501365).to_i}"