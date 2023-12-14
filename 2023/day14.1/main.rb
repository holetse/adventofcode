Cell = Struct.new(:value, :row, :col, :matrix) do
    def round_rock?
        value == 'O'
    end

    def square_rock?
        value == '#'
    end

    def ground?
        value == '.'
    end

    def rock?
        !ground?
    end

    def to_s
        inspect
    end

    def inspect
        "<cell #{value}@(#{row}, #{col})>"
    end
end

class Matrix
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
        rows[row][col]
    end

    def visualize(method = :value)
        rows.collect { |r| r.collect(&method).collect do |v|
            if [true, false].include?(v)
                v ? '#' : '.'
            else
                v
            end
        end.join('') }.join("\n")
    end
end

class Platform < Matrix
    def tilt!
        rock_rolled = true
        while rock_rolled do
            rock_rolled = false
            each.select(&:round_rock?).each do |rock|
                next if rock.row == 0
                north = get_cell(rock.row - 1, rock.col)
                if north.ground?
                    north.value, rock.value = rock.value, north.value
                    rock_rolled = true
                end
            end
        end
    end

    def score
        max_per_rock = rows.length
        each.select(&:round_rock?).sum { |rock| max_per_rock - rock.row }
    end
end

rows = []
File.readlines('input.txt', chomp: true).each do |line|
    rows.append(line.split('').each_with_index.collect { |c, i| Cell.new(c, rows.length, i) })
end

platform = Platform.new(rows)
platform.each do |cell|
    cell.matrix = platform
end

puts platform.visualize
platform.tilt!
puts '', platform.visualize
puts "tilted for: #{platform.score}"

