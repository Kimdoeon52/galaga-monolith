-- main.lua
-- 편대 슈팅 모놀리식 (MVC 과정 2주차). 의도적 안티패턴: 전부 이 파일 하나에 넣는다.

local ship
local shots = {}
local aliens = {}
local alienShots = {}
local swayDir = 1
local alienFireTimer = 0
local score = 0
local lives = 3
local gameOver = false
local sparks = {} -- 순수 연출 데이터인데 게임 상태와 같이 산다
local flashTime = 0
local shakeTime = 0
local SHIP_SPEED = 340
local SHOT_SPEED = 540
local ALIEN_SHOT_SPEED = 240

local function hit(a, b)
  return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

-- 적이 죽을 때 보이는 것. 충돌 판정 한복판에서 직접 호출된다.
local function explode(x, y)
  for _ = 1, 12 do
    local angle = math.random() * math.pi * 2
    local speed = 40 + math.random() * 120
    sparks[#sparks + 1] = {
      x = x,
      y = y,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed,
      life = 0.5,
    }
  end
  flashTime = 0.06
end

local function spawnFormation()
  aliens = {}
  for row = 0, 3 do
    for col = 0, 7 do
      aliens[#aliens + 1] = { x = 60 + col * 60, y = 60 + row * 50, w = 36, h = 28 }
    end
  end
end

-- 상태 변수가 늘 때마다 여기도 같이 고쳐야 한다.
local function resetGame()
  ship = { x = 280, y = 730, w = 40, h = 24, reload = 0 }
  shots = {}
  alienShots = {}
  sparks = {}
  swayDir = 1
  alienFireTimer = 0
  score = 0
  lives = 3
  gameOver = false
  flashTime = 0
  shakeTime = 0
  spawnFormation()
end

function love.load()
  love.graphics.setBackgroundColor(0.03, 0.02, 0.08)
  math.randomseed(os.time()) -- 매 실행 결과가 달라진다(비결정적)
  resetGame()
end

function love.update(dt)
  flashTime = flashTime - dt
  shakeTime = shakeTime - dt

  if gameOver then
    return
  end

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

  -- 충돌: 내 총알 x 적
  for si = #shots, 1, -1 do
    for ai = #aliens, 1, -1 do
      if hit(shots[si], aliens[ai]) then
        explode(aliens[ai].x + aliens[ai].w * 0.5, aliens[ai].y + aliens[ai].h * 0.5)
        table.remove(aliens, ai)
        table.remove(shots, si)
        score = score + 100
        break
      end
    end
  end

  -- 충돌: 적 총알 x 플레이어
  for i = #alienShots, 1, -1 do
    if hit(alienShots[i], ship) then
      table.remove(alienShots, i)
      lives = lives - 1
      shakeTime = 0.3 -- 규칙 처리 중에 연출 상태를 직접 건드린다
      if lives <= 0 then
        gameOver = true
      end
    end
  end

  -- 편대가 플레이어 높이까지 내려오면 끝
  for _, a in ipairs(aliens) do
    if a.y + a.h >= ship.y then
      gameOver = true
    end
  end

  -- 전멸하면 다음 편대
  if #aliens == 0 then
    spawnFormation()
  end

  -- 파티클도 게임 로직과 같은 루프에서 돈다
  for i = #sparks, 1, -1 do
    local p = sparks[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    if p.life <= 0 then
      table.remove(sparks, i)
    end
  end
end

function love.draw()
  love.graphics.push()
  if shakeTime > 0 then
    love.graphics.translate((math.random() - 0.5) * 10, (math.random() - 0.5) * 10)
  end

  if flashTime > 0 then
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("fill", 0, 0, 600, 800)
  end

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

  love.graphics.setColor(1, 0.8, 0.2)
  for _, p in ipairs(sparks) do
    love.graphics.rectangle("fill", p.x, p.y, 3, 3)
  end

  love.graphics.pop()

  love.graphics.setColor(1, 1, 1)
  love.graphics.print("SCORE " .. score, 10, 10)
  love.graphics.print("LIVES " .. lives, 520, 10)
  if gameOver then
    love.graphics.printf("GAME OVER\nPress R", 0, 380, 600, "center")
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  elseif key == "r" and gameOver then
    resetGame()
  end
end
