require 'perlin'

class IsometricFactory
  PERLIN_NOISE_STEP = 0.02
  OFFSET = Point.new(0, 0)
  MAX_HEIGHT = 10

  attr_reader :perlin_noise
  attr_reader :size_x, :size_y


  def initialize(size_x, size_y)
    @size_x = size_x
    @size_y = size_y
    @perlin_noise = Perlin::Generator.new(rand(1000), 1.0, 1)
    @colors = []
    @colors << 0xffffcc97
    @colors << 0xffffa179
    @colors << 0xffd34b59
    @colors << 0xffc13759
    @colors << 0xff744268
  end

  def randomize
    @perlin_noise = Perlin::Generator.new(rand(1000), 2.0, 1)
  end

  def self.get_tile_position(x, y)
    spacing = Point.new((Assets.tile_width/2.0).round, (Assets.tile_height/2.0).round)
    Point.new((-x * spacing.x) + (y * spacing.x) - y + x + OFFSET.x,
              (x * spacing.y) + (y*spacing.y) - y - x + OFFSET.y)
  end

  def get_tile_type(x, y)

  end

  def get_building_type(x, y)

  end

  def get_building_height(x, y)

  end

  def self.get_block_position(x, y, z)
    position = get_tile_position(x,y)
    position.y -= (Assets.block_height / 2.0).round * (z + 1)
    position
  end

  def get_perlin_noise(x, y)
    @perlin_noise[x * PERLIN_NOISE_STEP, y * PERLIN_NOISE_STEP]
  end

  #Finds if there is a block at the specified location
  def is_perlin_block_at?(x, y, z)
    (get_perlin_noise(x, y) * MAX_HEIGHT).round >= z
  end

  def is_city_block_at?(x, y, z)
    false
  end

  def draw_grid
    size_x.times do |x|
      size_y.times do |y|
        position = self.class.get_tile_position(x,y)
        Assets.get_tile_image(:base_tile).draw(position.x, position.y, 1, 1, 1, 0xffffcc97)
      end
    end
  end

  def draw_block(x, y, z)
    color_index = ((z / MAX_HEIGHT.to_f).clamp(0, 1.0)*@colors.length).to_i
    position = IsometricFactory.get_block_position(x, y, z)
    Assets.get_block_asset(:base_block).draw(position, 1, @colors[color_index])
  end

  def draw_perlin_blocks
    size_x.times do |x|
      size_y.times do |y|
        height = (get_perlin_noise(x, y) * MAX_HEIGHT).round
        height.times do |z|
          #skip drawing this block if we can't see it anyways.
          next if is_perlin_block_at?(x + 1, y + 1, z + 1) && x == size_x && y != size_y
          draw_block(x,y,z)
        end
      end
    end
  end

  def draw_city
    size_x.times do |x|
      size_y.times do |y|
        height = (get_perlin_noise(x, y) * MAX_HEIGHT).round
        #should we have a building here?
        build_value = "0.#{get_perlin_noise(x,y).to_s[-2..-1]}".to_f * 4
        next if build_value > get_perlin_noise(x, y)

        height.times do |z|
          #skip drawing this block if we can't see it anyways.
          next if is_city_block_at?(x + 1, y + 1, z + 1) && x == size_x && y != size_y
          draw_block(x,y,z)
        end
      end
    end
  end
end