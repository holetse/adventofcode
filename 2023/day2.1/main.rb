game_id_r = /^Game (\d+):/
hand_r = /\s?(?<count>\d+) (?<color>red|green|blue),?/
power_sum = 0
File.readlines('input.txt', chomp: true).each do |game|
    id_groups = game_id_r.match(game)
    id = id_groups[1].to_i
    hands = id_groups.post_match.split(';')
    max_by_color = {
        'red' => 0,
        'green' => 0,
        'blue' => 0
    }
    hands.each do |hand|
        cubes_matches = hand.to_enum(:scan, hand_r).map { Regexp.last_match }
        cubes_matches.each do |cube_match|
            count = cube_match[:count].to_i
            if count > max_by_color[cube_match[:color]]
                max_by_color[cube_match[:color]] = count
            end
        end
    end
    power_sum += max_by_color['red'] * max_by_color['green'] * max_by_color['blue']
end

puts "Power Sum: #{power_sum}"