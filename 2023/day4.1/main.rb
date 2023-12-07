Card = Struct.new(:winners, :numbers) do
    def winner_count
        numbers.intersection(winners).length
    end
    def points
        count = winner_count
        return count > 0 ? 2 ** (count - 1) : 0
    end
end

card_r = /^Card\s+(?<id>\d+):\s+(?<winners>(\d+\s+)+)\|(?<numbers>(\s+\d+)+)$/
point_sum = 0

File.readlines("input.txt", chomp: true).each do |line|
    card_match = card_r.match(line)
    winners = card_match[:winners].split
    numbers = card_match[:numbers].split
    card = Card.new(winners, numbers)
    point_sum += card.points
end

puts "Points: #{point_sum}"