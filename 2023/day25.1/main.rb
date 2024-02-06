
def count_nodes(from, adjacencies)
    visited = {from => true}
    remaining_nodes = adjacencies[from]
    while next_node = remaining_nodes.shift
        if !visited[next_node]
            visited[next_node] = true
            remaining_nodes.append(*adjacencies[next_node])
        end
    end

    visited.length
end

def trim_edge!(n1, n2, adjacencies)
    adjacencies[n1].reject! { |n| n == n2 }
    adjacencies[n2].reject! { |n| n == n1 }
end

def dot_export_graph(adjacencies, filename=nil)
    visited_edges = {}
    dot = "graph {\n"
    adjacencies.each do |node, other_nodes|
        other_nodes.each do |other_node|
            pair = [node, other_node].sort
            if !visited_edges[pair]
                dot += " #{node} -- #{other_node}\n"
                visited_edges[pair] = true
            end
        end
    end
    dot += "}\n"

    if filename
        File.write(filename, dot)
    end

    dot
end

node_r = /^(?<node>[a-z]+):\s(?<connections>[a-z\s]+)$/
nodes = {}
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    parsed_line = node_r.match(line)
    other_nodes = parsed_line[:connections].split(' ')
    ([parsed_line[:node]] + other_nodes).each do |node|
        nodes[node] ||= []
        nodes[parsed_line[:node]].append(node) unless node == parsed_line[:node]
        nodes[node].append(parsed_line[:node]) unless node == parsed_line[:node]
    end
end

dot_export_graph(nodes, 'input.dot')

trim_edge!('cbl', 'vmq', nodes)
trim_edge!('xgz', 'klk', nodes)
trim_edge!('nvf', 'bvz', nodes)

puts "Graph A: #{count_nodes('cbl', nodes)}"
puts "Graph B: #{count_nodes('vmq', nodes)}"