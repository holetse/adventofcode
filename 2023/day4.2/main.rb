Card = Struct.new(:winners, :numbers, :id) do
    def winner_count
        @winner_count ||= numbers.intersection(winners).length
    end

    def winner?
        winner_count > 0
    end

    def points
        count = winner_count
        count > 0 ? 2 ** (count - 1) : 0
    end
end

card_r = /^Card\s+(?<id>\d+):\s+(?<winners>(\d+\s+)+)\|(?<numbers>(\s+\d+)+)$/
point_sum = 0
original_cards = []

File.readlines("input.txt", chomp: true).each do |line|
    card_match = card_r.match(line)
    winners = card_match[:winners].split
    numbers = card_match[:numbers].split
    card = Card.new(winners, numbers, card_match[:id].to_i)
    point_sum += card.points
    original_cards.append(card)
end

cards_to_process = original_cards.dup
# puts cards_to_process.shift, cards_to_process.shift, cards_to_process.length, original_cards.length
final_cards = []
while card = cards_to_process.shift do
    final_cards.append(card)
    if card.winner?
        offset = card.id - 1
        cards = original_cards[(offset + 1)..(offset + card.winner_count)]
        cards_to_process.append(*cards)
        puts "#{final_cards.length} #{cards_to_process.length}"
    end
end

puts "Points: #{point_sum}"
puts "Card count: #{final_cards.length}"