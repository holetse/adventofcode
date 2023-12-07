Mapping = Struct.new(:range, :dst_offset) do
    def include?(val)
        range.include?(val)
    end

    def begin
        range.begin
    end

    def end
        range.end
    end

    def map(val)
        return nil unless include?(val)
        (val - range.begin) + dst_offset
    end

    def dst_range
        @dst_range ||= (dst_offset..(dst_offset + range.size - 1))
    end

    def to_s
        super[0..-2] + ", dst_range=#{dst_range}>"
    end

    def map_range(rng)
        mapped_range = nil
        remainder = nil
        if range.cover?(rng)
            start = rng.begin - range.begin
            mapped_range = (start + dst_range.begin)..(start + dst_range.begin + (rng.size - 1))
        elsif rng.begin <= range.end && rng.end >= range.end
            mapped_range = ((rng.begin - range.begin) + dst_range.begin)..(dst_range.end)
            remainder = (range.end + 1)..rng.end
        elsif rng.end >= range.begin && rng.begin <= range.begin
            mapped_range = (dst_range.begin)..(dst_range.begin + (rng.end - range.begin))
            remainder = rng.begin..(range.begin - 1)
        else
            remainder = rng
        end

        mr_size = mapped_range ? mapped_range.size : 0
        r_size = remainder ? remainder.size : 0
        raise "bad mapping: #{rng}, #{self}, #{mapped_range}, #{remainder}" if mr_size + r_size != rng.size

        return mapped_range, remainder
    end
end

Map = Struct.new(:name, :from, :to, :mappings) do
    def map(val)
        mappings.each do |mapping|
            return mapping.map(val) if mapping.include?(val)
        end
        val
    end

    def map_range(rng)
        ranges = []
        remainder = rng
        count = 0
        while remainder
            puts "remainder loop (#{name})"
            found = false
            mappings.each do |mapping|
                mapped_range, new_remainder = mapping.map_range(remainder)
                puts "iteration: #{mapped_range}, #{new_remainder}, #{mapping}, #{remainder}"
                remainder = new_remainder
                if !mapped_range.nil?
                    ranges.append(mapped_range)
                    found = true
                    break
                end
            end
            if !found && !remainder.nil?
                puts "not found: #{rng}, #{remainder}, #{ranges}, #{self.name}"
                ranges.append(remainder)
                remainder = nil
            end
        end
        raise "bad mapping: #{rng}, #{ranges}" if rng.size != ranges.sum(&:size)
        ranges
    end
end

seeds_r = /^seeds: (?<seeds>.*)/
map_r = /^(?<category>(?<from>[a-z]+)-to-(?<to>[a-z]+)) map:/

seeds = []
locations = []
maps = {}

File.open("example.txt") do |file|
    seeds = seeds_r.match(file.readline)[:seeds].split.collect(&:to_i)
    category = nil
    while !file.eof? do
        line = file.readline.strip
        if line.empty?
            if category
                maps[category.from] = category
            end
            category = nil
        elsif category.nil?
            map_matches = map_r.match(line)
            category = Map.new(map_matches[:category], map_matches[:from], map_matches[:to], [])
        else
            mapping_raw = line.split.collect(&:to_i)
            src_range = mapping_raw[1]..(mapping_raw[1] + mapping_raw[2] - 1)
            category.mappings.append(Mapping.new(src_range, mapping_raw[0]))
        end
    end
    maps[category.from] = category
end

seed_ranges = seeds.each_slice(2).collect { |s, o| s..(s + o - 1) }
puts "seed ranges: #{seed_ranges}"

seed_ranges.each do |seed_range|
    category = 'seed'
    ranges = [seed_range]
    while category != 'location'
        map = maps[category]
        ranges = ranges.collect { |r| map.map_range(r) }
        ranges.flatten!
        category = map.to
    end
    locations.append(ranges)
end

locations.flatten!
puts "counts: #{seed_ranges.sum(&:size)}, #{locations.sum(&:size)}"
puts locations
locations.collect!(&:begin)

# soil_ranges = maps['seed'].map_range(seed_ranges[0])

# puts soil_ranges.inspect
# puts "####"


# fert_ranges = soil_ranges.collect {|r| maps['soil'].map_range(r) }
# fert_ranges.flatten!

# puts "seed: #{seed_ranges[0]}, #{seed_ranges[0].size}"
# puts "soil: #{soil_ranges}, #{soil_ranges.sum(&:size)}"
# puts "fert: #{fert_ranges}, #{fert_ranges.sum(&:size)}"

# puts maps['seed'].map_range(seed_ranges[0])

# puts locations
puts "minimum location: #{locations.min}"

# the right answer is, 31161857, generated from seed 3267749434