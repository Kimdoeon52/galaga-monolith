-- main.lua
-- 편대 슈팅 모놀리식 (MVC 과정 2주차). 의도적 안티패턴: 전부 이 파일 하나에 넣는다.

local ship
local shots = {}
local aliens = {}
local alienShots = {}
local swayDir = 1
local alienFireTimer = 0
local SHIP_SPEED = 340
local SHOT_SPEED = 540
local ALIEN_SHOT_SPEED = 240

local function spawnFormation()
  aliens = {}
  for row = 0, 3 do
    for col = 0, 7 do
      aliens[#aliens + 1] = { x = 60 + col * 60, y = 60 + row * 50, w = 36, h = 28 }
    end
  end
end

function love.load()
  love.graphics.setBackgroundColor(0.03, 0.02, 0.08)
  math.randomseed(os.time()) -- 매 실행 결과가 달라진다(비결정적)
  ship = { x = 280, y = 730, w = 40, h = 24, reload = 0 }
  spawnFormation()
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

  -- 편대 이동: 끝에 닿을 것 같으면 방향을 바꾸고 한 칸 내려온다.
  local minx, maxx = math.huge, -math.huge
  for _, a in ipairs(aliens) do
    minx = math.min(minx, a.x)
    maxx = math.max(maxx, a.x + a.w)
  end
  local dx = swayDir * 40 * dt
  if maxx + dx > 590 or minx + dx < 10 then
    swayDir = -swayDir
    for _, a in ipairs(aliens) do
      a.y = a.y + 16
    end
  else
    for _, a in ipairs(aliens) do
      a.x = a.x + dx
    end
  end

  -- 적 발사: 아무 적이나 골라 아래로 쏜다.
  alienFireTimer = alienFireTimer - dt
  if alienFireTimer <= 0 and #aliens > 0 then
    alienFireTimer = 0.6
    local a = aliens[math.random(#aliens)]
    alienShots[#alienShots + 1] = { x = a.x + a.w * 0.5 - 2, y = a.y + a.h, w = 4, h = 12 }
  end

  for i = #alienShots, 1, -1 do
    local s = alienShots[i]
    s.y = s.y + ALIEN_SHOT_SPEED * dt
    if s.y > 800 then
      table.remove(alienShots, i)
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

  love.graphics.setColor(1, 0.4, 0.4)
  for _, a in ipairs(aliens) do
    love.graphics.rectangle("fill", a.x, a.y, a.w, a.h)
  end

  love.graphics.setColor(1, 0.6, 0.2)
  for _, s in ipairs(alienShots) do
    love.graphics.rectangle("fill", s.x, s.y, s.w, s.h)
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end
