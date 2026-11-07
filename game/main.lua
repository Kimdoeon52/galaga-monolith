-- main.lua
-- 편대 슈팅 모놀리식 (MVC 과정 2주차). 의도적 안티패턴: 전부 이 파일 하나에 넣는다.

local ship
local SHIP_SPEED = 340

function love.load()
  love.graphics.setBackgroundColor(0.03, 0.02, 0.08)
  ship = { x = 280, y = 730, w = 40, h = 24 }
end

function love.update(dt)
  if love.keyboard.isDown("left") then
    ship.x = ship.x - SHIP_SPEED * dt
  end
  if love.keyboard.isDown("right") then
    ship.x = ship.x + SHIP_SPEED * dt
  end
  if ship.x < 0 then
    ship.x = 0
  elseif ship.x > 600 - ship.w then
    ship.x = 600 - ship.w
  end
end

function love.draw()
  love.graphics.setColor(0.4, 0.9, 1)
  love.graphics.rectangle("fill", ship.x, ship.y, ship.w, ship.h)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end
