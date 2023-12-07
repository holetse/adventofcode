Race = Struct.new(:time, :distance)

def distance_traveled(time, charge)
    (time - charge) * charge
end

def charge_vs_distance(race)
    traveled = []
    0.upto(race.time) do |charge|
        traveled.append(distance_traveled(race.time, charge))
    end
    traveled
end

races = []
winning_options = []

File.open("input.txt") do |f|
    times = /^Time:(?<times>(\s+\d+)+)/.match(f.gets)
    times[:times].split.each do |time|
        races.append(Race.new(time.to_i))
    end

    distances = /^Distance:(?<distances>(\s+\d+)+)/.match(f.gets)
    distances[:distances].split.each_with_index do |distance, i|
        races[i].distance = distance.to_i
    end
end

races.each do |race|
    options = charge_vs_distance(race)
    winning_count = options.reduce(0) do |count, traveled|
        count += 1 if traveled > race.distance
        count
    end
    winning_options.append(winning_count)
end

puts "power options: #{winning_options.reduce(1, &:*)}"
