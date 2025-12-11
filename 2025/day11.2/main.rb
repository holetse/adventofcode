Node = Struct.new(:id, :connections) do
  def start?
    id == 'svr'
  end
  
  def end?
    id == 'out'
  end
  
  def dac?
    id == 'dac'
  end
  
  def fft?
    id == 'fft'
  end
  
  def to_s
    inspect
  end
  
  def inspect
    "<node id=#{id}>"
  end
end

class Graph
  def initialize(nodes, *args)
    @nodes = nodes.dup
    @start = nil
    @end = nil
    @index = {}
    
    @nodes.each do |node|
      @index[node.id] = node
      @start = node if node.start?
      @end = node if node.end?
    end
    
    super(*args)
  end
  
  def count_paths(included_nodes=[], start=@start)
    topological_nodes = sort_graph(@index)
    previous_node = start
    counts = included_nodes.collect do |node|
      count = count_paths_between(previous_node, node, topological_nodes)
      previous_node = node
      count
    end
    counts.append(count_paths_between(previous_node, @end, topological_nodes))
    counts.reduce(&:*)
  end
  
  def dot_export_graph(filename=nil)
    dot = "graph {\n"
    @nodes.each do |node|
      dot += " #{node.id} -- {#{node.connections.join(' ')}}\n"
    end
    dot += "}\n"
    
    if filename
      File.write(filename, dot)
    end
    
    dot
  end
  
  private

  def count_paths_between(start, finish, topological_nodes)
    paths_count = {start => 1}
    topological_nodes.each do |node|
      node.connections.each do |connection|
        paths_count[@index[connection]] ||= 0
        paths_count[@index[connection]] += paths_count[node] || 0
      end
    end

    paths_count[finish]
  end
  
  def sort_graph(nodes)
    return @sorted_nodes if @sorted_nodes
    marks = {}
    unsorted_nodes = Set.new(nodes.values)
    sorted_nodes = []
    visit_node = lambda do |node|
      if marks[node] == :sorted
        return
      elsif marks[node] == :temp
        raise 'cycle detected: not a DAG'
      end
      marks[node] = :temp
      node.connections.each { |edge| visit_node.call(nodes[edge]) }
      marks[node] = :sorted
      unsorted_nodes.delete(node)
      sorted_nodes.prepend(node)
    end
    
    while (node = unsorted_nodes.first)
      visit_node.call(node)
    end
    
    @sorted_nodes = sorted_nodes
  end
end

r = /([a-z]{3}):\s([a-z\s]+)/

nodes = File.readlines(File.join(__dir__, 'input.txt'), chomp: true).collect do |line|
  parsed = line.match(r)
  Node.new(parsed[1], parsed[2].split(' ')) 
end
nodes.append(Node.new('out', []))

graph = Graph.new(nodes)
dac = nodes.find(&:dac?)
fft = nodes.find(&:fft?)

puts "total unique paths = #{graph.count_paths([fft, dac]) + graph.count_paths([dac, fft])}"