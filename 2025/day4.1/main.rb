Cell = Struct.new(:value, :row, :col, :matrix) do
  def roll?
    value == '@'
  end

  def empty?
    value == '.'
  end

  def moveable?
    roll? && neighbors.count(&:roll?) < 4
  end

  def neighbors
    offsets = [
        [-1, 0], [0, -1], [0, 1], [1, 0], [-1, -1], [-1, 1], [1, -1], [1, 1]
    ]
    @neighbors ||= offsets.collect { |o| matrix.get_cell(row + o.first, col + o.last) }.compact
  end
  
  def to_s
    inspect
  end

  def inspect
    "<cell #{value}@(#{row}, #{col})>"
  end
end

class CellMatrix
  include Enumerable

  def initialize(rows, *args)
    @rows = rows.dup.freeze
    each do |cell|
      cell.matrix = self
    end
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
end

class Floor < CellMatrix
end

rows = []
File.readlines('input.txt', chomp: true).each do |line|
  rows.append(line.split('').each_with_index.collect { |c, i| Cell.new(c, rows.length, i) })
end

floor = Floor.new(rows)

puts "moveable rolls = #{floor.count(&:moveable?)}"