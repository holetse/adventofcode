Node = Struct.new(:id, :connections) do
  def start?
    id == 'you'
  end

  def end?
    id == 'out'
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
    @index = {}
    
    @nodes.each do |node|
      @index[node.id] = node
      @start = node if node.start?
    end

    super(*args)
  end

  def count_paths
    find_paths.count
  end

  private

  def find_paths(start=@start, path=[])
    new_path = path.dup
    new_path.push(start)
    return [new_path] if start.end?
    start.connections.collect do |connection|
      find_paths(@index[connection], new_path)
    end.flatten(1)
  end

end

r = /([a-z]{3}):\s([a-z\s]+)/

nodes = File.readlines(File.join(__dir__, 'input.txt'), chomp: true).collect do |line|
  parsed = line.match(r)
  Node.new(parsed[1], parsed[2].split(' ')) 
end
nodes.append(Node.new('out', []))

graph = Graph.new(nodes)

puts "total unique paths = #{graph.count_paths}"