Record = Struct.new(:fragment, :spans) do

    def consecutive_counts(char, str)
        groups = []
        group_length = nil
    
        str.each_char do |c|
            if c == char
                if group_length
                    group_length += 1
                else
                    group_length = 1
                end
            else
                groups.append(group_length) if group_length
                group_length = nil
            end
        end
    
        groups.append(group_length) if group_length
        groups
    end
    
    def calculate_possibilites(fragment, spans)
        if (unknown = fragment.index('?')).nil?
            if consecutive_counts('#', fragment) == spans
                return 1
            else
                return 0
            end
        end
    
        damaged_fragment = fragment.dup
        damaged_fragment[unknown] = '#'
    
        operational_fragment = fragment.dup
        operational_fragment[unknown] = '.'
        
        return calculate_possibilites(damaged_fragment, spans) + calculate_possibilites(operational_fragment, spans)
    end
    
    def possibilites
        @possibilites ||= calculate_possibilites(fragment, spans)
    end
end

records = []
File.readlines("input.txt", chomp: true).each do |line|
    fragment, spans_str = line.split
    spans = spans_str.split(',').collect(&:to_i)
    records.append(Record.new(fragment, spans))
end


puts "Possibilites: #{records.sum(&:possibilites)}"

