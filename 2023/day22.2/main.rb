Brick = Struct.new(:x1, :y1, :z1, :x2, :y2, :z2, :label) do
    def bounds
        @bounds ||= {
            x: x1..x2,
            y: y1..y2,
            z: z1..z2
        }
    end
    
    def dimensions
        @dimensions ||= {
            x: bounds[:x].size,
            y: bounds[:y].size,
            z: bounds[:z].size
        }
    end

    def volume
        @volume ||= dimensions.values.reduce(&:*)
    end

    def axis
        @axis ||= dimensions.find {|_, dim| dim != 1 }&.first
    end

    def xy_profile
        return @xy_profile if @xy_profile

        if axis == :z || axis.nil?
            @xy_profile = [[x1, y1]]
        elsif axis == :x
            @xy_profile = bounds[axis].collect { |pos| [pos, y1] }
        else
            @xy_profile = bounds[axis].collect { |pos| [x1, pos] }
        end

        @xy_profile
    end

    def fall!
        raise 'at ground' if z1 == 0
        self.z1 -= 1
        self.z2 -= 1
        @bounds = nil
    end

    def <=>(other)
        ((self.x1 <=> other.x1) <=> (self.y1 <=> other.y1)) <=> (self.z1 <=> other.z1)
    end
end

Volume = Struct.new(:bricks) do
    def dimensions
        @dimensions ||= bricks.reduce({x: 0, y: 0, z: 0}) do |dim, brick|
            {
                x: [dim[:x], brick.x1, brick.x2].max,
                y: [dim[:y], brick.y1, brick.y2].max,
                z: [dim[:z], brick.z1, brick.z2].max
            }
        end
    end

    def bricks_by_axis(axis)
        axes = [:x, :y, :z]
        raise 'bad axis' if !axes.include?(axis)
        return @bricks_by_axis[axis] if @bricks_by_axis

        @bricks_by_axis = {
            x: {},
            y: {},
            z: {}
        }

        dimensions.each do |a, dim|
            0.upto(dim).each do |pos|
                @bricks_by_axis[a][pos] = []
            end
        end

        bricks.each do |b|
            b.bounds.each do |a, rng|
                rng.each do |pos|
                    @bricks_by_axis[a][pos].append(b)
                end
            end
        end

        @bricks_by_axis[axis]
    end

    def empty_axis?(axis, point)
        axes = [:x, :y, :z]
        raise 'bad axis' if !axes.include?(axis)
        axes.delete(axis)

        (bricks_by_axis(axes.first)[point.first] & bricks_by_axis(axes.last)[point.last]).length == 0
    end

    def empty?(point, ignoring=nil)
        x, y, z = point

        ((bricks_by_axis(:z)[z] & bricks_by_axis(:x)[x] & bricks_by_axis(:y)[y]) - [ignoring]).length == 0
    end

    def can_fall?(brick, ignoring=nil)
        bounds = brick.bounds
        z = bounds[:z].begin - 1
        
        return false if z <= 0

        brick.xy_profile.each do |x, y|
            return false if !empty?([x, y, z], ignoring)
        end

        true
    end

    def vertical_contact(brick, z_dir)
        raise 'bad z-direction' if z_dir.abs != 1

        bounds = brick.bounds
        z = bounds[:z].end + z_dir

        bricks = []
        bricks_by_axis(:z)[z].each do |b|
            brick.xy_profile.each do |x, y|
                if b.bounds[:x].include?(x) && b.bounds[:y].include?(y)
                    bricks.append(b)
                    break
                end
            end
        end

        bricks
    end

    def bricks_supported_by(brick)
        vertical_contact(brick, 1)
    end

    def bricks_supporting(brick)
        vertical_contact(brick, -1)
    end

    def can_disintegrate?(brick)
        bricks_supported_by(brick).each do |supported|
            return false if bricks_supporting(supported).length == 1
        end

        true
    end

    def fall!(brick)
        old_z = brick.bounds[:z]
        brick.fall!
        new_z = brick.bounds[:z]
        lookup = bricks_by_axis(:z)
        old_z.each do |pos|
            lookup[pos].delete(brick)
        end
        new_z.each do |pos|
            lookup[pos].append(brick)
        end
        @dimensions = nil
    end

    def settle!
        remaining_bricks = bricks.dup
        while remaining_bricks.length > 0
            to_fall = []
            remaining_bricks.sort { |a, b| a.z1 <=> b.z1 }.each do |b|
                if can_fall?(b)
                    to_fall.append(b)
                elsif to_fall.empty?
                    remaining_bricks.delete(b)
                end
            end
            to_fall.each do |b|
                fall!(b)
            end
        end
    end

    def support_tree
        tree = {}

        bricks.each do |brick|
            tree[brick] = bricks_supported_by(brick).reject {|b| b == brick }
        end

        tree
    end

    def dependeny_tree
        tree = {}

        bricks.each do |brick|
            tree[brick] = bricks_supporting(brick).reject {|b| b == brick }
        end

        tree
    end

    def find_chain(brick, stree=support_tree, dtree=dependeny_tree)
        chain = []
        visited = Set.new

        remaining = [brick]
        while next_brick = remaining.shift
            chain.append(next_brick)
            stree[next_brick].each do |b|
                if (dtree[b] - chain).length == 0
                    remaining.append(b)
                end
            end
        end

        chain
    end

    def visualize(axis, label=true)
        axes = [:x, :y, :z]
        raise 'bad axis' if !axes.include?(axis)
        axes.delete(axis)
        row_count = dimensions[axes.last]
        col_count = dimensions[axes.first]

        viz = 0.upto(row_count).collect do |row|
            0.upto(col_count).collect do |col|
                if row == row_count && axis != :z
                    '-'
                else
                    empty_axis?(axis, [col, row_count - row]) ? '.' : '#'
                end
            end.join('')
        end.join("\n")

        if label
            label_figure(viz, row_reverse: true)
        end
    end
