ingredient_ids = []
available_ingredients = []

ingredient_id_r = /^(\d+)-(\d+)$/
ingredient_ids_read = false
File.readlines('input.txt', chomp: true).each do |line|
  if (line == '')
    ingredient_ids_read = true
  elsif ingredient_ids_read
    available_ingredients << line.to_i
  else
    parts = ingredient_id_r.match(line)
    ingredient_ids << (parts[1].to_i..parts[2].to_i)
  end
end

fresh_count = available_ingredients.count do |id|
  ingredient_ids.any? do |range|
    range.include?(id)
  end
end

puts "fresh ingredients = #{fresh_count}"