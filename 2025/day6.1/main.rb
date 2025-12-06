Cell = Struct.new(:value, :row, :col, :matrix) do
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

class Worksheet < CellMatrix
  def total
    cols.sum { |c| calculate(c) }
  end

  private

  def calculate(col)
    operation = col.last.value.to_sym
    values = col[0..-2].collect(&:value).collect(&:to_i)
    values.reduce(&operation)
  end
end

rows = []
File.readlines('input.txt', chomp: true).collect do |line|
  rows.append(line.strip.split(/\s+/).each_with_index.collect { |c, i| Cell.new(c, rows.length, i) })
end

worksheet = Worksheet.new(rows)

puts "grand total = #{worksheet.total}"
