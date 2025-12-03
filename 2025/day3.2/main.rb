class Bank
  def initialize(batteries, enabled_count=12)
    @batteries = batteries.chars.collect(&:to_i)
    @enabled_batteries = nil
    @enabled_count = enabled_count
  end
  
  def jolts
    @jolts ||= enabled_batteries.each_with_index.collect do |pos, i|
      @batteries[pos] * (10 ** (@enabled_count - 1 - i))
    end.sum
  end

  def enabled_batteries
    return @enabled_batteries unless @enabled_batteries.nil?
    @enabled_batteries = []
    last = -1
    @enabled_count.downto(1) do |remaining|
      @enabled_batteries << next_enabled_battery(last, remaining)
      last = @enabled_batteries.last
    end
    @enabled_batteries
  end

  private

  def next_enabled_battery(previous, remaining)
    max = 0
    maxPos = -1
    (previous + 1).upto(@batteries.length - remaining) do |i|
      if @batteries[i] > max
        max = @batteries[i]
        maxPos = i
      end
    end
    maxPos
  end
end

banks = File.readlines('input.txt', chomp: true).collect do |batteries|
  Bank.new(batteries)
end

puts "total joltage = #{banks.collect(&:jolts).sum}"