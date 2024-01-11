PartRange = Struct.new(:x, :m, :a, :s, :state) do
    def accepted?
        state == 'A'
    end

    def rejected?
        state == 'R'
    end

    def halted?
        accepted? || rejected?
    end

    def size
        x.size * m.size * a.size * s.size
    end
end

Transition = Struct.new(:category, :condition, :threshold, :state) do
    def gt?
        condition == '>'
    end

    def lt?
        condition == '<'
    end

    def default?
        condition.nil?
    end

    def apply(part)
        new_part = part.dup
        new_part.state = state
        remainder = part.dup

        if gt?
            new_part[category] = (threshold + 1)..(part[category].end)
            remainder[category] = (part[category].begin)..threshold
        elsif lt?
            new_part[category] = (part[category].begin)..(threshold - 1)
            remainder[category] = threshold..(part[category].end)
        elsif default?
            remainder = nil
        else
            raise "bad condition: #{self}"
        end

        return new_part, remainder
    end
end

State = Struct.new(:name, :transitions) do
    def halt?
        transitions.length == 0
    end

    def next_states(part)
        return [part] if halt?

        remainder = part
        parts = []
        transitions.each do |t|
            new_part, remainder = t.apply(remainder)
            parts.append(new_part)
        end

        raise "bad remainder: #{remainder}" if remainder
        parts
    end
end

MIN_THRESHOLD = 1
MAX_THRESHOLD = 4000

states = {
}

state_r = /(?<name>[a-z]+){(?<rules>.*)}/
rule_r = /((?<category>[xmas])(?<condition>[<>])(?<threshold>\d+):)?(?<state>[AR]|[a-z]+)/

File.open(File.join(__dir__, 'input.txt')) do |file|
    while (line = file.gets(chomp: true)).length > 0
        parsed = state_r.match(line)
        transitions = parsed[:rules].split(',').collect {|r| rule_r.match(r)}.collect do |rule|
            Transition.new(rule[:category], rule[:condition], rule[:threshold]&.to_i, rule[:state])
        end
        state = State.new(parsed[:name], transitions)
        states[state.name] = state
    end
end

parts = [PartRange.new(MIN_THRESHOLD..MAX_THRESHOLD, MIN_THRESHOLD..MAX_THRESHOLD, MIN_THRESHOLD..MAX_THRESHOLD, MIN_THRESHOLD..MAX_THRESHOLD, 'in')]

while parts.find { |p| !p.halted? }
    parts = parts.reduce([]) do |acc, part|
        if part.halted?
            acc.append(part)
        else
            new_parts = states[part.state].next_states(part)
            acc.append(*new_parts)
        end
    end
end

puts "Total Possibilites: #{parts.select(&:accepted?).sum(&:size)}"