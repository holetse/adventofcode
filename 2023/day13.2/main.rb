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
        rows.each { |r| r.each { |c| yield c } }
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

    def visualize(method = :itself)
        rows.collect { |r| r.collect(&method).collect do |v|
            if [true, false].include?(v)
                v ? '#' : '.'
            else
                v
            end
        end.join('') }.join("\n")
    end
end

class Pattern < Matrix
    def initialize(rows, *args)
        @reflection_h = nil
        @reflection_v = nil
        super(rows, *args)
    end

    def vertical_reflection
        return @reflection_v if !@reflection_v.nil?
        
        last_col = []
        cols.each_with_index do |col, i|
            if col == last_col # possible reflection
                reflect_size = [cols.length - i, i].min
                uniform = true
                1.upto(reflect_size - 1) do |offset|
                    if cols[i + offset] != cols[i - offset - 1]
                        uniform = false
                    end
                end
                if uniform
                    @reflection_v = i - 1
                    break
                end
            else
                last_col = col
            end
        end

        @reflection_v
    end

    def has_vertical_reflection?
        !!vertical_reflection
    end

    def horizontal_reflection
        return @reflection_h if !@reflection_h.nil?

        last_row = []
        rows.each_with_index do |row, i|
            if row == last_row # possible reflection
                reflect_size = [rows.length - i, i].min
                uniform = true
                1.upto(reflect_size - 1) do |offset|
                    if rows[i + offset] != rows[i - offset - 1]
                        uniform = false
                    end
                end
                if uniform
                    @reflection_h = i - 1
                    break
                end
            else
                last_row = row
            end
        end
        
        @reflection_h
    end

    def has_horizontal_reflection?
        !!horizontal_reflection
    end

    def has_reflection?
        has_vertical_reflection? || has_horizontal_reflection?
    end

    def smudge_eqls(a, b)
        return [false, false] if a.size != b.size

        smudge = false
        a.each_with_index do |v, i|
            if v != b[i]
                if !smudge
                    smudge = i
                else
                    return [false, false]
                end
            end
        end

        [true, smudge]
    end

    def find_smudge(rows, skip_reflection=nil)
        last_row = []
        rows.each_with_index do |row, i|
            equals, smudge = smudge_eqls(last_row, row)
            if equals && i - 1 != skip_reflection
                reflect_size = [rows.length - i, i].min
                uniform = true
                1.upto(reflect_size - 1) do |offset|
                    a = rows[i + offset]
                    b = rows[i - offset - 1]
                    if smudge
                        if a != b
                            uniform = false
                            break
                        end
                    else
                        equals, smudge = smudge_eqls(a, b)
                        if !equals
                            uniform = false
                            break
                        end
                    end
                end
                if uniform
                    return i - 1
                end
            end
            last_row = row
        end
        nil
    end

    def vertical_smudge
        return @smudge_v if !@smudge_v.nil?
        
        @smudge_v = find_smudge(cols, vertical_reflection)

        @smudge_v
    end

    def has_vertical_smudge?
        !!vertical_smudge
    end

    def horizontal_smudge
        return @smudge_h if !@smudge_h.nil?

        @smudge_h = find_smudge(rows, horizontal_reflection)
        
        @smudge_h
    end

    def has_horizontal_smudge?
        !!horizontal_smudge
    end

    def has_smudge?
        has_vertical_smudge? || has_horizontal_smudge?
    end

    def score
        return 0 if !has_reflection?

        score = if @reflection_h.nil?
            @reflection_v + 1
        else
            (@reflection_h + 1) * 100
        end
    end

    def smudge_score
        return 0 if !has_smudge?

        score = if @smudge_h.nil?
            @smudge_v + 1
        else
            (@smudge_h + 1) * 100
        end
    end
end

patterns = []
rows = []
File.readlines("input.txt", chomp: true).each do |line|
    if line == ''
        patterns.append(Pattern.new(rows))
        rows = []
    else
        rows.append(line.split(''))
    end
end

if !rows.empty?
    patterns.append(Pattern.new(rows))
end

puts "Score: #{patterns.sum(&:score)}"
puts "Smudge Score: #{patterns.sum(&:smudge_score)}"