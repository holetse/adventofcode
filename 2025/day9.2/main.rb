class Polygon
  attr_reader :vertices
  attr_reader :edges
  
  Vertex = Struct.new(:x, :y) do
    def area_between(vertex)
      ((x-vertex.x).abs + 1) * ((y-vertex.y).abs + 1)
    end

    def adjacent_points(vertex)
      [[x, vertex.y], [vertex.x, y]]
    end

    def point
      [x, y]
    end

    def to_s
      inspect
    end

    def inspect
      "<vertex @#{x},#{y}>"
    end
  end
  
  Edge = Struct.new(:v1, :v2) do
    def horizontal_edge?
      v1.y == v2.y
    end
    
    def vertical_edge?
      v1.x == v2.x
    end
    
    def length
      (vertical_edge? ? (v2.y - v1.y) : (v2.x - v1.x)).abs
    end
    
    def range
      start_at, end_at = (vertical_edge? ? [v1.y, v2.y] : [v1.x, v2.x]).minmax
      if vertical_edge?
        end_at += 1
      else
        start_at += 1
      end
      (start_at..(end_at - 1))
    end
    
    def overlap?(edge_or_range)
      other_range = edge_or_range.respond_to?(:range) ? edge_or_range.range : edge_or_range
      other_range.overlap?(range)
    end

    def cover?(edge)
      range.cover?(edge.range)
    end

    def to_s
        inspect
    end

    def inspect
      "<edge (#{v1.x},#{v1.y})--(#{v2.x},#{v2.y})>"
    end
  end
  
  def initialize(*args)
    @vertices = []
    @edges = []
    super(*args)
  end
  
  def append(x, y)
    last = vertices.last
    v = Vertex.new(x, y)
    @vertices.append(v)
    @edges.append(Edge.new(last, v)) if last
    @valid_pairs = nil
    @horizontal_edges = nil
    @vertical_edges = nil
    @horizontal_edge_tbl = nil
    @vertical_edge_tbl = nil
    raise "unsupported diagonal: #{x},#{y}" if last && (last.x != x && last.y != y)
    vertices.last
  end
  
  def horizontal_edges
    @horizontal_edges ||= edges.select(&:horizontal_edge?).sort { |a, b| a.v1.y <=> b.v1.y }
  end
  
  def vertical_edges
    @vertical_edges ||= edges.select(&:vertical_edge?).sort { |a, b| a.v1.x <=> b.v1.x }
  end
  
  def horizontal_edge_tbl
    @horizontal_edge_tbl ||= horizontal_edges.reduce({}) do |tbl, edge|
      tbl[edge.v1.y] ||= []
      tbl[edge.v1.y].append(edge)
      tbl
    end
  end

  def vertical_edge_tbl
    @vertical_edge_tbl ||= vertical_edges.reduce({}) do |tbl, edge|
      tbl[edge.v1.x] ||= []
      tbl[edge.v1.x].append(edge)
      tbl
    end
  end
  
  def on_horizontal_edge?(x, y)
    (horizontal_edge_tbl[y] || []).each do |edge|
      return true if edge.range.include?(x)
    end
    
    return false
  end
  
  def cover?(x, y)
    
    return true if on_horizontal_edge?(x, y)
    
    crossings = 0
    last_crossing = nil
    vertical_edges.each do |edge|
      break if edge.v1.x > x
      if edge.range.include?(y)
        if edge.v1.x == x
          return true
        else
          crossings += 1
          if last_crossing
            # horizontal edge check between last_crossing..edge
            horizontal_edge_range = (last_crossing.v1.x..edge.v1.x)
            found_edges = (horizontal_edge_tbl[y] || []).select do |e|
              e.overlap?(horizontal_edge_range)
            end
            if found_edges.length == 1
              # need to check curvature direction
              if !(edge.range.include?(y - 1) && last_crossing.range.include?(y - 1)) && !(edge.range.include?(y + 1) && last_crossing.range.include?(y + 1))
                crossings -= 1 # we counted an extra edge
              end
            elsif found_edges.length > 1
              raise "bad edge check #{edge}"
            end
          end
          last_crossing = edge
        end
      end
    end
    
    crossings.odd?
  end

  def cover_edge?(edge)
    if edge.horizontal_edge?
      min, max = [edge.v1.x, edge.v2.x].minmax
      table = vertical_edge_tbl
    else
      min, max = [edge.v1.y, edge.v2.y].minmax
      table = horizontal_edge_tbl
    end
    possible_edges = table.keys.find_all { |key| key > min && key < max }.collect { |key| table[key] }.flatten
    !possible_edges.flatten.find do |other|
      if edge.horizontal_edge?
        other.range.include?(edge.v1.y) && other.range.end != edge.v1.y && other.range.begin != edge.v1.y
      else
        other.range.include?(edge.v1.x) && other.range.end != edge.v1.x && other.range.begin != edge.v1.x
      end
    end
  end

