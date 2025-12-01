class Safe
    attr_reader :currentPos, :rotatedToZeroCount
    def initialize(startingPos: 50, maxPos: 99)
        @currentPos = startingPos
        @maxPos = maxPos
        @minPos = 0
        @rotatedToZeroCount = 0
    end

    def rotate_left(positions)
        positions.times do
            rotate_inc(-1)
        end
    end

    def rotate_right(positions)
        positions.times do
            rotate_inc(1)
        end
    end

    private

    def rotate_inc(leftOrRight)
        @currentPos += leftOrRight
        if (@currentPos == (@maxPos + 1))
            @currentPos = 0
        elsif (@currentPos == -1)
            @currentPos = @maxPos
        end
        if (@currentPos == 0)
            @rotatedToZeroCount += 1
        end
    end

end

safe = Safe.new()

r = /^([RL])(\d+)$/
File.readlines('input.txt', chomp: true).each do |line|
    groups = r.match(line)
    direction = groups[1]
    positions = groups[2].to_i
    if direction == 'R'
        safe.rotate_right(positions)
    else
        safe.rotate_left(positions)
    end
    puts "#{direction} #{positions} = #{safe.currentPos}"
end

puts "password = #{safe.rotatedToZeroCount}"
