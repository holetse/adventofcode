Cell = Struct.new(:value, :row, :col, :matrix) do
    def start?
        value == 'S'
    end

    def ground?
        value == '.'
    end

    def pipe?
        !start? && !ground?
    end

    def connect?(cell)
        connections.include?(cell)
    end

    def connections
        return [] unless pipe?
        dirs = case value
        when '|'
            [[-1, 0], [1, 0]]
        when '-'
            [[0, -1], [0, 1]]
        when 'L'
            [[-1, 0], [0, 1]]
        when 'J'
            [[-1, 0], [0, -1]]
        when 'F'
            [[1, 0], [0, 1]]
        when '7'
            [[1, 0], [0, -1]]
        end
        @connections ||= dirs.collect { |dir| matrix.get_cell(row + dir.first, col + dir.last) }
    end

    def neighbors
        offets = [
            [-1, 0], [0, -1], [0, 1], [1, 0]
        ]
        @neighbors ||= offets.collect { |o| matrix.get_cell(row + o.first, col + o.last) }
    end

    def to_s
        inspect
    end

    def inspect
        "<cell #{value}@(#{row}, #{col})>"
    end
end

Matrix = Struct.new(:rows) do
    def start
        @start ||= rows.reduce(nil) { |acc, r| acc ||= r.find(&:start?) }
    end

    def get_cell(row, col)
        rows[row][col]
    end
end

if __FILE__ == $0
    matrix = Matrix.new([])
    File.readlines("input.txt", chomp: true).each_with_index do |line, row|
        cells = []
        line.split('').each_with_index do |value, col|
            cells.append(Cell.new(value, row, col, matrix))
        end
        matrix.rows.append(cells)
    end

    steps = 1
    cell = matrix.start.neighbors.find {|c| c.connect?(matrix.start) }
    last_cell = matrix.start
    while !cell.start?
        next_cell = cell.connections.find { |c| c != last_cell }
        last_cell = cell
        cell = next_cell
        steps += 1
    end

    puts "Midpoint: #{steps / 2}"
end