end

class TheaterFloor < Polygon
  def valid_pairs
    @valid_pairs ||= every_pair(vertices).find_all { |pair| valid_pair(pair) }
  end
  
  private

  def valid_pair(pair)
    adjacent = pair[0].adjacent_points(pair[1]).collect { |point| Polygon::Vertex.new(*point) }
      edges = [
        Edge.new(pair[0], adjacent[0]),
        Edge.new(pair[0], adjacent[1]),
        Edge.new(pair[1], adjacent[0]),
        Edge.new(pair[1], adjacent[1])
      ]
      # all four corners are valid, now we need to check for edge crossings
      cover?(*adjacent[0].point) && cover?(*adjacent[1].point) && !edges.find { |edge| !cover_edge?(edge) }
  end
  
  def every_pair(objs)
    pairs = []
    unpaired = objs.dup
    while obj = unpaired.pop do
      pairs_for_obj = unpaired.collect { |other| [obj, other] }
      pairs.push(*pairs_for_obj)
    end
    pairs
  end
  
end

class PrintableTheaterFloor < TheaterFloor
  def bounds
    return @bounds if @bounds
    
    min_x, max_x = vertices.collect(&:x).minmax
    min_y, max_y = vertices.collect(&:y).minmax
    @bounds = [[min_x, min_y], [max_x, max_y]]
  end
  
  def extent
    [[bounds[0][0], bounds[1][0]], [bounds[0][1], bounds[1][1]]]
  end
  
  def visualize(method=:edge?)
    grid.visualize(method)
  end

  def to_svg(scale: 1/10.0, overlay_polygons: [])
    width = extent[0][1] - extent[0][0]
    height = extent[1][1] - extent[1][0]
    points = vertices.collect { |v| "#{v.x * scale},#{v.y * scale}"}
    overlays_svg = overlay_polygons.collect do |polygon|
      overlay_points = polygon.collect { |v| "#{v[0] * scale},#{v[1] * scale}"}
      <<~SVG
        <polygon points="#{overlay_points.join(' ')}" style="fill:blue;stroke:red;stroke-width:0.1" />
      SVG
    end
    <<~SVG
      <svg height="#{height * scale}" width="#{width * scale}" xmlns="http://www.w3.org/2000/svg">
        <polygon points="#{points.join(' ')}" style="fill:lime;stroke:purple;stroke-width:0.1" />
        #{overlays_svg.join("\n")}
      </svg>
    SVG
  end
end

floor = PrintableTheaterFloor.new
r = /(\d+),(\d+)/
File.readlines(File.join(__dir__, 'input.txt'), chomp: true).collect do |line|
  match = line.match(r)
  floor.append(*(match[1..2].collect(&:to_i)))
end
floor.append(*floor.vertices.first.point)

vertex_areas = floor.valid_pairs.collect { |pair| pair[0].area_between(pair[1]) }.sort

puts "the largest area = #{vertex_areas.last}"