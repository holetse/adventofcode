HolidayHash = Struct.new(:value) do
    def festive
        @festive ||= value.each_char.reduce(0) do |h, c|
            h += c.ord
            h *= 17
            h %= 256
            h
        end
    end
end

hashes = []
instructions = File.read('input.txt').strip
instructions.split(',').each do |instruction|
    hashes.append(HolidayHash.new(instruction))
end

puts "Mmm, hash: #{hashes.sum(&:festive)}"