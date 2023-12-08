Node = Struct.new(:id, :left, :right)
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

current_node = nodes['AAA']
next_direction = directions.first
steps = 0
while current_node.id != 'ZZZ'
    if next_direction.left?
        current_node = nodes[current_node.left]
    else
        current_node = nodes[current_node.right]
    end
    next_direction = next_direction.next
    steps += 1
end

puts "Steps: #{steps}"