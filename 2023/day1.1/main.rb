calibration_sum = 0
r = /^\D*(\d).*?((\d)\D*)?$/
File.readlines('input.txt', chomp: true).each do |line|
    groups = r.match(line)
    first = groups[1]
    last = groups[3] || groups[1]
    puts "#{line} = #{first}, #{last}"
    calibration_sum = calibration_sum + "#{first}#{last}".to_i
end

puts "calibration sum: ", calibration_sum