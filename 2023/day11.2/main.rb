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

EXPANSION_CONSTANT = 1000000

class SparseMatrix
    def initialize(cells, *args)
        @row_count = cells.collect(&:row).max
        @col_count = cells.collect(&:col).max
        @cells = cells.dup.freeze
        super(*args)
    end

    def cells
        @cells
    end

    def expand!
        zero_cols = (0..@col_count).to_a - cells.collect(&:col)
        zero_rows = (0..@row_count).to_a - cells.collect(&:row)

        cells.each do |cell|
            delta_col = (zero_cols.select {|c| c < cell.col }.length) * (EXPANSION_CONSTANT - 1)
            delta_row = (zero_rows.select {|r| r < cell.row }.length) * (EXPANSION_CONSTANT - 1)
            cell.col += delta_col
            cell.row += delta_row
        end
    end
end

if __FILE__ == $0
    cells = []
    File.readlines("input.txt", chomp: true).each_with_index do |line, row|
        line.split('').each_with_index do |value, col|
            cells.append(Cell.new(true, row, col)) if value == '#'
        end
    end
    matrix = SparseMatrix.new(cells)
    
    matrix.expand!

    galaxies = matrix.cells
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