Cell = Struct.new(:value, :row, :col, :matrix, :energized) do
    def space?
        value == '.'
    end

    def clockwise_mirror?
        value == '/'
    end

    def counterclockwise_mirror?
        value == '\\'
    end

    def mirror?
        clockwise_mirror? || counterclockwise_mirror?
    end

    def northsouth_beamsplitter?
        value == '|'
    end

    def eastwest_beamsplitter?
        value == '-'
    end

    def beamsplitter?
        northsouth_beamsplitter? || eastwest_beamsplitter?
    end

    def energized?
        !!(energized&.values&.include?(true))
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

class LightTable < Matrix
    def beamwalk!(row=0, col=0, dir=[0, 1])
        return if row > rows.length - 1 || row < 0 || col > cols.length - 1 || col < 0
        
        cell = get_cell(row, col)

        cell.energized ||= {}
        return if cell.energized[dir]

        cell.energized[dir] = true
        if cell.space?
            beamwalk!(row + dir[0], col + dir[1], dir)
        elsif cell.mirror?
            if cell.clockwise_mirror?
                new_dir = [dir[1] * -1, dir[0] * -1]
            elsif cell.counterclockwise_mirror?
                new_dir = [dir[1], dir[0]]
            else
                raise "bad cell: #{cell}"
            end
            beamwalk!(row + new_dir[0], col + new_dir[1], new_dir)
        elsif cell.beamsplitter?
            if cell.northsouth_beamsplitter?
                if dir[1] != 0
                    beamwalk!(row - 1, col, [-1, 0])
                    beamwalk!(row + 1, col, [1, 0])
                else
                    beamwalk!(row + dir[0], col + dir[1], dir)
                end
            elsif cell.eastwest_beamsplitter?
                if dir[0] != 0
                    beamwalk!(row, col + 1, [0, 1])
                    beamwalk!(row, col - 1, [0, -1])
                else
                    beamwalk!(row + dir[0], col + dir[1], dir)
                end
            else
                raise "bad cell: #{cell}"
            end
        else
            raise "bad cell: #{cell}"
        end
    end

end

rows = []
File.readlines('input.txt', chomp: true).each do |line|
    rows.append(line.split('').each_with_index.collect { |c, i| Cell.new(c, rows.length, i) })
end

table = LightTable.new(rows)
table.each do |cell|
    cell.matrix = table
end

puts table.visualize()
table.beamwalk!
puts table.visualize(:energized?)
puts "Tiles energized: #{table.each.count(&:energized?)}"