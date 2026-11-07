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
local boss = nil
local bossDefeated = false
local bossFireTimer = 0
local bossPattern = 0
local SHIP_SPEED = 340
local SHOT_SPEED = 540
local ALIEN_SHOT_SPEED = 240
local BOSS_SCORE = 2000
local BOSS_HP = 40
local BOSS_SPEED = 90
local BOSS_SHOT_SPEED = 200
local MISSILE_SPEED = 320
local MISSILE_TURN = 6 -- 초당 최대 선회각(rad)
local MISSILE_RELOAD = 1
local MISSILE_LIFE = 4

local function hit(a, b)
  return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

-- 유도 목표 탐색. 일반 적과 보스를 둘 다 알아야 한다.
local function nearestTarget(x, y)
  local best, bestDist = nil, math.huge
  for _, a in ipairs(aliens) do
    local dx, dy = a.x + a.w * 0.5 - x, a.y + a.h * 0.5 - y
    local dist = dx * dx + dy * dy
    if dist < bestDist then
      best, bestDist = a, dist
    end
  end
  if boss then
    local dx, dy = boss.x + boss.w * 0.5 - x, boss.y + boss.h * 0.5 - y
    if dx * dx + dy * dy < bestDist then
      best = boss
    end
  end
  return best
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

-- 보스 탄막. 적 총알 목록에 그대로 넣기 위해 적 총알에 vx/vy 가 필요해졌다.
local function fireBossPattern()
  local cx, cy = boss.x + boss.w * 0.5, boss.y + boss.h
  bossPattern = bossPattern + 1
  if bossPattern % 2 == 1 then
    -- 원형 16발
    for i = 1, 16 do
      local angle = (i / 16) * math.pi * 2
      alienShots[#alienShots + 1] = {
        x = cx,
        y = cy,
        w = 6,
        h = 6,
        vx = math.cos(angle) * BOSS_SHOT_SPEED,
        vy = math.sin(angle) * BOSS_SHOT_SPEED,
      }
    end
  else
    -- 플레이어를 조준한 부채꼴 7발
    local aim = math.atan2(ship.y - cy, ship.x + ship.w * 0.5 - cx)
    for i = -3, 3 do
      local angle = aim + i * math.rad(12)
      alienShots[#alienShots + 1] = {
        x = cx,
        y = cy,
        w = 6,
        h = 6,
        vx = math.cos(angle) * BOSS_SHOT_SPEED * 1.3,
        vy = math.sin(angle) * BOSS_SHOT_SPEED * 1.3,
      }
    end
  end
end

-- 상태 변수가 늘 때마다 여기도 같이 고쳐야 한다.
local function resetGame()
  ship = { x = 280, y = 730, w = 40, h = 24, reload = 0, missileReload = 0 }
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
  boss = nil
  bossDefeated = false
  bossFireTimer = 0
  bossPattern = 0
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

  -- 유도 미사일 발사: 새 키와 쿨다운이 입력 블록에 하나 더 붙는다.
  ship.missileReload = ship.missileReload - dt
  if love.keyboard.isDown("x") and ship.missileReload <= 0 then
    shots[#shots + 1] = {
      x = ship.x + ship.w * 0.5 - 3,
      y = ship.y,
      w = 6,
      h = 10,
      homing = true,
      angle = -math.pi * 0.5,
      life = MISSILE_LIFE,
    }
    ship.missileReload = MISSILE_RELOAD
  end

  for i = #shots, 1, -1 do
    local s = shots[i]
    if s.homing then
      -- 일반 총알 이동 루프 안에 유도 분기가 끼어든다.
      local target = nearestTarget(s.x, s.y)
      if target then
        local want = math.atan2(target.y + target.h * 0.5 - s.y, target.x + target.w * 0.5 - s.x)
        local diff = (want - s.angle + math.pi) % (math.pi * 2) - math.pi
        local maxTurn = MISSILE_TURN * dt
        s.angle = s.angle + math.max(-maxTurn, math.min(maxTurn, diff))
      end
      s.x = s.x + math.cos(s.angle) * MISSILE_SPEED * dt
      s.y = s.y + math.sin(s.angle) * MISSILE_SPEED * dt
      s.life = s.life - dt
      if s.life <= 0 or s.y + s.h < 0 or s.y > 800 or s.x + s.w < 0 or s.x > 600 then
        table.remove(shots, i)
      end
    else
      s.y = s.y - SHOT_SPEED * dt
      if s.y + s.h < 0 then
        table.remove(shots, i)
      end
    end
  end

  -- 보스 등장: 점수 조건이 편대 로직을 지운다.
  if score >= BOSS_SCORE and not boss and not bossDefeated then
    boss = { x = 240, y = 70, w = 120, h = 60, hp = BOSS_HP, dir = 1 }
    aliens = {}
    bossFireTimer = 1
  end

  -- 보스 이동 + 발사
  if boss then
    boss.x = boss.x + boss.dir * BOSS_SPEED * dt
    if boss.x < 0 then
      boss.x = 0
      boss.dir = 1
    elseif boss.x > 600 - boss.w then
      boss.x = 600 - boss.w
      boss.dir = -1
    end
    bossFireTimer = bossFireTimer - dt
    if bossFireTimer <= 0 then
      bossFireTimer = 1.4
      fireBossPattern()
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
    alienShots[#alienShots + 1] = {
      x = a.x + a.w * 0.5 - 2,
      y = a.y + a.h,
      w = 4,
      h = 12,
      vx = 0,
      vy = ALIEN_SHOT_SPEED,
    }
  end

  for i = #alienShots, 1, -1 do
    local s = alienShots[i]
    s.x = s.x + s.vx * dt
    s.y = s.y + s.vy * dt
    if s.y > 800 or s.y + s.h < 0 or s.x + s.w < 0 or s.x > 600 then
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

  -- 충돌: 내 총알 x 보스. 일반 적 루프를 못 쓰고 HP 규칙용 루프가 하나 더 생긴다.
  if boss then
    for si = #shots, 1, -1 do
      if hit(shots[si], boss) then
        table.remove(shots, si)
        boss.hp = boss.hp - 1
        flashTime = 0.03
        if boss.hp <= 0 then
          explode(boss.x + boss.w * 0.25, boss.y + boss.h * 0.5)
          explode(boss.x + boss.w * 0.75, boss.y + boss.h * 0.5)
          shakeTime = 0.5
          score = score + 3000
          boss = nil
          bossDefeated = true
          break
        end
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

  -- 전멸하면 다음 편대 (보스전 중에는 나오면 안 된다)
  if #aliens == 0 and not boss then
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

  for _, s in ipairs(shots) do
    if s.homing then
      love.graphics.setColor(0.4, 1, 0.6)
    else
      love.graphics.setColor(1, 1, 0.3)
    end
    love.graphics.rectangle("fill", s.x, s.y, s.w, s.h)
  end

  love.graphics.setColor(1, 0.4, 0.4)
  for _, a in ipairs(aliens) do
    love.graphics.rectangle("fill", a.x, a.y, a.w, a.h)
  end

  if boss then
    love.graphics.setColor(0.9, 0.3, 1)
    love.graphics.rectangle("fill", boss.x, boss.y, boss.w, boss.h)
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
  if boss then
    love.graphics.setColor(0.3, 0.1, 0.35)
    love.graphics.rectangle("fill", 150, 36, 300, 10)
    love.graphics.setColor(0.9, 0.3, 1)
    love.graphics.rectangle("fill", 150, 36, 300 * boss.hp / BOSS_HP, 10)
    love.graphics.setColor(1, 1, 1)
  end
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
