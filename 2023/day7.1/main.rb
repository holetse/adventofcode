
CARD_RANKS = {
    'A' => 14, 'K' => 13, 'Q' => 12, 'J' => 11, 'T' => 10, '9' => 9, '8' => 8, '7' => 7, '6' => 6, '5' => 5, '4' => 4, '3' => 3, '2' => 2
}

def hand_high?(hand)

end

HAND_TYPES = {
    kind5: lambda { |h| h.tally.length == 1 },
    kind4: lambda { |h| h.tally.has_value?(4) },
    full: lambda { |h| h.tally.has_value?(3) && h.tally.has_value?(2) },
    kind3: lambda { |h| h.tally.has_value?(3) && h.tally.count {|k, v| v == 1} == 2 },
    pair2: lambda { |h| h.tally.count {|k, v| v == 2} == 2 },
    pair1: lambda { |h| h.tally.count {|k, v| v == 2} == 1 },
    high: lambda { |h| h.tally.length == h.cards.length }
}

HAND_TYPES_RANK = HAND_TYPES.keys

Card = Struct.new(:label) do
    def rank
        @rank ||= CARD_RANKS[label]
    end

    def <=>(other)
        rank <=> other.rank
    end
end

Hand = Struct.new(:cards, :bid) do
    def type
        @type ||= HAND_TYPES_RANK.find { |type| HAND_TYPES[type].call(self) }
    end

    def rank
        @rank ||= HAND_TYPES_RANK.index(type)
    end

    def <=>(other)
        ordering = rank <=> other.rank
        return ordering unless ordering == 0
        other.cards <=> cards
    end

    def tally
        @tally ||= cards.tally
    end
end

line_r = /^(?<cards>[#{CARD_RANKS.keys.join('')}]+)\s+(?<bid>\d+)/
hands = []
File.readlines('input.txt', chomp: true).each do |line|
    hand = line_r.match(line)
    cards = hand[:cards].split('').collect { |c| Card.new(c) }
    hands.append(Hand.new(cards, hand[:bid].to_i))
end

hands.sort!.reverse!
winnings = 0
hands.each_with_index { |h, i| winnings += h.bid * (i + 1)}

puts hands
puts "winnings: #{winnings}"