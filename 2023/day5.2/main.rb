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
        remainder = []
        if range.cover?(rng)
            mapped_range = map(rng.begin)..map(rng.end)
        elsif rng.begin < range.begin && rng.end > range.end # begin & end overlap
            mapped_range = dst_range
            remainder = [rng.begin..(range.begin - 1), (range.end + 1)..rng.end]
        elsif rng.begin >= range.begin && rng.end > range.end && rng.begin <= range.end  # end overlap
            mapped_range = map(rng.begin)..(dst_range.end)
            remainder = [(range.end + 1)..rng.end]
        elsif rng.begin < range.begin && rng.end <= range.end && rng.end >= range.begin  # begin overlap
            mapped_range = (dst_range.begin)..map(rng.end)
            remainder = [rng.begin..(range.begin - 1)]
        else
            remainder = [rng]
        end

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
        remainder = [rng]
        count = 0
        while (r = remainder.pop)
            found = false
            mappings.each do |mapping|
                mapped_range, new_remainder = mapping.map_range(r)
                if !mapped_range.nil?
                    remainder.append(*new_remainder)
                    ranges.append(mapped_range)
                    found = true
                    break
                end
            end
            if !found
                ranges.append(r)
            end
        end
        ranges
    end
end

seeds_r = /^seeds: (?<seeds>.*)/
map_r = /^(?<category>(?<from>[a-z]+)-to-(?<to>[a-z]+)) map:/

seeds = []
locations = []
maps = {}

File.open("input.txt") do |file|
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
locations.collect!(&:begin)

puts "minimum location: #{locations.min}"
