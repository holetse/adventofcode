Sequence = Struct.new(:numbers) do
    def zeros?
        numbers.find { |n| !n.zero? }.nil?
    end

    def steps
        if !@steps 
            @steps = []
            numbers.each_with_index do |n, i|
                @steps.append(n - numbers[i - 1]) if i > 0 && i < numbers.length
            end
        end
        @steps
    end

    def predict
        return 0 if zeros?
        step = Sequence.new(steps).predict
        step + numbers.last
    end
end

sequences = []
File.readlines("input.txt", chomp: true).each do |line|
    numbers = line.split.collect(&:to_i)
    sequences.append(Sequence.new(numbers))
end

puts "Sum: #{sequences.sum(&:predict)}"