Cell = Struct.new(:value, :row, :col, :matrix) do

  def space?
    value == ' '
  end

  def operator?
    value == '+' || value == '*'
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

class Problem < CellMatrix

  def answer
    @answer ||= numbers.reduce(&operation)
  end

  def operation
    @operation ||= rows.last.find(&:operator?).value.to_sym
  end

  def numbers
    @numbers ||= cols.collect { |col| col.reduce('') {|str, cell| cell.operator? ? str : str + cell.value }.to_i }
  end

end

class Worksheet < CellMatrix

  def initialize(*args)
    super(*args)
    @problems = split_into_problems
  end

  def total
    @problems.sum(&:answer)
  end

  private

  def split_into_problems
    problem_ranges = []
    last_problem_separator = -1
    cols.each_with_index do |col, i|
      if col.count(&:space?) == col.length
        problem_ranges << ((last_problem_separator + 1)..(i - 1))
        last_problem_separator = i
      end
    end
    problem_ranges << ((last_problem_separator + 1)..(cols.length - 1))
    problem_ranges.collect do |col_range|
      sub_rows = rows.collect do |row|
        row[col_range]
      end
      Problem.new(sub_rows)
    end
  end
end

rows = []
File.readlines('input.txt', chomp: true).collect do |line|
  rows.append(line.chars.each_with_index.collect { |c, i| Cell.new(c, rows.length, i) })
end

worksheet = Worksheet.new(rows)

puts "grand total = #{worksheet.total}"
