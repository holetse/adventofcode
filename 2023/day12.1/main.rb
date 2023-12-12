class Node
    include Enumerable
    attr_accessor :value, :operational, :damaged, :parent

    def initialize(value, operational = nil, damaged = nil, parent = nil, *args)
        self.value = value
        self.operational = operational
        self.damaged = damaged
        self.parent = parent
        super(*args)
    end

    def operational=(node)
        @operational = node
        node.parent = self if !node.nil?
    end

    def damaged=(node)
        @damaged = node
        node.parent = self if !node.nil?
    end

    def each
        operational.each { |l| yield l } if !operational.nil?
        yield self
        damaged.each { |r| yield r } if !damaged.nil?
    end

    def leaves
        if operational.nil? && damaged.nil?
            yield self 
        else
            operational.leaves { |l| yield l } if !operational.nil?
            damaged.leaves { |r| yield r } if !damaged.nil?
        end
    end
    
    def depth
        count = 0
        node = self
        while node.parent
            count += 1
            node = node.parent
        end

        count
    end

    def branch_value
        values = [value]
        node = self
        while node.parent
            if node.parent.operational == node
                values.append('.')
            else
                values.append('#')
            end
            node = node.parent
            values.append(node.value)
        end

        values.reverse.join('')
    end

    def visualize_branch
        values = [value]
        node = self
        while node.parent
            node = node.parent
            values.append('->', "#{node.value}?")
        end

        values.reverse.join('')
    end

    def to_s
        "<'#{value}' operational=#{operational.inspect} damaged=#{damaged.inspect} parent=#{parent.inspect}>"
    end
end

Record = Struct.new(:fragment, :spans) do

    def spans_r
        @spans_r ||= Regexp.new("^\\.*#{spans.collect {|c| "\#{#{c}}" }.join('\\.+')}\\.*$")
    end
    def possibilites
        return @possibilites if !@possibilites.nil?

        tree = nil
        fixed = ''
        fragment.split('').each do |c|
            if (c == '?')
                if tree.nil?
                    tree = Node.new(fixed, Node.new(''), Node.new(''))
                else
                    tree.leaves do |leaf|
                        leaf.value += fixed
                        leaf.operational = Node.new('')
                        leaf.damaged = Node.new('')
                    end
                end
                fixed = ''
            else
                fixed += c
            end
        end
        if fixed.length > 0
            tree.leaves do |leaf|
                leaf.value += fixed
            end
        end

        possibilites = []
        tree.leaves do |leaf|
            possibility = leaf.branch_value
            possibilites.append(possibility) if spans_r.match(possibility)
        end
        @possibilites = possibilites
    end
end

records = []
File.readlines("input.txt", chomp: true).each do |line|
    fragment, spans_str = line.split
    spans = spans_str.split(',').collect(&:to_i)
    records.append(Record.new(fragment, spans))
end


puts "Possibilites: #{records.sum {|r| r.possibilites.length }}"

