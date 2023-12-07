require 'progressbar'

THREADS = 10
CHUNK_SIZE = 1000000

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

split_seed_ranges = seed_ranges.collect do |r|
    ranges = []
    next_begin = r.begin
    while next_begin <= r.end
        next_end = [r.end, next_begin + (CHUNK_SIZE - 1)].min
        ranges.append(next_begin..next_end)
        next_begin = next_end + 1
    end
    ranges
end

split_seed_ranges.flatten!
# split_seed_ranges = split_seed_ranges[0..3]

total_seeds = split_seed_ranges.sum(&:size)
bar = ProgressBar.create(total: total_seeds, format: "%a %e %P% Processed: %c from %C")
bar_mutex = Mutex.new

threads = []

split_seed_ranges.each_slice(split_seed_ranges.length / THREADS) do |seed_ranges|
    thr = Thread.new do
        calcd_locations = []
        seed_ranges.each do |seed_range|
            seed_locations = []
            seed_range.each do |seed|
                category = 'seed'
                val = seed
                while category != 'location'
                    # print "#{category}(#{val}) -> "
                    map = maps[category]
                    val = map.map(val)
                    category = map.to
                end
                seed_locations.append([seed, val])
                if seed_locations.length % 10000 == 0
                    bar_mutex.synchronize { bar.progress += 10000 }
                end
                # puts "#{category}(#{val})"
            end
            File.write("out/#{seed_range}.txt", seed_locations)
            system("gzip out/#{seed_range}.txt")
            calcd_locations.append(seed_locations.collect(&:last).min)
        end
        calcd_locations.min
    end
    threads.append(thr)
end

threads.each { |t| t.join }
locations = threads.collect(&:value)

File.write('out.txt', locations)

puts "locations: #{locations}"
puts "minimum location: #{locations.min}"

