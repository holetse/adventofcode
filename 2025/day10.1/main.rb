class Machine
  
  def initialize(lights, buttons, joltages, *args)
    @lights = lights
    @buttons = buttons
    @joltages = joltages

    @lbits = @lights.each_with_index.reduce(0) { |bits, pair| ((pair[0] == '#' ? 1 : 0) << pair[1]) | bits }
    @bbits = @buttons.collect { |button| button.reduce(0) { |bits, bit| (1 << bit) | bits } }

    super(*args)
  end

  def fewest_pushes
    @fewest_pushes ||= fewest_pushes_calc
  end

  def push_button(button, state=0)
    toggle(state, button)
  end

  def to_s
    inspect
  end

  def inspect
    "<machine [#{@lights.join('')}], #{@buttons.collect {|button| "(#{button.join(',')})" }.join(' ')}, {#{@joltages.join(',')}}>"
  end

  private

  def toggle(state, button)
    state ^ @bbits[button]
  end

  def fewest_pushes_calc
    button_indexes = (0..@buttons.length - 1).to_a
    remaining = button_indexes.collect { |button| [button, 0, 0] }

    while push = remaining.pop
      button, state, count = push
      state = push_button(button, state)
      count += 1
      if @lbits == state
        return count
      end
      button_indexes.each { |button| remaining.unshift([button, state, count]) }
    end
  end

end

machines = File.readlines(File.join(__dir__, 'input.txt'), chomp: true).collect do |line|
  instructions = line.split(' ')
  lights = instructions.first[1..-2].split('')
  joltages = instructions.last[1..-2].split(',').collect(&:to_i)
  buttons = instructions[1..-2].collect { |button| button[1..-2].split(',').collect(&:to_i)}
  Machine.new(lights, buttons, joltages)
end

puts "sum of fewest pushes = #{machines.sum(&:fewest_pushes)}"