Cell = Struct.new(:galaxy, :row, :col) do
    def galaxy?
        !!galaxy
    end

    def space?
        !galaxy?
    end

    def distance(cell)
        return nil if !cell.galaxy? || !galaxy?

        (cell.row - row).abs + (cell.col - col).abs
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
        rows.each { |r| r.each { |c| yield c } }
    end

    def each_row
        rows.each { |r| yield r }
    end

    def each_col
        cols.each { |c| yield c }
    end

    def get_cell(row, col)
        rows[row][col]
    end

    def visualize(method = :galaxy)
        rows.collect { |r| r.collect(&method).collect do |v|
            if [true, false].include?(v)
                v ? '#' : '.'
            else
                v
            end
        end.join('') }.join("\n")
    end

    def expand!
        zero_cols = cols.each_with_index.reduce([]) { |acc, ci | ci.first.find(&:galaxy?) ? acc : acc << ci.last }

        new_rows = []
        rows.each_with_index do |row, ri|
            new_row = []

            cols.each_with_index do |col, ci|
                new_row << col[ri]
                new_row << col[ri].dup if zero_cols.include?(ci)
            end

            new_rows << new_row
            new_rows << new_row.dup if !row.find(&:galaxy?)
        end

        new_rows.each_with_index do |row, ri|
            row.each_with_index do |cell, ci|
                cell.row = ri
                cell.col = ci
            end
        end

        @rows = new_rows.freeze
        @cols = nil
    end
end

if __FILE__ == $0
    matrix = nil
    rows = []
    File.readlines("input.txt", chomp: true).each_with_index do |line, row|
        cells = []
        line.split('').each_with_index do |value, col|
            cells.append(Cell.new(value == '#', row, col))
        end
        rows.append(cells)
    end
    matrix = Matrix.new(rows)
    
    matrix.expand!

    galaxies = matrix.select(&:galaxy?)
    distance_sum = 0
    distances = {}
    galaxies.each do |a|
        distances[a] ||= {}
        galaxies.each do |b|
            distances[b] ||= {}
            next if a == b || distances[b][a]
            distance = a.distance(b)
            distance_sum += distance
            distances[a][b] = distance
            distances[b][a] = distance
        end
    end

    puts "Distance: #{distance_sum.to_i}"
end