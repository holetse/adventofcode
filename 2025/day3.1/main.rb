class Bank
  def initialize(batteries)
    @batteries = batteries.chars.collect(&:to_i)
    @most_significant_battery = nil
    @most_significant_battery_pos = nil
    @least_significant_battery = nil
  end
  
  def jolts
    @jolts ||= (most_significant_battery * 10) + least_significant_battery
  end

  private

  def most_significant_battery
    return @most_significant_battery unless @most_significant_battery.nil?
    max = 0
    maxPos = -1
    0.upto(@batteries.length - 2) do |i|
      if @batteries[i] > max
        max = @batteries[i]
        maxPos = i
      end
    end
    @most_significant_battery_pos = maxPos
    @most_significant_battery = max
  end

  def most_significant_battery_pos
    most_significant_battery if @most_significant_battery_pos.nil?
    @most_significant_battery_pos
  end
  
  def least_significant_battery
    max = 0
    maxPos = -1
    (most_significant_battery_pos + 1).upto(@batteries.length - 1) do |i|
      if @batteries[i] > max
        max = @batteries[i]
        maxPos = i
      end
    end
    @least_significant_battery = max
  end

end

banks = File.readlines('input.txt', chomp: true).collect do |batteries|
  Bank.new(batteries)
end

puts "total joltage = #{banks.collect(&:jolts).sum}"