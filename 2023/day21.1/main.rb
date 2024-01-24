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

class Garden < Matrix
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

rows = []
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    rows.append(line.split('').each_with_index.collect { |c, i| Cell.new(c, rows.length, i) })
end

garden = Garden.new(rows)
garden.each do |cell|
    cell.matrix = garden
end

puts garden.label_figure(garden.visualize)

garden.wander(64).each do |cell|
    cell.reachable = true
end

puts "Plots reachable: #{garden.each.count(&:reachable?)}"
puts garden.label_figure(garden.visualize(:reachable?))