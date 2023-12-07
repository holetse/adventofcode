limits = {
    'red' => 12,
    'green' => 13,
    'blue' => 14
}

game_id_r = /^Game (\d+):/
hand_r = /\s?(?<count>\d+) (?<color>red|green|blue),?/
id_sum = 0
File.readlines('input.txt', chomp: true).each do |game|
    id_groups = game_id_r.match(game)
    id = id_groups[1].to_i
    hands = id_groups.post_match.split(';')
    valid = true
    hands.each do |hand|
        cubes_matches = hand.to_enum(:scan, hand_r).map { Regexp.last_match }
        cubes_matches.each do |cube_match|
            if cube_match[:count].to_i > limits[cube_match[:color]]
                valid = false
                puts "#{cube_match[:count]} > #{limits[cube_match[:color]]}"
                break
            end
        end
        break if !valid
    end
    if valid
        id_sum += id
    end
end

puts "ID Sum: #{id_sum}"