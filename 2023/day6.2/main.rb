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
    time = times[:times].split.join('')
    races.append(Race.new(time.to_i))
    distances = /^Distance:(?<distances>(\s+\d+)+)/.match(f.gets)
    distance = distances[:distances].split.join('')
    races[0].distance = distance.to_i
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
