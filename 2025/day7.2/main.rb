Cell = Struct.new(:value, :row, :col, :matrix, :timeline_count) do

  def start?
    value == 'S'
  end

  def empty?
    value == '.' || start?
  end

  def splitter?
    value == '^'
  end

  def beam?
    value == '|'
  end

  def propagator?
    beam? || start?
  end

  def propagate!(from)
    if empty? || beam?
      self.value = '|'
      if empty?
        self.timeline_count = from.timeline_count
      else
        self.timeline_count ||= 0
        self.timeline_count += from.timeline_count
      end
    elsif splitter?
      [left, right].compact.each { |cell| cell.propagate!(from)}
    else
      raise "unknown cell value #{self}"
    end
  end

  def below
    @below ||= matrix.get_cell(row + 1, col)
  end

  def left
    @left ||= matrix.get_cell(row, col - 1)
  end

  def right
    @right ||= matrix.get_cell(row, col + 1)
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

class QuantumTachyonManifold < CellMatrix
  def total_timelines
    propagate_beams
  end

  def start
    @start ||= find(&:start?)
  end

  private

  def propagate_beams
    start.timeline_count = 1
    rows.each do |row|
      row.find_all(&:propagator?).each do |cell|
        if below = cell.below
          below.propagate!(cell)
        end
      end
    end
    rows.last.sum { |cell| cell.beam? ? cell.timeline_count : 0}
  end
end

rows = []
File.readlines('input.txt', chomp: true).each do |line|
    rows.append(line.chars.each_with_index.collect { |c, i| Cell.new(c, rows.length, i) })
end

manifold = QuantumTachyonManifold.new(rows)

puts "total timelines = #{manifold.total_timelines}"
