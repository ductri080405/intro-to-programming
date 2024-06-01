require 'ruby2d'

set title: 'Battle Of The Ships'
set width: 1200
set height: 700

# Constants
PLAYER_WIDTH = 96
PLAYER_HEIGHT = 138
BULLET_WIDTH = 18
BULLET_HEIGHT = 15
BULLET_SPEED = 10
ROTATION_SPEED = 3
VELOCITY_SPEED = 0.1
MAX_SPEED = 10
MAX_ASTEROID = 6
ASTEROID_WIDTH = 58
ASTEROID_HEIGHT = 61

# Global variables
$current_screen = nil
$asteroids = []
$last_asteroid_time = Time.now
$background_music = nil

def animate_players(players, selected_player)
  i = 0
  while i < players.length
    if i == selected_player
      players[i].sprite.play(animation: :move_fast, loop: true)
    else
      players[i].sprite.play(animation: :move_slow, loop: true)
    end
    i += 1
  end
end

def player_stat_text(players, selected_player_index, speed_texts, fire_rate_texts)
  i = 0
  while i < players.length
    if i == selected_player_index
      speed_texts[i].color = Color.new([1, 1, 1, 1])
      fire_rate_texts[i].color = Color.new([1, 1, 1, 1])
    else
      speed_texts[i].color = Color.new([1, 1, 1, 0])
      fire_rate_texts[i].color = Color.new([1, 1, 1, 0])
    end
    speed_texts[i].text = "Speed - #{players[i].speed}%"
    speed_texts[i].x = players[i].sprite.x + (PLAYER_WIDTH - speed_texts[i].width) / 2
    fire_rate_texts[i].text = "Fire Rate - #{players[i].fire_rate}%"
    fire_rate_texts[i].x = players[i].sprite.x + (PLAYER_WIDTH - fire_rate_texts[i].width) / 2
    i += 1
  end
end

class Player
  attr_accessor :sprite, :x_velocity, :y_velocity, :speed, :fire_rate, :last_fired_frame, :bullets

  def initialize(image, x, y, speed, fire_rate)
    @sprite = Sprite.new(
      image,
      clip_width: 32,
      width: PLAYER_WIDTH,
      height: PLAYER_HEIGHT,
      x: x,
      y: y,
      rotate: 0,
      animations: {
        move_slow: 1..2,
        move_fast: 3..4
      }
    )
    @x_velocity = 0
    @y_velocity = 0
    @speed = speed
    @fire_rate = fire_rate
    @last_fired_frame = 0
    @bullets = []
  end
end

class Bullet
  attr_accessor :image, :x_velocity, :y_velocity

  def initialize(x, y, rotate)
    @image = Sprite.new('bullet.png', width: BULLET_WIDTH, height: BULLET_HEIGHT, x: x, y: y, rotate: rotate)
    Sound.new('laser.mp3').play
    @x_velocity = Math.sin(rotate * Math::PI / 180) * BULLET_SPEED
    @y_velocity = -Math.cos(rotate * Math::PI / 180) * BULLET_SPEED
  end
end

class Asteroid
  attr_accessor :sprite

  def initialize
    @sprite = Sprite.new('asteroid.png', x: rand(Window.width), y: rand(Window.height), width: ASTEROID_WIDTH, height: ASTEROID_HEIGHT, clip_width: 58, clip_height: 61, rotate: rand(360))
  end
end

class PlayerSelectScreen
  attr_accessor :selected_player_index, :players, :speed_texts, :fire_rate_texts
  def initialize
    @title_text = Text.new('BATTLE OF THE SHIPS', size: 70, y: 40)
    @title_text.x = (Window.width - @title_text.width) / 2

    @player_select_text = Text.new('SELECT YOUR SHIP', size: 30, y: 120)
    @player_select_text.x = (Window.width - @player_select_text.width) / 2

    @players = [
      Player.new('ship_1.png', Window.width * (1 / 4.0) - PLAYER_WIDTH / 2, 240, 80, 80),
      Player.new('ship_2.png', Window.width * (2 / 4.0) - PLAYER_WIDTH / 2, 240, 60, 90),
      Player.new('ship_3.png', Window.width * (3 / 4.0) - PLAYER_WIDTH / 2, 240, 90, 60)
    ]

    @selected_player_index = 1
    @speed_texts = []
    @fire_rate_texts = []
    i = 0
    while i < @players.length
      player = @players[i]
      @speed_texts << Text.new("Speed - #{player.speed}%", size: 20, x: player.sprite.x, y: player.sprite.y + 200, color: Color.new([1, 1, 1, 0]))
      @fire_rate_texts << Text.new("Fire Rate - #{player.fire_rate}%", size: 20, x: player.sprite.x, y: player.sprite.y + 230, color: Color.new([1, 1, 1, 0]))
      i += 1
    end
    animate_players(@players, @selected_player_index)
    player_stat_text(@players, @selected_player_index, @speed_texts, @fire_rate_texts)
  end

end

def change_player_select(direction, player_select_screen)
  if direction == "left"
    player_select_screen.selected_player_index = (player_select_screen.selected_player_index - 1) % player_select_screen.players.length
  elsif direction == "right"
    player_select_screen.selected_player_index = (player_select_screen.selected_player_index + 1) % player_select_screen.players.length
  end
  animate_players(player_select_screen.players, player_select_screen.selected_player_index)
  player_stat_text(player_select_screen.players, player_select_screen.selected_player_index, player_select_screen.speed_texts, player_select_screen.fire_rate_texts)
end

