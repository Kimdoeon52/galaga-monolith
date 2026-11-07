-- main.lua
-- 편대 슈팅 모놀리식 (MVC 과정 2주차). 의도적 안티패턴: 전부 이 파일 하나에 넣는다.

local ship
local shots = {}
local SHIP_SPEED = 340
local SHOT_SPEED = 540

function love.load()
  love.graphics.setBackgroundColor(0.03, 0.02, 0.08)
  ship = { x = 280, y = 730, w = 40, h = 24, reload = 0 }
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

  -- 발사: 입력 해석과 총알 생성이 한 곳에 붙어 있다.
  ship.reload = ship.reload - dt
  if love.keyboard.isDown("space") and ship.reload <= 0 then
    shots[#shots + 1] = { x = ship.x + ship.w * 0.5 - 2, y = ship.y, w = 4, h = 12 }
    ship.reload = 0.25
  end

  for i = #shots, 1, -1 do
    local s = shots[i]
    s.y = s.y - SHOT_SPEED * dt
    if s.y + s.h < 0 then
      table.remove(shots, i)
    end
  end
end

function love.draw()
  love.graphics.setColor(0.4, 0.9, 1)
  love.graphics.rectangle("fill", ship.x, ship.y, ship.w, ship.h)

  love.graphics.setColor(1, 1, 0.3)
  for _, s in ipairs(shots) do
    love.graphics.rectangle("fill", s.x, s.y, s.w, s.h)
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end
