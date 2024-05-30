require 'ruby2d'

set title: 'Battle Of The Ships'
set width: 1200
set height: 700

class Player
  WIDTH = 96
  HEIGHT = 138

  attr_accessor :image, :x, :y, :speed, :fire_rate, :bullets

  def initialize(image, x, y, speed, fire_rate)
    @x_velocity = 0
    @y_velocity = 0
    @image = image
    @x = x
    @y = y
    @speed = speed
    @last_fired_frame = 0
    @fire_rate = fire_rate
    @bullets = []
    @sprite = Sprite.new(
      image,
      clip_width: 32,
      width: WIDTH,
      height: HEIGHT,
      x: x,
      y: y,
      rotate: 0,
      animations: {
        move_slow: 1..2,
        move_fast: 3..4
      }
    )
  end

  def animation_slow
    @sprite.play(animation: :move_slow, loop: true)
  end

  def animation_fast
    @sprite.play(animation: :move_fast, loop: true)
  end

  ROTATION_SPEED = 3
  VELOCITY_SPEED = 0.1

  def rotate(direction)
    case direction
    when :left
      @sprite.rotate -= ROTATION_SPEED
    when :right
      @sprite.rotate += ROTATION_SPEED
    end
  end

  MAX_SPEED = 10

  def accelerate(direction)
    angle_rad = @sprite.rotate * Math::PI / 180
    animation_fast # animate fast when moving forward and backward
    case direction
    when :forward
      @x_velocity += Math.sin(angle_rad) * VELOCITY_SPEED * @speed / 100.0
      @y_velocity -= Math.cos(angle_rad) * VELOCITY_SPEED * @speed / 100.0
    when :backward
      @x_velocity -= Math.sin(angle_rad) * VELOCITY_SPEED * @speed / 100.0
      @y_velocity += Math.cos(angle_rad) * VELOCITY_SPEED * @speed / 100.0
    end

    total = @x_velocity.abs + @y_velocity.abs
    if total > MAX_SPEED
      @x_velocity *= MAX_SPEED / total
      @y_velocity *= MAX_SPEED / total
    end
  end

  def move
    @sprite.x += @x_velocity
    @sprite.y += @y_velocity

    if @sprite.x > Window.width + @sprite.width
      @sprite.x = -@sprite.width
    elsif @sprite.x < -@sprite.width
      @sprite.x = Window.width + @sprite.width
    end

    if @sprite.y > Window.height + @sprite.height
      @sprite.y = -@sprite.height
    elsif @sprite.y < -@sprite.height
      @sprite.y = Window.height + @sprite.height
    end

    i = 0
    while i < @bullets.length
      @bullets[i].move
      if @bullets[i].image.x < -Bullet::WIDTH || @bullets[i].image.x > Window.width || @bullets[i].image.y < -Bullet::HEIGHT || @bullets[i].image.y > Window.height
        @bullets[i].remove
        @bullets.delete_at(i)
      else
        i += 1
      end
    end
  end

  def halt
    animation_slow
  end

  def fire_bullet
    angle_rad = @sprite.rotate * Math::PI / 180
    if (@last_fired_frame + 15 - (@fire_rate / 10) < Window.frames)
      x_component = Math.sin(angle_rad)
      y_component = -Math.cos(angle_rad)

      x = @sprite.x + @sprite.width * 0.5 + (x_component * @sprite.width)
      y = @sprite.y + @sprite.height * 0.5 + (y_component * @sprite.height)

      @bullets << Bullet.new(x, y, @sprite.rotate)
      @last_fired_frame = Window.frames
    end
  end
end

class Bullet
  WIDTH = 6 * 3
  HEIGHT = 5 * 3
  BULLET_SPEED = 10

  attr_reader :image

  def initialize(x, y, rotate)
    @bullet_sound = Sound.new('laser.mp3')
    @bullet_sound.play

    @image = Sprite.new(
      'bullet.png',
      width: WIDTH,
      height: HEIGHT,
      x: x,
      y: y,
      rotate: rotate
    )

    @x_velocity = Math.sin(@image.rotate * Math::PI / 180) * BULLET_SPEED
    @y_velocity = -Math.cos(@image.rotate * Math::PI / 180) * BULLET_SPEED
  end

  def move
    @image.x += @x_velocity
    @image.y += @y_velocity

    if @image.x < -WIDTH || @image.x > Window.width || @image.y < -HEIGHT || @image.y > Window.height
      remove
    end
  end

  def remove
    @image.remove
  end

  def hitbox
    x1 = @image.x
    y1 = @image.y
    x2 = @image.x + WIDTH
    y2 = @image.y + HEIGHT
    [x1, y1, x2, y2]
  end
end

