#! /usr/bin/env ruby

require './key.rb'
require './isometric_factory.rb'
require './factories/perlin_factory'
require './factories/city_factory'
require './factories/edge_test_factory.rb'
require './factories/sine_wave_factory.rb'

require './monkey_patch.rb'

require 'gosu'
require 'benchmark'

class Game < Gosu::Window

  CAMERA_SPEED = 10
  SIZE_X = 50
  SIZE_Y = 50
  SIZE_Z = 8
  def initialize
    super(1200, 600, false)

    Gosu::enable_undocumented_retrofication

    @camera = Vector2.new(0,0)
    @generators = [EdgeTestFactory, SineWaveFactory, PerlinFactory, CityFactory]
    @generator = 0

    @zoom_modes = [0.5, 1, 2, 4, 8, 16, 32]
    @zoom = 1


    @factory = @generators[@generator].new(rand(100_000_00), SIZE_X, SIZE_Y, SIZE_Z)

    @draw_blocks = true
    @draw_grid = true

    @time = 0

    @render_mode = :draw_easy

    @close_button = Key.new Gosu::KbEscape
    @random_button = Key.new Gosu::KbSpace
    @next_view_button = Key.new Gosu::KbA
    @last_view_button = Key.new Gosu::KbS
    @draw_easy_button = Key.new Gosu::KbG
    @draw_hard_button = Key.new Gosu::KbH
    @rotate_cw_button = Key.new Gosu::KbW
    @rotate_ccw_button = Key.new Gosu::KbQ
    @zoom_in_button = Key.new Gosu::KbZ
    @zoom_out_button = Key.new Gosu::KbX

    @draw_grid_button = Key.new Gosu::KbE
    @draw_blocks_button = Key.new Gosu::KbR

    @debug_button = Key.new Gosu::KbC
  end

  def update
    Key.update_keys self

    close if @close_button.is_down?

    if @random_button.was_pressed?
      force_redraw
      view = @factory.view
      @factory = @generators[@generator].new(rand(100_000_00), SIZE_X, SIZE_Y, SIZE_Z)
      @factory.view = view
    end

    @camera.x -= CAMERA_SPEED if button_down? Gosu::KbRight
    @camera.x += CAMERA_SPEED if button_down? Gosu::KbLeft

    @camera.y -= CAMERA_SPEED if button_down? Gosu::KbDown
    @camera.y += CAMERA_SPEED if button_down? Gosu::KbUp

    if @next_view_button.was_pressed?
      @generator += 1
      @generator = 0 if @generator > @generators.length-1
      force_redraw
      view = @factory.view
      @factory = @generators[@generator].new(@factory.seed, SIZE_X, SIZE_Y, SIZE_Z)
      @factory.view = view
    end

    if @last_view_button.was_pressed?
      @generator -= 1
      @generator = @generators.length-1 if @generator < 0
      force_redraw
      view = @factory.view
      @factory = @generators[@generator].new(@factory.seed, SIZE_X, SIZE_Y, SIZE_Z)
      @factory.view = view
    end

    if @draw_hard_button.was_pressed?
      @render_mode = :draw_hard
    end

    if @draw_easy_button.was_pressed?
      @render_mode = :draw_easy
    end

    if @rotate_ccw_button.was_pressed?
      @factory.rotate_counter_clockwise
      force_redraw
    end

    if @rotate_cw_button.was_pressed?
      @factory.rotate_clockwise
      force_redraw
    end

    if @zoom_in_button.was_pressed?
      @zoom += 1
      @zoom = @zoom_modes.length-1 if @zoom >= @zoom_modes.length
    end

    if @zoom_out_button.was_pressed?
      @zoom -= 1
      @zoom = 0 if @zoom < 0
    end

    if@draw_grid_button.was_pressed?
      @draw_grid = !@draw_grid
      force_redraw
    end

    if @draw_blocks_button.was_pressed?
      @draw_blocks = !@draw_blocks
      force_redraw
    end

    if @debug_button.was_pressed?
      @factory.debug = !@factory.debug
      force_redraw
    end

    self.caption = "ICG c:#{@camera.x},#{@camera.y} fps: #{Gosu.fps} seed: #{@factory.seed} g_t: #{@factory.fill_cache_time} d_t: #{@time} debug:#{@factory.debug}"

    Key.post_update_keys self
  end

  def draw
    #draw first
    send @render_mode
  end

  def draw_easy
    @image ||= record(1, 1) do
      #profiler = MethodProfiler.observe(IsometricFactory)
      @time = Benchmark.realtime do
        @factory.draw_grid if @draw_grid
        @factory.draw_blocks if @draw_blocks
      end
      #puts profiler.report.sort_by(:total_calls).order(:ascending)
    end
    translate(@camera.x, @camera.y) do
      @image.draw(740, 190, 1, @zoom_modes[@zoom], @zoom_modes[@zoom])
    end
  end

  def draw_hard
    translate(@camera.x, @camera.y) do
      @factory.draw_grid if @draw_grid
      @factory.draw_blocks if @draw_blocks
    end
  end

  def force_redraw
    @image = nil
  end
end

#profiler = MethodProfiler.observe(IsometricFactory)
Game.new.show
#puts profiler.report

