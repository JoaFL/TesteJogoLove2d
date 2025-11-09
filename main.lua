---@diagnostic disable: undefined-global

-- Const da velocidade de movimento
local MOVEMENT_SPEED = 6000

-- Inicia/prepara o jogo 
function love.load()
    wf = require('libraries.windfield')
    world = wf.newWorld(0, 0)

    camera = require('libraries.camera') -- module que facilita a criação da câmera
    cam = camera()

    anim8 = require('libraries.anim8') -- module que facilita a criação de animações
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require('libraries.sti') -- module que facilita a criação de tileMaps
    gameMap = sti('maps/testMap.lua')

    -- Criando o player
    player = {
        x = 400,
        y = 200
    }
    
    player.colision = world:newBSGRectangleCollider(player.x, player.y, 50, 100, 10)
    player.colision:setFixedRotation(true)

    -- sprites
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    -- animação
    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.2)
    player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.2)
    player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.2)
    player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.2)
    player.anim = player.animations.left

    sounds = {}
    sounds.blip = love.audio.newSource("sounds/blip.wav", "static")
    sounds.music = love.audio.newSource("sounds/music.mp3", "stream")
    sounds.music:setLooping(true)

    sounds.music:play()
    
    walls = {}
    if gameMap.layers["Walls"] then
        for i, v in pairs(gameMap.layers["Walls"].objects) do
            local wall = world:newRectangleCollider(v.x, v.y, v.width, v.height)
            wall:setType('static')

            table.insert(walls, wall)
        end
    end
    
    --love.window.setMode(bgWidth, bgHeight)
end

-- Atualiza a lógica do jogo a cada frame
function love.update(dt) -- dt = delta time, tempo decorrido entre frames

    -- Faz o player não sair da tela
    --[[player.x = math.max(0, math.min(player.x, love.graphics.getWidth()))
    player.y = math.max(0, math.min(player.y, love.graphics.getHeight()))]]

    local isMoving = false -- auto explicativo

    local vx = 0
    local vy = 0

    if love.keyboard.isDown("right") then
        vx = (dt * MOVEMENT_SPEED)
        player.anim = player.animations.right -- muda a animação
        isMoving = true
    elseif love.keyboard.isDown("left") then
        vx = (dt * MOVEMENT_SPEED) * -1
        player.anim = player.animations.left
        isMoving = true
    end

    if love.keyboard.isDown("up") then
        vy = (dt * MOVEMENT_SPEED) * -1
        player.anim = player.animations.up
        isMoving = true
    elseif love.keyboard.isDown("down") then
        vy = (dt * MOVEMENT_SPEED)
        player.anim = player.animations.down
        isMoving = true
    end

    player.colision:setLinearVelocity(vx, vy)

    world:update(dt)
    player.x = player.colision:getX()
    player.y = player.colision:getY()
    
    -- se não estiver movendo, vai para o frame 2 de todas as anims (sprite parado)
    if not isMoving then
        player.anim:gotoFrame(2)
    end

    -- Atualiza a animação
    player.anim:update(dt)

    -- Local onde a câmera ira olhar
    cam:lookAt(player.x, player.y)

    -- Limitar a posição da câmera para o background
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    if cam.x < w/2 then
        cam.x = w/2
    end

    if cam.y < h/2 then
        cam.y = h/2
    end

    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight
    if cam.x > (mapW - w/2) then
        cam.x = (mapW - w/2)
    end

    if cam.y > (mapH - h/2) then
        cam.y = (mapH - h/2)
    end
end

-- Desenha os elementos da tela a cada frame
function love.draw()
    cam:attach() -- desenha na perspectiva da câmera
        gameMap:drawLayer(gameMap.layers["Camada de Blocos 1"])

        -- Desenha o player com animação
        player.anim:draw(player.spriteSheet, player.x, player.y, 0, 6, nil, 6, 9)

        gameMap:drawLayer(gameMap.layers["Camada de Blocos 2"])
        
        --world:draw()
    cam:detach()

    love.graphics.print("FPS: " .. love.timer.getFPS(), 5, 30)
    love.graphics.print("X: " .. math.floor(player.x) .. " Y: " .. math.floor(player.y), 5, 10)
end

function love.keypressed(key)
    if key == 'space' then
        sounds.blip:play()
    end

    if key == 'r' then
        love.event.quit('restart')
    end
end