class PlayerSelectScreen
  def initialize
    title_text = Text.new('BATTLE OF THE SHIPS', size: 70, y: 40)
    title_text.x = (Window.width - title_text.width) / 2

    player_select_text = Text.new('SELECT YOUR SHIP', size: 30, y: 120)
    player_select_text.x = (Window.width - player_select_text.width) / 2

    @players = [
      Player.new('ship_1.png', Window.width * (1 / 4.0) - Player::WIDTH / 2, 240, 80, 80),
      Player.new('ship_2.png', Window.width * (2 / 4.0) - Player::WIDTH / 2, 240, 60, 90),
      Player.new('ship_3.png', Window.width * (3 / 4.0) - Player::WIDTH / 2, 240, 90, 60)
    ]

    @selected_player = 1
    @speed_texts = []
    @fire_rate_texts = []
    i = 0
    while i < @players.length
      player = @players[i]
      @speed_texts << Text.new("Speed - #{player.speed}%", size: 20, x: player.x, y: player.y + 200, color: Color.new([1, 1, 1, 0]))
      @fire_rate_texts << Text.new("Fire Rate - #{player.fire_rate}%", size: 20, x: player.x, y: player.y + 230, color: Color.new([1, 1, 1, 0]))
      i += 1
    end
    animate_players(@players, @selected_player)
    player_stat_text(@players, @selected_player)
  end

  def animate_players(players, selected_player)
    i = 0
    while i < players.length
      if i == selected_player
        players[i].animation_fast
      else
        players[i].animation_slow
      end
      i += 1
    end
  end

  def change(direction)
    if direction == :left
      @selected_player = (@selected_player - 1) % @players.length
    elsif direction == :right
      @selected_player = (@selected_player + 1) % @players.length
    end
    animate_players(@players, @selected_player)
    player_stat_text(@players, @selected_player)
  end

  def player_stat_text(players, selected_player)
    i = 0
    while i < players.length
      if i == selected_player
        @speed_texts[i].color = Color.new([1, 1, 1, 1])
        @fire_rate_texts[i].color = Color.new([1, 1, 1, 1])
      else
        @speed_texts[i].color = Color.new([1, 1, 1, 0])
        @fire_rate_texts[i].color = Color.new([1, 1, 1, 0])
      end
      @speed_texts[i].text = "Speed - #{players[i].speed}%"
      @speed_texts[i].x = players[i].x + (Player::WIDTH - @speed_texts[i].width) / 2
      @fire_rate_texts[i].text = "Fire Rate - #{players[i].fire_rate}%"
      @fire_rate_texts[i].x = players[i].x + (Player::WIDTH - @fire_rate_texts[i].width) / 2
      i += 1
    end
  end

  def update
    # No specific update logic needed for player select screen
  end

  def selected_player
    @players[@selected_player]
  end
end

class GameScreen
  MAX_ASTEROID = 6

  def initialize(player)
    @background_music = Sound.new('mario.mp3')
    @background_music.loop = true
    @background_music.play

    @player = Player.new(player.image, Window.width / 2, Window.height / 2, player.speed, player.fire_rate)
    @player.animation_slow
    @asteroids = []
    @last_asteroid_time = Time.now
  end

  def update
    @player.move

    current_time = Time.now
    if (current_time - @last_asteroid_time >= 2) && (@asteroids.size < MAX_ASTEROID)
      @asteroids << Asteroid.new
      @last_asteroid_time = current_time
    end

    i = 0
    while i < @asteroids.length
      @asteroids[i].move
      if @asteroids[i].sprite.x < -Asteroid::WIDTH || @asteroids[i].sprite.x > Window.width || @asteroids[i].sprite.y < -Asteroid::HEIGHT || @asteroids[i].sprite.y > Window.height
        @asteroids[i].remove
        @asteroids.delete_at(i)
      else
        i += 1
      end
    end

    check_collisions
  end

  def rotate(direction)
    @player.rotate(direction)
  end

  def accelerate(direction)
    @player.accelerate(direction)
  end

  def halt
    @player.halt
  end

  def fire_bullet
    @player.fire_bullet
  end

  def stop_music
    @background_music.stop
  end

  def check_collisions
    i = 0
    while i < @player.bullets.length
      j = 0
      while j < @asteroids.length
        if check_collision(@player.bullets[i], @asteroids[j])
          @player.bullets[i].remove
          @asteroids[j].remove
          @player.bullets.delete_at(i)
          @asteroids.delete_at(j)
          break
        end
        j += 1
      end
      i += 1 unless @player.bullets[i].nil?
    end
  end

  def check_collision(bullet, asteroid)
    bullet_x1, bullet_y1, bullet_x2, bullet_y2 = bullet.hitbox
    asteroid_x1, asteroid_y1, asteroid_x2, asteroid_y2 = asteroid.hitbox

    if bullet_x2 < asteroid_x1 || bullet_x1 > asteroid_x2 ||
       bullet_y2 < asteroid_y1 || bullet_y1 > asteroid_y2
      return false
    else
      return true
    end
  end
end

class Asteroid
  WIDTH = 58
  HEIGHT = 61

  attr_reader :sprite

  def initialize
    @sprite = Sprite.new(
      'asteroid.png',
      x: rand(Window.width),
      y: rand(Window.height),
      width: WIDTH,
      height: HEIGHT,
      clip_width: 58,
      clip_height: 61,
      rotate: rand(360)
    )
  end

  def move
    # Asteroids do not move in this implementation
  end

  def hitbox
    x1 = @sprite.x
    y1 = @sprite.y
    x2 = @sprite.x + WIDTH
    y2 = @sprite.y + HEIGHT
    [x1, y1, x2, y2]
  end

  def remove
    @sprite.remove
  end
end

current_screen = PlayerSelectScreen.new

update do
  current_screen.update
end

on :key_down do |event|
  case current_screen
  when PlayerSelectScreen
    case event.key
    when 'left'
      current_screen.change(:left)
    when 'right'
      current_screen.change(:right)
    when 'return'
      Window.clear
      current_screen = GameScreen.new(current_screen.selected_player)
    end
  when GameScreen
    case event.key
    when 'escape'
      current_screen.stop_music
      Window.clear
      current_screen = PlayerSelectScreen.new
    end
  end
end

on :key_held do |event|
  case current_screen
  when GameScreen
    case event.key
    when 'up'
      current_screen.accelerate(:forward)
    when 'down'
      current_screen.accelerate(:backward)
    when 'left'
      current_screen.rotate(:left)
    when 'right'
      current_screen.rotate(:right)
    when 'space'
      current_screen.fire_bullet
    end
  end
end

on :key_up do |event|
  case current_screen
  when GameScreen
    case event.key
    when 'down', 'up'
      current_screen.halt
    end
  end
end

show