end

def label_figure(figure, options={})
    row_inner_margin = 2
    row_outer_margin = 1
    col_inner_margin = 1
    col_outer_margin = 1
    rows = figure.split("\n")
    rows_length_digits = rows.length.to_s.length
    columns_length = rows.max {|a, b| a.length <=> b.length}.length
    columns_length_digits = columns_length.to_s.length
    row_header_len = rows_length_digits + row_inner_margin + row_outer_margin
    
    header_rows = Array.new(columns_length_digits + col_inner_margin + col_outer_margin, ' ' * row_header_len)
    0.upto(columns_length - 1) do |col|
        digits = col.digits
        padded_digits = digits.reverse + Array.new(columns_length_digits - digits.length, ' ')
        header_rows.each_with_index do |row, ri|
            if ri < col_outer_margin || ri >= col_outer_margin + columns_length_digits
                header_rows[ri] += ' '
            else
                header_rows[ri] += padded_digits.pop.to_s
            end
        end
    end
    header_rows.join("\n") + "\n" + rows.each_with_index.collect do |row, i|
        if options[:row_reverse]
            i_str = ((rows.length - 1) - i).to_s
        else
            i_str = i.to_s
        end
        (' ' * row_outer_margin) + (' ' * (rows_length_digits - i_str.length)) + i_str + (' ' * row_inner_margin) + row
    end.join("\n")
end

brick_r = /(?<x1>\d+),(?<y1>\d+),(?<z1>\d+)~(?<x2>\d+),(?<y2>\d+),(?<z2>\d+)/
bricks = []
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    parsed_line = brick_r.match(line)
    bricks.append(Brick.new(*parsed_line.captures.collect(&:to_i).append(bricks.length)))
end

volume = Volume.new(bricks)

puts volume.dimensions
puts volume.visualize(:y)
puts volume.visualize(:x)

volume.bricks_by_axis(:x)

puts "Settling..."
volume.settle!

puts volume.visualize(:y)
puts volume.visualize(:x)

falls_per_brick = {}
dependeny_tree = volume.dependeny_tree
support_tree = volume.support_tree

volume.bricks.each do |brick|
    chain = volume.find_chain(brick, support_tree, dependeny_tree)
    falls_per_brick[brick] = chain.length - 1
end

puts "\nBrick chain reaction total: #{falls_per_brick.sum {|k, v| v }}"
