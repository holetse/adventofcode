Record = Struct.new(:fragment, :spans) do

    def calculate_possibilites(string, groups, preceeding='')
        key = [string, groups, preceeding]
        @calculate_possibilites ||= {}
        return @calculate_possibilites[key] if @calculate_possibilites[key]

        group = groups[0]
        return 0 if string.length < group
    
        substr = string[0..(group - 1)]
        remaining = string[group..]
        preceeding_hash = preceeding.include?('#')
    
        possibilites = if substr.include?('.')
            0
        elsif (groups.length == 1 && remaining.include?('#')) || (remaining[0] || '') == '#'
            0
        elsif preceeding_hash
            0
        else
            1
        end
    
        if possibilites == 1 && groups.length > 1
            possibilites = calculate_possibilites(string[(groups[0] + 1)..] || '', groups[1..], preceeding)
        end
    
        other_possibilities = if preceeding_hash
            0
        else
            calculate_possibilites(string[1..-1], groups, (preceeding[-1..] || '') + string[0])
        end

        @calculate_possibilites[key] = possibilites + other_possibilities
    end

    def possibilites
        @possibilites ||= calculate_possibilites(fragment, spans)
    end
end


records = []
File.readlines('input.txt', chomp: true).each do |line|
    fragment, spans_str = line.split
    fragment = ([fragment] * 5).join('?')
    spans_str = ([spans_str] * 5).join(',')
    spans = spans_str.split(',').collect(&:to_i)
    records.append(Record.new(fragment, spans))
end


puts "Possibilites: #{records.sum do |r|
    $stdout.print("#{r.fragment}: ")
    puts r.possibilites
    r.possibilites
end}"