class GameScreen
  def initialize(player)
    $background_music = Sound.new('mario.mp3')
    $background_music.loop = true
    $background_music.play

    @player = Player.new(player.sprite.path, Window.width / 2, Window.height / 2, player.speed, player.fire_rate)
    @player.sprite.play(animation: :move_slow, loop: true)
    $asteroids = []
    $last_asteroid_time = Time.now
  end

end

# Initial screen setup
$current_screen = PlayerSelectScreen.new

def move_player(player)
  player.sprite.x += player.x_velocity
  player.sprite.y += player.y_velocity

  if player.sprite.x > Window.width + PLAYER_WIDTH
    player.sprite.x = -PLAYER_WIDTH
  elsif player.sprite.x < -PLAYER_WIDTH
    player.sprite.x = Window.width + PLAYER_WIDTH
  end

  if player.sprite.y > Window.height + PLAYER_HEIGHT
    player.sprite.y = -PLAYER_HEIGHT
  elsif player.sprite.y < -PLAYER_HEIGHT
    player.sprite.y = Window.height + PLAYER_HEIGHT
  end

  i = 0
  while i < player.bullets.length
    bullet = player.bullets[i]
    bullet.image.x += bullet.x_velocity
    bullet.image.y += bullet.y_velocity

    if bullet.image.x < -BULLET_WIDTH || bullet.image.x > Window.width || bullet.image.y < -BULLET_HEIGHT || bullet.image.y > Window.height
      bullet.image.remove
      player.bullets.delete_at(i)
    else
      i += 1
    end
  end
end

def update_player(player, direction)
  angle_rad = player.sprite.rotate * Math::PI / 180
  player.sprite.play(animation: :move_fast, loop: true)

  if direction == "forward"
    player.x_velocity += Math.sin(angle_rad) * VELOCITY_SPEED * player.speed / 100.0
    player.y_velocity -= Math.cos(angle_rad) * VELOCITY_SPEED * player.speed / 100.0
  elsif direction == "backward"
    player.x_velocity -= Math.sin(angle_rad) * VELOCITY_SPEED * player.speed / 100.0
    player.y_velocity += Math.cos(angle_rad) * VELOCITY_SPEED * player.speed / 100.0
  end

  total = player.x_velocity.abs + player.y_velocity.abs
  if total > MAX_SPEED
    player.x_velocity *= MAX_SPEED / total
    player.y_velocity *= MAX_SPEED / total
  end
end

def fire_bullet(player)
  angle_rad = player.sprite.rotate * Math::PI / 180
  if player.last_fired_frame + 15 - (player.fire_rate / 10) < Window.frames
    x_component = Math.sin(angle_rad)
    y_component = -Math.cos(angle_rad)

    x = player.sprite.x + PLAYER_WIDTH * 0.5 + (x_component * PLAYER_WIDTH)
    y = player.sprite.y + PLAYER_HEIGHT * 0.5 + (y_component * PLAYER_HEIGHT)

    player.bullets << Bullet.new(x, y, player.sprite.rotate)
    player.last_fired_frame = Window.frames
  end
end



def check_collisions(player, asteroids)
  i = 0
  while i < player.bullets.length
    bullet = player.bullets[i]
    j = 0
    while j < asteroids.length
      asteroid = asteroids[j]
      if check_collision(bullet, asteroid)
        bullet.image.remove
        asteroid.sprite.remove
        player.bullets.delete_at(i)
        asteroids.delete_at(j)
        break
      end
      j += 1
    end
    i += 1
  end
end

def check_collision(bullet, asteroid)

  bullet_x1 = bullet.image.x
  bullet_y1 = bullet.image.y
  bullet_x2 =  bullet.image.x + BULLET_WIDTH
  bullet_y2 = bullet.image.y + BULLET_HEIGHT

  asteroid_x1 = asteroid.sprite.x
  asteroid_y1 = asteroid.sprite.y
  asteroid_x2 = asteroid.sprite.x + ASTEROID_WIDTH
  asteroid_y2 = asteroid.sprite.y + ASTEROID_HEIGHT

  !(bullet_x2 < asteroid_x1 || bullet_x1 > asteroid_x2 || bullet_y2 < asteroid_y1 || bullet_y1 > asteroid_y2)
end

update do
  if $current_screen.is_a?(GameScreen)
    player = $current_screen.instance_variable_get(:@player)
    move_player(player)

    if Time.now - $last_asteroid_time >= 2 && $asteroids.length < MAX_ASTEROID
      $asteroids << Asteroid.new
      $last_asteroid_time = Time.now
    end

    check_collisions(player, $asteroids)
  end
end

on :key_down do |event|
  if $current_screen.is_a?(PlayerSelectScreen)
    if event.key == "return"
      Window.clear
      $current_screen = GameScreen.new($current_screen.players[$current_screen.selected_player_index])
    elsif event.key == "right" or event.key == "left"
      change_player_select(event.key, $current_screen)
    end
  elsif $current_screen.is_a?(GameScreen)
    if event.key == "escape"
      $background_music.stop
      Window.clear
      $current_screen = PlayerSelectScreen.new
    end
  end
end

on :key_held do |event|
  if $current_screen.is_a?(GameScreen)
    player = $current_screen.instance_variable_get(:@player)
    if event.key == "up"
      update_player(player, "forward")
    elsif event.key == "down"
      update_player(player, "backward")
    elsif event.key == "left"
      player.sprite.rotate -= ROTATION_SPEED
    elsif event.key == "right"
      player.sprite.rotate += ROTATION_SPEED
    elsif event.key == "space"
      fire_bullet(player)
    end
  end
end

on :key_up do |event|
  if $current_screen.is_a?(GameScreen)
    player = $current_screen.instance_variable_get(:@player)
    if event.key == "down" || event.key == "up"
      player.sprite.play(animation: :move_slow, loop: true)
    end
  end
end

show
