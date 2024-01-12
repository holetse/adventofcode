class CommunicationModule
    LOW = :low
    HIGH = :high
    attr_reader :destinations
    attr_reader :name
    attr_reader :inputs
    attr_reader :low_pulses
    attr_reader :high_pulses

    def initialize(name, *args)
        @name = name
        @destinations = []
        @inputs = []
        @low_pulses = 0
        @high_pulses = 0
        @incoming_signals = []
        super(*args)
    end

    def inspect
        to_s
    end

    def to_s
        "<#{self.class} name='#{name}' inputs='#{@inputs.collect(&:name).join(',')}' destinations='#{@destinations.collect(&:name).join(',')}'>"
    end

    def add_input(mod)
        return if @inputs.include?(mod)
        @inputs.append(mod)
        mod.add_destination(self)
    end

    def add_destination(mod)
        return if @destinations.include?(mod)
        @destinations.append(mod)
        mod.add_input(self)
    end

    def propagate(signal, from)
        raise "bad signal: #{signal}" if ![LOW, HIGH].include?(signal)

        @incoming_signals.append([from, signal])
    end

    def process(signal, from) # return a list of nodes we propagated to, or nil if we don't
        raise "bad signal: #{signal}" if ![LOW, HIGH].include?(signal)
        nil
    end

    def tick # return a list of nodes we propagated to, or nil if we don't
        from, signal = @incoming_signals.shift

        if signal == LOW
            @low_pulses += 1
        elsif signal == HIGH
            @high_pulses += 1
        end

        process(signal, from)
    end
end

class Broadcaster < CommunicationModule
    def process(signal, from)
        raise "bad signal: #{signal}" if ![LOW, HIGH].include?(signal)
        return nil if destinations.empty?

        destinations.each { |mod| mod.propagate(signal, self) }
    end
end

class FlipFlop < CommunicationModule
    def initialize(*args)
        @on = false
        super(*args)
    end

    def process(signal, from)
        raise "bad signal: #{signal}" if ![LOW, HIGH].include?(signal)
        return nil if signal == HIGH || destinations.empty?

        @on = !@on
        destinations.each { |mod| mod.propagate(@on ? HIGH : LOW, self) }
    end
end

class Conjunction < CommunicationModule
    def initialize(*args)
        @state = {}
        super(*args)
    end

    def add_input(mod)
        super(mod)
        @inputs.each { |m| @state[m.name] = LOW }
    end

    def process(signal, from)
        raise "bad signal: #{signal}" if ![LOW, HIGH].include?(signal)
        return nil if destinations.empty?

        @state[from.name] = signal
        if @state.values.include?(LOW)
            send_signal = HIGH
        else
            send_signal = LOW
        end

        destinations.each { |mod| mod.propagate(send_signal, self) }

    end

end

class Emitter < CommunicationModule
    def initialize(*args)
        @pushed = false
        super(*args)
    end

    def push
        @pushed = true
    end

    def process(signal, from)
        raise "bad signal: #{signal}" if !signal.nil?
        return nil if !@pushed || destinations.empty?
        
        @pushed = false
        destinations.each { |mod| mod.propagate(LOW, self) }
    end
end

class Sink < CommunicationModule
end

modules = {}
destinations = {}

connection_r = /(?<type>[&%]?)(?<name>[a-z]+) -> (?<destinations>[a-z]+(, [a-z]+)*)/
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    parsed = connection_r.match(line)
    destination_names = parsed[:destinations].split(', ')
    if parsed[:name] == 'broadcaster'
        type = Broadcaster
    elsif parsed[:type] == '&'
        type = Conjunction
    elsif parsed[:type] == '%'
        type = FlipFlop
    else
        raise "bad connection: #{line}"
    end
    mod = type.new(parsed[:name])
    modules[mod.name] = mod
    destinations[mod.name] = destination_names
end

destinations.each do |name, destination_names|
    destination_names.each do |destination_name|
        mod = modules[destination_name]
        if mod.nil? # sink module
            mod = Sink.new(destination_name)
            modules[destination_name] = mod
        end
        modules[name].add_destination(mod)
    end
end

modules['button'] = Emitter.new('button')
modules['button'].add_destination(modules['broadcaster'])

1.upto(1000) do
    modules['button'].push
    processed = [modules['button']]
    while (processed = processed.collect(&:tick).compact.flatten).any?
    end
end

high_count = modules.values.sum(&:high_pulses)
low_count = modules.values.sum(&:low_pulses)

puts "Low Count: #{low_count}"
puts "High Count: #{high_count}"
puts "Low * High: #{low_count * high_count}"