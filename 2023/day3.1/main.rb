matrix = []

def get_cell(m, row, col)
    if (row < m.length && row >= 0) && (col < m[row].length && col >= 0)
        return m[row][col]
    end
    return false
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

def is_part_number?(m, row, col, len)
    cells = []
    0.upto(len - 1) do |offset|
        cells.append(get_3x3(m, row, col + offset))
    end
    return !cells.flatten.select(&:itself).join('').gsub(/\d|\./, '').empty?
end

part_number_sum = 0

File.readlines("input.txt", chomp: true).each do |line|
    row = line.split('')
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
                part_number_sum += part_number.to_i
                puts "part number: #{part_number}"
            else
                puts "NOT part number: #{part_number}, #{row}, #{col}"
            end
            part_number = ''
        end
    end
    if part_number.length > 0
        if is_part_number?(matrix, row, matrix[row].length - part_number.length - 1, part_number.length)
            part_number_sum += part_number.to_i
            puts "part number: #{part_number}"
        else
            puts "NOT part number: #{part_number}"
        end
        part_number = ''
    end
end

# puts "cells: ", get_3x3(matrix, 3, 3)
# puts "part number: ", is_part_number?(matrix, 139, 6, 3)
puts "part number sum: #{part_number_sum}"