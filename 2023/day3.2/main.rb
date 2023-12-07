matrix = []

def get_cell(m, row, col)
    if (row < m.length && row >= 0) && (col < m[row].length && col >= 0)
        return m[row][col][:cell]
    end
    return false
end

def get_part(m, row, col)
    if (row < m.length && row >= 0) && (col < m[row].length && col >= 0)
        return m[row][col]
    end
    return false
end

def set_part_id(m, row, col, part_id)
    m[row][col][:part_id] = part_id
end

def set_part_number(m, row, col, part_number)
    m[row][col][:part_number] = part_number
end

def get_3x3(m, row, col)
    offets = [
        [-1, -1], [-1, 0], [-1, 1],
        [0, -1], [0, 0], [0, 1],
        [1, -1], [1, 0], [1, 1]
    ]
    cells = offets.collect { |o| get_cell(m, row + o.first, col + o.last) }
    return cells
end

def get_3x3_part(m, row, col)
    offets = [
        [-1, -1], [-1, 0], [-1, 1],
        [0, -1], [0, 0], [0, 1],
        [1, -1], [1, 0], [1, 1]
    ]
    parts = offets.collect { |o| get_part(m, row + o.first, col + o.last) }
    return parts
end

def is_part_number?(m, row, col, len)
    cells = []
    0.upto(len - 1) do |offset|
        cells.append(get_3x3(m, row, col + offset))
    end
    return !cells.flatten.select(&:itself).join('').gsub(/\d|\./, '').empty?
end

def mark_part_number(m, row, col, len, part_id, part_number)
    0.upto(len - 1) do |offset|
        set_part_id(m, row, col + offset, part_id)
        set_part_number(m, row, col + offset, part_number)
    end
end

def get_gear_ratio(m, row, col)
    if get_cell(m, row, col) == '*'
        parts = get_3x3_part(m, row, col).reject { |p| p[:part_id].nil? }
        unique_parts = parts.flatten.uniq { |p| p[:part_id] }
        if unique_parts.length == 2
            return unique_parts.reduce(1) { |ratio, part| ratio * part[:part_number].to_i }
        end
    end
    return false
end

part_number_sum = 0
part_id = 1
ratio_sum = 0

File.readlines("input.txt", chomp: true).each do |line|
    row = line.split('').collect { |c| { cell: c, part_id: nil, part_number: nil }}
    matrix.push(row)
end

0.upto(matrix.length - 1) do |row|
    part_number = ''
    0.upto(matrix[row].length - 1) do |col|
        cell = get_cell(matrix, row, col)
        if cell.match(/\d/)
            part_number += cell
        elsif part_number.length > 0
            if is_part_number?(matrix, row, col - part_number.length, part_number.length)
                puts "part number: #{part_number}"
                part_number_sum += part_number.to_i
                mark_part_number(matrix, row, col - part_number.length, part_number.length, part_id, part_number)
                part_id += 1
            else
                puts "NOT part number: #{part_number}, #{row}, #{col}"
            end
            part_number = ''
        end
    end
    if part_number.length > 0
        part_col = matrix[row].length - part_number.length - 1
        if is_part_number?(matrix, row, part_col, part_number.length)
            puts "part number: #{part_number}"
            part_number_sum += part_number.to_i
            mark_part_number(matrix, row, part_col, part_number.length, part_id, part_number)
            part_id += 1
        else
            puts "NOT part number: #{part_number}"
        end
        part_number = ''
    end
end

0.upto(matrix.length - 1) do |row|
    0.upto(matrix[row].length - 1) do |col|
        if ratio = get_gear_ratio(matrix, row, col)
            puts "GEAR part: #{row}, #{col}, #{ratio}"
            ratio_sum += ratio
        end
    end
end

# puts "cells: ", get_3x3(matrix, 3, 3)
# puts "part number: ", is_part_number?(matrix, 139, 6, 3)
puts "part number sum: #{part_number_sum}"
puts "ratio sum: #{ratio_sum}"