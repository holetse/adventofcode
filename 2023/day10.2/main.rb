Cell = Struct.new(:value, :row, :col, :matrix, :route) do
    def start?
        value == 'S'
    end

    def ground?
        value == '.'
    end

    def pipe?
        !start? && !ground?
    end

    def route?
        start? || !route.nil?
    end

    def inside?
        return false if route?
        return @inside unless @inside.nil?

        crossed = 0
        is_edge = false
        started_dir = nil
        matrix.rows[row][0..col].each do |cell|
            if !is_edge && cell.route?
                is_edge = true
                started_dir = cell.connection_directions.find { |dir| !dir.first.zero? }
            end
            if is_edge && !cell.connection_directions.include?([0, 1])
                crossed += 1 if cell.connection_directions.include?([started_dir.first * -1, 0])
                is_edge = false
                started_dir = nil
            end
        end
        raise "bad edge" if is_edge
        @inside = crossed.odd?
    end

    def connect?(cell)
        connections.include?(cell)
    end

    def connection_directions
        @dirs ||= case value
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
        when 'S'
            neighbors.find_all {|c| c.connect?(self) }.collect { |c| [c.row - row, c.col - col] }
        else
            []
        end
    end

    def connections
        @connections ||= connection_directions.collect { |dir| matrix.get_cell(row + dir.first, col + dir.last) }
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
        "<cell #{value}@(#{row}, #{col})#{'R' if route?}>"
    end
end

Route = Struct.new(:cells) do
    def add_cell(cell)
        cells.append(cell)
        cell.route = self
    end
end

Matrix = Struct.new(:rows) do
    include Enumerable
    def start
        @start ||= rows.reduce(nil) { |acc, r| acc ||= r.find(&:start?) }
    end

    def get_cell(row, col)
        rows[row][col]
    end

    def each
        rows.each { |r| r.each { |c| yield c } }
    end

    def visualize(method = :value)
        rows.collect { |r| r.collect(&method).collect do |v|
            if [true, false].include?(v)
                v ? '#' : '.'
            else
                v
            end
        end.join('') }.join("\n")
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

    route = Route.new([])
    route.add_cell(matrix.start)
    steps = 1
    cell = matrix.start.connections.first
    last_cell = matrix.start
    while !cell.start?
        route.add_cell(cell)
        next_cell = cell.connections.find { |c| c != last_cell }
        last_cell = cell
        cell = next_cell
        steps += 1
    end

    puts "Inside: #{matrix.count(&:inside?)}"
end