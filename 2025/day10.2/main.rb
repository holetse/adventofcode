require 'rulp' # note this requires a modification to https://github.com/wouterken/rulp/blob/925f07685446a86616ba43f9fd511f3b59c668c5/lib/rulp/rulp_bounds.rb#L56

Rulp::log_level = Logger::WARN

class Machine
  
  attr_accessor :mode
  
  def initialize(lights, buttons, joltages, mode=:lights, *args)
    raise "unknown mode '#{mode}'" unless [:lights, :joltages].include?(mode)
    @lights = lights
    @buttons = buttons
    @joltages = joltages
    @mode = mode
    
    @lbits = @lights.each_with_index.reduce(0) { |bits, pair| ((pair[0] == '#' ? 1 : 0) << pair[1]) | bits }
    @bbits = @buttons.collect { |button| button.reduce(0) { |bits, bit| (1 << bit) | bits } }
    
    super(*args)
  end
  
  def fewest_pushes
    @fewest_pushes ||= mode == :lights? ? fewest_pushes_calc_lights : fewest_pushes_calc_joltages
  end
  
  def push_button(button, state)
    if mode == :lights
      toggle_lights(state, button)
    else
      toggle_joltages(state, button)
    end
  end
  
  def to_s
    inspect
  end
  
  def inspect
    "<machine [#{@lights.join('')}], #{@buttons.collect {|button| "(#{button.join(',')})" }.join(' ')}, {#{@joltages.join(',')}}>"
  end
  
  private
  
  def toggle_lights(state, button)
    state ^ @bbits[button]
  end
  
  def toggle_joltages(state, button)
    new_state = state.dup
    @buttons[button].each { |index| new_state[index] += 1 }
    new_state
  end
  
  def fewest_pushes_calc_lights
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

  def fewest_pushes_calc_joltages
    desired_joltages = @joltages

    buttons = @buttons

    joltage_to_buttons = desired_joltages.each_with_index.collect do |joltage, i|
      buttons.each_with_index.reduce([]) do |map, pair|
        btn, j = pair
        if btn.include?(i)
          map.push(j)
        end
        map
      end
    end

    presses_variables = buttons.each_with_index.collect do |button, i|
      Presses_i(i)
    end

    constraints = [
      presses_variables.collect { |presses| presses >= 0 },
      desired_joltages.each_with_index.collect do |joltage, i|
        if joltage_to_buttons[i].length == 1
          presses_variables[joltage_to_buttons[i][0]] == joltage
        else
          joltage_to_buttons[i].collect { |btn| presses_variables[btn] }.inject(&:+) == joltage
        end
      end
    ]

    problem = Rulp::Min(presses_variables.reduce(&:+))
    problem[constraints]

    problem.glpk

    presses_variables.collect(&:value).sum.to_i
  end
  
end

machines = File.readlines(File.join(__dir__, 'input.txt'), chomp: true).collect do |line|
  instructions = line.split(' ')
  lights = instructions.first[1..-2].split('')
  joltages = instructions.last[1..-2].split(',').collect(&:to_i)
  buttons = instructions[1..-2].collect { |button| button[1..-2].split(',').collect(&:to_i)}
  Machine.new(lights, buttons, joltages, :joltages)
end

puts "sum of fewest pushes = #{machines.sum(&:fewest_pushes)}"