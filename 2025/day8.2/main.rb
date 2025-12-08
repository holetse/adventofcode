JunctionBox = Struct.new(:x, :y, :z, :circuit) do

    def distance_to(box)
      Math.sqrt((x-box.x)**2 + (y-box.y)**2 + (z-box.z)**2)
    end

    def connect_to(circuit)
      self.circuit.remove_box(self) if self.circuit
      self.circuit = circuit
    end

    def to_s
        inspect
    end

    def inspect
        "<box @#{x},#{y},#{z}>"
    end
end

class Circuit

  def initialize(boxes=[], *args)
    @boxes = boxes.dup
    @boxes.each { |box| box.connect_to(self) }
    super(*args)
  end

  def add_box(box)
    box.connect_to(self)
    boxes << box
  end

  def remove_box(box)
    boxes.delete(box)
  end

  def include?(box)
    boxes.include?(box)
  end

  def connect_to(circuit)
    to_add = circuit.boxes.dup # avoid modifying array during iteration
    to_add.each { |box| add_box(box) }
  end

  def empty?
    boxes.empty?
  end

  def size
    boxes.size
  end

  def to_s
      inspect
  end

  def inspect
      "<circuit {#{@boxes}}>"
  end

  protected

  attr_reader :boxes

end

def every_pair(objs)
  pairs = []
  unpaired = objs.dup
  while obj = unpaired.pop do
    pairs_for_obj = unpaired.collect { |other| [obj, other] }
    pairs.push(*pairs_for_obj)
  end
  pairs
end

r = /(\d+),(\d+),(\d+)/
boxes = File.readlines(File.join(__dir__, 'input.txt'), chomp: true).collect do |line|
  match = line.match(r)
  JunctionBox.new(*(match[1..3].collect(&:to_i)))
end

circuits = boxes.collect { |box| Circuit.new([box]) }

pairs = every_pair(boxes).sort { |a, b| a[0].distance_to(a[1]) <=> b[0].distance_to(b[1]) }
pair = nil
while circuits.length > 1 do
  pair = pairs.shift
  pair_circuits = circuits.find_all { |circuit| circuit.include?(pair[0]) || circuit.include?(pair[1]) }
  if pair_circuits.length > 1
    pair_circuits[0].connect_to(pair_circuits[1])
    circuits.delete(pair_circuits[1])
  end
end

puts "last pairs X coordinates (#{pair[0].x}, #{pair[1].x}) multiplied = #{pair[0].x * pair[1].x}"