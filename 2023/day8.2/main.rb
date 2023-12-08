Node = Struct.new(:id, :left, :right) do
    def end?
        @end ||= id[-1] == 'Z'
    end

    def start?
        @start ||= id[-1] == 'A'
    end
end
Direction = Struct.new(:turn, :next) do
    def left?
        turn == 'L'
    end

    def right?
        turn == 'R'
    end

    def to_s
        "Direction[#{turn} -> #{self.next.turn}]"
    end
end

nodes = {}
directions = []

node_r = /^(?<id>[A-Z]{3}) = \((?<left>[A-Z]{3}), (?<right>[A-Z]{3})\)/
File.open("input.txt") do |file|
    directions = file.gets.strip.split('').collect { |d| Direction.new(d, nil)}
    directions.each_with_index { |d, i| d.next = directions[i + 1] }
    directions.last.next = directions.first
    file.gets
    while !file.eof?
        matches = node_r.match(file.gets)
        nodes[matches[:id]] = Node.new(matches[:id], matches[:left], matches[:right])
    end
end

current_nodes = nodes.values.select(&:start?)
next_direction = directions.first
steps = 0
results = {}
while !current_nodes.empty?
    if next_direction.left?
        current_nodes.collect! { |n| nodes[n.left] }
    else
        current_nodes.collect! { |n| nodes[n.right] }
    end
    next_direction = next_direction.next
    steps += 1
    current_nodes.each { |n| results[n] = steps if n.end? }
    current_nodes.reject!(&:end?)
end

puts "Steps: #{results.values.reduce { |acc, s| acc.lcm(s) }}"