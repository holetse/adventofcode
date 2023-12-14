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
    def tilt!(direction = :north)
        rock_rolled = true
        changed = false
        while rock_rolled do
            rock_rolled = false
            each.select(&:round_rock?).each do |rock|
                case direction
                when :east
                    next if rock.col == cols.length - 1
                    next_rock = get_cell(rock.row, rock.col + 1)
                when :west
                    next if rock.col == 0
                    next_rock = get_cell(rock.row, rock.col - 1)
                when :north
                    next if rock.row == 0
                    next_rock = get_cell(rock.row - 1, rock.col)
                when :south
                    next if rock.row == rows.length - 1
                    next_rock = get_cell(rock.row + 1, rock.col)
                else
                    raise "bad direction: #{direction}"
                end
                if next_rock.ground?
                    next_rock.value, rock.value = rock.value, next_rock.value
                    rock_rolled = true
                    changed = true
                end
            end
        end

        changed
    end

    def cycle!(n=1000, report_freq=-1)
        directions = [:north, :west, :south, :east]
        next_direction = 0
        cycles = 0
        report_freq = [(n / 1000), 1].max if report_freq == -1
        old_scores = []
        cycle_detected = nil

        while tilt!(directions[next_direction]) && cycles < n
            next_direction += 1
            if next_direction >= directions.length
                next_direction = 0
                cycles += 1
                old_scores.append(score)
                cycle_detected = detect_cycle(old_scores, [3 - Math.log(old_scores.length, 10).floor, 2].max)
                if cycle_detected
                    puts "#{cycles}: #{old_scores.last} (#{cycle_detected})"
                    break
                else
                    puts "#{cycles}: #{old_scores.last} (#{cycle_detected})" if report_freq && cycles % report_freq == 0
                end
            end
        end

        if cycles < n
            old_scores[(-1 * cycle_detected)..-1][((n - cycles - 1) % cycle_detected)]
        else
            score
        end
    end

    def find_all_index(value, values)
        occurrences = []
        values.each_with_index do |val, i|
            if (val == value)
                occurrences.append(i)
            end
        end

        occurrences
    end

    def find_occurrence_intervals(value, values)
        occurrences = find_all_index(value, values)
        last_occur = nil
        occurrences.product(occurrences).collect { |a, b| (b - a).abs }.reject(&:zero?)
    end

    def is_cycle(period, values)
        a = values[(-2 * period)..((-1 * period) - 1)]
        b = values[(-1 * period)..-1]
        a == b
    end

    def detect_cycle(values, min_cycle_length=2)
        occur_freqs = {}
        values.each_with_index do |score, i|
            occur_intervals = find_occurrence_intervals(score, values).reject { |o| o < min_cycle_length }
            occur_tally = occur_intervals.tally
            if !occur_intervals.empty? && occur_tally.values.max >= 3
                occur_tally.keys.sort.reverse.each { |period| return period if is_cycle(period, values) }
            end
        end
        
        nil
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
puts "cycled for: #{platform.cycle!(1000000000, 1)}"

