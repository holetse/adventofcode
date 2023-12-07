CARD_RANKS = {
    'A' => 14, 'K' => 13, 'Q' => 12, 'T' => 10, '9' => 9, '8' => 8, '7' => 7, '6' => 6, '5' => 5, '4' => 4, '3' => 3, '2' => 2, 'J' => 1
}

Card = Struct.new(:label) do
    def rank
        @rank ||= CARD_RANKS[label]
    end

    def <=>(other)
        rank <=> other.rank
    end
end

def get_n_of_a_kind(hand_tally_sorted, n)
    mostcard = hand_tally_sorted[0]
    return [mostcard] if mostcard[1] == n

    cards = []
    wildcard = hand_tally_sorted.find { |tally| tally[0] == WILDCARD }
    return cards unless wildcard

    if mostcard[0] == WILDCARD
        mostcard = hand_tally_sorted[1]
    end
    
    cards = [mostcard, wildcard] if mostcard[1] + wildcard[1] == n
    cards
end

def has_n_of_a_kind(hand, n)
    !get_n_of_a_kind(hand.tally_sorted, n).empty?
end

WILDCARD = Card.new('J')
HAND_TYPES = {
    kind5: lambda { |h| has_n_of_a_kind(h, 5) },
    kind4: lambda { |h| has_n_of_a_kind(h, 4) },
    full: lambda do |h|
        kind3 = get_n_of_a_kind(h.tally_sorted, 3)
        kind2 = get_n_of_a_kind(h.tally_sorted - kind3, 2)
        !kind3.empty? && !kind2.empty?
    end,
    kind3: lambda { |h| has_n_of_a_kind(h, 3) },
    pair2: lambda do |h|
        first_pair = get_n_of_a_kind(h.tally_sorted, 2)
        second_pair = get_n_of_a_kind(h.tally_sorted - first_pair, 2)
        !first_pair.empty? && !second_pair.empty? 
    end,
    pair1: lambda { |h| has_n_of_a_kind(h, 2) },
    high: lambda { |h| h.tally.length == h.cards.length }
}

HAND_TYPES_RANK = HAND_TYPES.keys

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

    def tally_sorted
        @tally_sorted ||= tally.sort_by { |k, v| v } .reverse
    end
end

if __FILE__ == $0
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
end