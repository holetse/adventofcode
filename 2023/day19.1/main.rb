Part = Struct.new(:x, :m, :a, :s) do
    def score
        x + m + a + s
    end
end

Transition = Struct.new(:category, :condition, :threshold, :state) do
    def gt?
        condition == '>'
    end

    def lt?
        condition == '<'
    end

    def applies?(part)
        return true if category.nil?

        if gt?
            return part[category] > threshold
        elsif lt?
            return part[category] < threshold
        else
            raise "bad condition: #{self}"
        end
    end
end

State = Struct.new(:name, :transitions) do
    def halt?
        transitions.length == 0
    end

    def next_state(part)
        return nil if halt?

        transitions.find {|t| t.applies?(part)}.state
    end
end

REJECT = State.new('R', [])
ACCEPT = State.new('A', [])

states = {
    REJECT.name => REJECT,
    ACCEPT.name => ACCEPT
}

parts = []

state_r = /(?<name>[a-z]+){(?<rules>.*)}/
rule_r = /((?<category>[xmas])(?<condition>[<>])(?<threshold>\d+):)?(?<state>[AR]|[a-z]+)/
part_r = /{x=(?<x>\d+),m=(?<m>\d+),a=(?<a>\d+),s=(?<s>\d+)}/

File.open(File.join(__dir__, 'input.txt')) do |file|
    while (line = file.gets(chomp: true)).length > 0
        parsed = state_r.match(line)
        transitions = parsed[:rules].split(',').collect {|r| rule_r.match(r)}.collect do |rule|
            Transition.new(rule[:category], rule[:condition], rule[:threshold]&.to_i, rule[:state])
        end
        state = State.new(parsed[:name], transitions)
        states[state.name] = state
    end
    while !file.eof?
        parsed = part_r.match(file.gets(chomp: true))
        parts.append(Part.new(parsed[:x].to_i, parsed[:m].to_i, parsed[:a].to_i, parsed[:s].to_i))
    end
end

score = 0

parts.each do |part|
    state = states['in']
    while !state.halt?
        state = states[state.next_state(part)]
    end
    if state == ACCEPT
        score += part.score
    end
end

puts "Accepted Score: #{score}"
