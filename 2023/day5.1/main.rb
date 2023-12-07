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
end
Map = Struct.new(:name, :from, :to, :mappings) do
    def map(val)
        mappings.each do |mapping|
            return mapping.map(val) if mapping.include?(val)
        end
        val
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

seeds.each do |seed|
    category = 'seed'
    val = seed
    while category != 'location'
        print "#{category}(#{val}) -> "
        map = maps[category]
        val = map.map(val)
        category = map.to
    end
    locations.append(val)
    puts "#{category}(#{val})"
end

puts locations
puts "minimum location: #{locations.min}"

