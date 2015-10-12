require './isometric_factory.rb'

class CityFactory < PerlinFactory

  BUILDING_CHANCE = 5
  ROAD_CHANCE = 25
  FOLIAGE_CHANCE = 4
  FOLIAGE_SEED = 2
  ROOF_CHANCE = 5
  ROOF_SEED = 1

  def initialize(seed, size_x, size_y, size_z)
    super(seed, size_x, size_y, size_z)

    @building_colors = [0xFF_6A5039, 0xFF_F4E4CA, 0xFF_FFFDF2,
                        0xFF_E0E2DB, 0xFF_D2D4C8, 0xFF_B8BDB5,
                        0xFF_889696, 0xFF_F2C5A6, 0xFF_E49880,
                        0xFF_C37E61, 0xFF_D2D4C8, 0xFF_9D705D,
                        ]

    @assets.add_content("city_factory")
    @assets.add_alias(:grass, :tile)
    @assets.add_alias(:cement, :tile)
    @assets.add_alias(:water, :tile)
    @assets.add_alias(:roof_5, :small_block_1)
  end

  def is_tile_flipped_h?(x, y)
    type = get_tile_type(x, y)
    case(type)
      when :road_4_way
        false
      when :road_straight
        (get_perlin_bool_1d(y, 1, ROAD_CHANCE) && (view == :west || view == :east)) ||
            (get_perlin_bool_1d(x, 1, ROAD_CHANCE) && (view == :south || view == :north))
      else
        return false
    end
  end

  def is_a_road?(x, y)
    get_perlin_bool_1d(x, 1, ROAD_CHANCE) || get_perlin_bool_1d(y, 1, ROAD_CHANCE)
  end

  def get_tile_type(x, y)

    #see if it is a road first
    if is_a_road?(x, y)
      #find which axis
      if get_perlin_bool_1d(x, 1, ROAD_CHANCE) && get_perlin_bool_1d(y, 1, ROAD_CHANCE)
        return :road_4_way
      elsif (get_perlin_bool_1d(x, 1, ROAD_CHANCE) || get_perlin_bool_1d(y, 1, ROAD_CHANCE))
        return :road_straight
      end
    end

    height = get_perlin_height(x, y)
    if height == 0
      return :water
    elsif height < 3
      return :grass
    else
      return :cement
    end
  end

  def get_tile_color(x, y)
    if get_tile_type(x,y) == :grass
      return 0xff1ecc1e
    elsif get_tile_type(x,y) == :cement
      return 0xffe6e6e6
    elsif get_tile_type(x, y) == :water
      return 0xff0000ff
    end
    0xffffffff
  end

  def is_tile_buildable?(x, y)
    is_tile_type_buildable?(get_tile_type(x, y))
  end

  def is_tile_type_buildable?(type)
    !(assets.roads.include?(type) || type == :water || type.nil?)
  end

  def get_block_type(x, y, z)
    return nil unless is_block_at?(x, y, z)
    return nil unless is_tile_buildable?(x, y)

    if is_foliage_at?(x, y)
      if z == 0
        return get_perlin_item_3d(x, y, FOLIAGE_SEED, assets.foliage)
      else
        return nil
      end
    end

    #make it a roof sometimes if there is no block above
    if is_block_at?(x, y, z - 1) && !is_block_at?(x, y, z + 1) && is_block_buildable(x,y,z-1)
      #roll for a roof
      if get_perlin_bool_2d(x, y, 1, ROOF_CHANCE)
        if get_perlin_height(x, y) <  2
          return :roof_1
        end
        return get_perlin_item_3d(x, y, z, assets.roofs)
      end
    end

    if get_perlin_height(x, y) <= 1 && z == 0
      return :small_block_1
    elsif get_perlin_height(x, y) <= 1
      return nil
    end

    return :block
  end

  def get_block_color(x, y, z)
    if get_block_type(x,y,z) == :block || get_block_type(x, y, z) == :small_block_1 || assets.roofs.include?(get_block_type(x,y,z))
      return get_perlin_item_3d(x, y, 5, @building_colors)
    end

    0xffffffff
  end

  def is_block_flipped_h?(x, y, z)
    type = get_block_type(x, y, z)
    case(type)
      when :roof_1
        return get_perlin_bool_3d(x, y, z) if view == :north || view == :south
        return !get_perlin_bool_3d(x, y, z) if view == :east || view == :west
      when :small_block_1
        return get_perlin_bool_3d(x, y, z) if view == :north || view == :south
        return !get_perlin_bool_3d(x, y, z) if view == :east || view == :west

    end
  end

  def is_block_type_buildable?(type)
    !(assets.roofs.include?(type) || assets.foliage.include?(type)  || type == :small_block_1 || type.nil?)
  end

  def is_block_buildable(x, y, z)
    is_block_type_buildable?(get_block_type(x,y,z)) && is_tile_buildable?(x, y)
  end

  def is_block_at?(x, y, z)
    super(x, y, z) && (is_building_at?(x, y) || is_foliage_at?(x, y))
  end

  def is_foliage_at?(x, y)
    get_tile_type(x, y) == :grass && get_perlin_bool_2d(x, y, 1, FOLIAGE_CHANCE)
  end

  def is_building_at?(x, y)
    get_perlin_bool_2d(x, y, 1, BUILDING_CHANCE) && is_tile_buildable?(x, y) && !is_foliage_at?(x, y)
  end

  def get_features(x, y, z)

  end

  def draw_features(x, y, z)

  end
end
