class Range
  def combine(range)
    if self.cover?(range)
      self
    elsif range.cover?(self)
      range
    elsif range.begin >= self.begin && range.end > self.end && range.begin <= self.end  # end overlap
      self.begin..range.end
    elsif range.begin < self.begin && range.end <= self.end && range.end >= self.begin  # begin overlap
      range.begin..self.end
    else
      nil
    end
  end
end

def combine_ranges(ranges)
  to_combine = ranges.dup

  did_combine = false
  combined_ranges = []
  while to_combine.length > 0 do
    uncombined_ranges = []
    combined_range = to_combine.reduce do |range, other|
      combined = range.combine(other)
      if combined.nil?
        uncombined_ranges << other
        combined = range
      else
        did_combine = true
      end
      combined
    end
    combined_ranges << combined_range
    to_combine = uncombined_ranges
  end
  if did_combine
    combine_ranges(combined_ranges)
  else
    combined_ranges
  end
end

ingredient_ids = []
combined_ids = []
ingredient_id_r = /^(\d+)-(\d+)$/
File.readlines('input.txt', chomp: true).each do |line|
  break if (line == '')

  parts = ingredient_id_r.match(line)
  ingredient_ids << (parts[1].to_i..parts[2].to_i)
end

reduced_ranges = combine_ranges(ingredient_ids)


puts "total fresh ingredients = #{reduced_ranges.sum(&:size)}"
