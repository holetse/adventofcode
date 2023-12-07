words_to_numbers = {
    'one' => 1,
    'two' => 2,
    'three' => 3,
    'four' => 4,
    'five' => 5,
    'six' => 6,
    'seven' => 7,
    'eight' => 8,
    'nine' => 9,
    'zero' => 0
}
words_group = words_to_numbers.keys.join('|')
calibration_sum = 0
digit_or_word_r = /(?:(\d)|(#{words_group}))/
File.readlines('input.txt', chomp: true).each do |line|
    offset = 0
    first = false
    while groups = digit_or_word_r.match(line[offset..-1])
        group = groups[1] ? 1 : 2
        last = groups[1] || words_to_numbers[groups[2]]
        offset = groups.begin(group) + 1 + offset
        if (!first)
            first = last
        end
    end
    puts "#{line} = #{first}, #{last}"
    calibration_sum = calibration_sum + "#{first}#{last}".to_i
end

puts "calibration sum: ", calibration_sum