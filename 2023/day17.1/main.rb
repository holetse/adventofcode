require 'pqueue'

Cell = Struct.new(:value, :row, :col, :matrix) do
    def neighbors(exclude_dirs=[])
        offsets = [
            [-1, 0], [0, -1], [0, 1], [1, 0]
        ]
        (offsets - exclude_dirs).collect { |o| matrix.get_cell(row + o.first, col + o.last) }.compact
    end

    def direction(cell)
        [cell.row - row, cell.col - col]
    end
    
    def to_s
        inspect
    end

    def inspect
        "<cell #{value}@(#{row}, #{col})>"
    end
end

Node = Struct.new(:weight, :step, :direction, :cell)

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

class City < Matrix

    MUST_TURN_STEPS = 3

    def cartpath_fast(start=[0,0], finish=[rows.length - 1, cols.length - 1])
        pathtree = cart_pathtree(start)
        pathtree[get_cell(*finish)]
    end

    def cart_buildnodes(start=[0,0], turn_after = MUST_TURN_STEPS)
        start_cell = get_cell(*start)
        start_node = Node.new(start_cell.value, 0, nil, start_cell)
        remaining = [start_node]
        visited = {}
        neighbor_nodes = {}

        while (visiting = remaining.shift)
            if !visited[visiting]
                visited[visiting] = true
                neighbors = visiting.cell.neighbors([visiting.direction, [(visiting.direction&.first || 0) * -1, (visiting.direction&.last || 0) * -1]]).collect do |neighbor|
                    neighbor_dir = visiting.cell.direction(neighbor)
                    nodes = []
                    last_weight = 0
                    0.upto(turn_after - 1) do |step|
                        next_neighbor = get_cell(neighbor.row + (step * neighbor_dir.first), neighbor.col + (step * neighbor_dir.last))
                        if next_neighbor
                            last_weight += next_neighbor.value
                            nodes.append(Node.new(last_weight, step + 1, neighbor_dir, next_neighbor))
                        end
                    end
                    nodes
                end.flatten
                neighbor_nodes[visiting] = neighbors
                remaining.append(*neighbors)
            end
        end

        [visited.keys, neighbor_nodes]
    end

    def cart_pathtree(start=[0,0], turn_after = MUST_TURN_STEPS)
        distances = {}
        nodes, neighbors = cart_buildnodes(start, turn_after)

        queue = PQueue.new { |a, b| distances[b] <=> distances[a] } # lowest first
        nodes.each do |node|
            if node.cell.row == start.first && node.cell.col == start.last
                distances[node] = 0
                queue.push(node)
            else
                distances[node] = Float::INFINITY
            end
        end

        while (node = queue.pop)
            neighbors[node].each do |neighbor|
                distance = distances[node] + neighbor.weight
                if distance < distances[neighbor]
                    distances[neighbor] = distance
                    queue.push(neighbor)
                end
            end
        end

        distances.reduce({}) do |acc, pair|
            node, distance = pair
            acc[node.cell] = [distance, acc[node.cell]].compact.min
            acc
        end
    end

    def visualize_path(path)
        rows.collect { |r| r.collect do |cell|
            if i = path.index(cell)
                last_cell = path[i - 1] || cell
                dir = [cell.row - last_cell.row, cell.col - last_cell.col]
                case dir
                when [1, 0]
                    'v'
                when [-1, 0]
                    '^'
                when [0, 1]
                    '>'
                when [0, -1]
                    '<'
                else
                    '#'
                end
            else
                cell.value
            end
        end.join('') }.join("\n")
    end

end

rows = []
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    rows.append(line.split('').each_with_index.collect { |c, i| Cell.new(c.to_i, rows.length, i) })
end

city = City.new(rows)
city.each do |cell|
    cell.matrix = city
end

puts city.label_figure(city.visualize), ''

fast_heatloss = city.cartpath_fast
puts "Heatloss: #{fast_heatloss}"