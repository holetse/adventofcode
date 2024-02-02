Hailstone = Struct.new(:x, :y, :z, :dx, :dy, :dz)

def gauss_elim!(m)
    n = m.length
    row = 1
    1.upto(n - 1) do |k|
        p, pi = m.each_with_index.to_a[(row-1)..].max { |a,b| a[0][k-1] <=> b[0][k-1] }
        raise "singular" if p[k-1] == 0
        m[pi] = m[row-1]
        m[row-1] = p
        (k + 1).upto(n) do |i|
            m[i-1][k-1] = m[i-1][k-1] / m[k-1][k-1]
            (k + 1).upto(n+1) do |j|
                m[i-1][j-1] = m[i-1][j-1] - (m[i-1][k-1] * m[k-1][j-1])
            end
            m[i-1][k-1] = 0
        end
        row += 1
    end

    n.downto(1) do |i|
        (i + 1).upto(n) do |j|
            m[i-1][n] = m[i-1][n] - (m[i-1][j-1] * m[j-1][n])
        end
        m[i-1][n] = m[i-1][n] / m[i-1][i-1]
    end

    m
end

def build_augmented_matrix(a, b, c)
    # X Y Z DX DY DZ B
    m = [
        # a-b
        [b.dy - a.dy, a.dx - b.dx, 0, a.y - b.y, b.x - a.x, 0, (b.x * b.dy) - (b.y * b.dx) - (a.x * a.dy) + (a.y * a.dx)],
        [b.dz - a.dz, 0, a.dx - b.dx, a.z - b.z, 0, b.x - a.x, (b.x * b.dz) - (b.z * b.dx) - (a.x * a.dz) + (a.z * a.dx)],
        [0, a.dz - b.dz, b.dy - a.dy, 0, b.z - a.z, a.y - b.y, (b.z * b.dy) - (b.y * b.dz) - (a.z * a.dy) + (a.y * a.dz)],
        #a-c
        [c.dy - a.dy, a.dx - c.dx, 0, a.y - c.y, c.x - a.x, 0, (c.x * c.dy) - (c.y * c.dx) - (a.x * a.dy) + (a.y * a.dx)],
        [c.dz - a.dz, 0, a.dx - c.dx, a.z - c.z, 0, c.x - a.x, (c.x * c.dz) - (c.z * c.dx) - (a.x * a.dz) + (a.z * a.dx)],
        [0, a.dz - c.dz, c.dy - a.dy, 0, c.z - a.z, a.y - c.y, (c.z * c.dy) - (c.y * c.dz) - (a.z * a.dy) + (a.y * a.dz)],
    ]
end

stones_r = /^(?<x>-?\d+),\s+(?<y>-?\d+),\s+(?<z>-?\d+)\s+@\s+(?<dx>-?\d+),\s+(?<dy>-?\d+),\s+(?<dz>-?\d+)$/
stones = []
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).each do |line|
    parsed_stone = stones_r.match(line)
    stones.append(Hailstone.new(parsed_stone[:x].to_r, parsed_stone[:y].to_r, parsed_stone[:z].to_r, parsed_stone[:dx].to_r, parsed_stone[:dy].to_r, parsed_stone[:dz].to_r))
end

m = build_augmented_matrix(stones[0], stones[1], stones[2])
gauss_elim!(m)
x, y, z, dx, dy, dz = m.collect { |row| row[-1] }
puts "Stone #{x}, #{y}, #{z} @ #{dx}, #{dy}, #{dz}"
puts "Sum of Coordinates: #{x + y + z}"
