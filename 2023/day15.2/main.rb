HolidayHash = Struct.new(:value) do
    def label
        @label ||= /[a-z]+/.match(value).to_s
    end

    def focal_length
        @focal_length ||= /\d$/.match(value)&.to_s
    end

    def operation
        @operation ||= /[-=]/.match(value).to_s
    end

    def remove?
        operation == '-'
    end

    def add?
        operation == '='
    end

    def box
        @box ||= festive(label)
    end

    def score(slot)
        return 0 if remove?
        (box + 1) * slot * focal_length.to_i
    end

    def festive(str=value)
        str.each_char.reduce(0) do |h, c|
            h += c.ord
            h *= 17
            h %= 256
            h
        end
    end

    def to_s
        "<HolidayHash label=#{label} focal_length=#{focal_length} operation=#{operation}>"
    end

    def inspect
        to_s
    end
end

hashes = []
instructions = File.read('input.txt').strip
instructions.split(',').each do |instruction|
    hashes.append(HolidayHash.new(instruction))
end

puts "Mmm, hash: #{hashes.sum(&:festive)}"

hashmap = {}
hashes.each do |hash|
    hashmap[hash.box] ||= []
    box = hashmap[hash.box]
    if hash.add?
        old_hash = box.index { |h| h.label == hash.label }
        if old_hash
            box[old_hash] = hash
        else
            box.append(hash)
        end
    elsif hash.remove?
        hashmap[hash.box].reject! { |h| h.label == hash.label }
    else
        raise 'oh no, bad hash'
    end
end

score = 0
hashmap.values.each do |box|
    box.each_with_index do |hash, i|
        score += hash.score(i + 1)
    end
end

puts "Total hash: #{score}"