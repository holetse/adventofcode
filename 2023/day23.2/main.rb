Cell = Struct.new(:value, :row, :col) do

    def walkable?
        !forest?
    end

    def slope?
        !slope_direction.nil?
    end

    def slope_direction
        {
            '>' => [0, 1],
            '<' => [0, -1],
            '^' => [-1, 0],
            'v' => [1, 0]
        }[value]
    end

    def ground?
        value == '.'
    end

    def forest?
        value == '#'
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

Node = Struct.new(:cell)
Edge = Struct.new(:from, :to, :weight)

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

    def neighbors(cell, exclude_dirs=[])
        offsets = [
            [-1, 0], [0, -1], [0, 1], [1, 0]
        ]
        (offsets - exclude_dirs).collect { |o| get_cell(cell.row + o.first, cell.col + o.last) }.compact
    end

    def neighbor(cell, dir)
        get_cell(cell.row + dir.first, cell.col + dir.last)
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

class Maze < Matrix

    def start_cell
        @start_cell ||= rows.first.find(&:ground?)
    end

    def end_cell
        @end_cell ||= rows.last.find(&:ground?)
    end

    def intersection?(cell)
        @intersections ||= {}
        return @intersections[cell] if @intersections.has_key?(cell)
    
        @intersections[cell] = if cell.ground?
            neighbors(cell).select(&:walkable?).length > 2
        else
            false
        end
    end

    def visualize_points(points, char='O')
        rows.collect { |r| r.collect do |cell|
            if points.include?(cell)
                char
            else
                cell.value
            end
        end.join('') }.join("\n")
    end

    def intersections
        each.select { |c| intersection?(c) }
    end

    def merge_intersection?(cell)
        return false if !intersection?(cell)

        intersection_paths(cell).count {|slope, dir| slope == dir} == 1
    end

    def fork_intersection?(cell)
        intersection?(cell) && !merge_intersection?(cell)
    end

    def intersection_paths(cell)
        return nil if !intersection?(cell)

        @intersection_paths ||= {}
        @intersection_paths[cell] ||= neighbors(cell).collect { |c| [c.slope_direction, cell.direction(c)]}
        @intersection_paths[cell]
    end

    def build_graph
        start_node = Node.new(start_cell)
        end_node = Node.new(end_cell)
        nodes = [start_node, end_node]
        adjacencies = {end_node => []}
        walked = Set.new
        next_cell = start_cell
        remaining_intersections = []
        last_cell = nil
        last_node = start_node
        steps = 0
        while next_cell
            walked.add(next_cell)
            last_cell = next_cell
            if intersection?(next_cell)
                new_node = Node.new(next_cell)
                adjacencies[last_node] ||= []
                adjacencies[last_node].append(Edge.new(last_node, new_node, steps))
                nodes.append(new_node)
                available = intersection_paths(next_cell).collect {|slope, dir| neighbor(next_cell, dir) if slope && slope == dir }
                remaining_intersections.append(*(available.compact.select {|c| !walked.include?(c) }.collect {|c| [c, new_node]}))
                next_cell, last_node = remaining_intersections.shift
                steps = 1
            else
                next_cell = neighbors(next_cell).select { |c| c.walkable? && !walked.include?(c) }.first
                steps += 1
            end

            if !next_cell
                node_cell = neighbors(last_cell).find {|c| intersection?(c) }
                if !node_cell # we are at the end, go back one step
                    node_cell = last_cell
                    steps -= 1
                end
                adjacencies[last_node] ||= []
                adjacencies[last_node].append(Edge.new(last_node, nodes.find { |n| n.cell == node_cell }, steps))
                next_cell, last_node = remaining_intersections.shift
                steps = 1
            end
        end

        [nodes, adjacencies, walked]
    end

    def remove_slopes_from_graph(nodes, adjacencies)
        expanded_adjacencies = {}
        expanded_nodes = nodes.dup

        # add edges in other direction
        adjacencies.each do |node, edges|
            edges.each do |edge|
                new_edge = Edge.new(edge.to, edge.from, edge.weight)
                expanded_adjacencies[new_edge.from] ||= []
                expanded_adjacencies[new_edge.from].append(new_edge)
                new_edge
            end
            expanded_adjacencies[node] ||= []
            expanded_adjacencies[node].append(*edges)
        end
        

        [expanded_nodes, expanded_adjacencies]
    end

    def longest_path_dfs(nodes, adjacencies, source = nil, sink = nil, visited = nil)
        source ||= nodes.find { |n| n.cell == start_cell }
        sink ||= nodes.find { |n| n.cell == end_cell }

        return [0, []] if sink == source

        visited = visited&.dup || Set.new
        visited.add(source)

        options = adjacencies[source].reject { |e| visited.include?(e.to) }.collect do |edge|
            deep_max, deep_path = longest_path_dfs(nodes, adjacencies, edge.to, sink, visited)
            if deep_max && deep_path
                [edge.weight + deep_max, deep_path.prepend(edge)]
            else
                nil
            end
        end.compact

        options.max { |a, b| a.first <=> b.first } || [nil, nil]
    end
end

rows = []
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    rows.append(line.split('').each_with_index.collect { |c, i| Cell.new(c, rows.length, i) })
end

maze = Maze.new(rows)
puts maze.label_figure(maze.visualize)
nodes, adjacencies, points = maze.build_graph()
expanded_nodes, expanded_adjacencies = maze.remove_slopes_from_graph(nodes, adjacencies)
weight, path = maze.longest_path_dfs(expanded_nodes, expanded_adjacencies)
puts "Longest Path: #{weight}"
