push = require 'push'

Class = require 'class'

require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest') -- deixa o jogo com aparencia retro sem ficar embaçado

    love.window.setTitle('Ping Pong') -- titulo do jogo

    math.randomseed(os.time()) -- aleatorizar numeros numa escala de 00:00:00 que muda o tempo todo

    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)

    love.graphics.setFont(smallFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'), -- som e tipo do som
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static') -- quando bate em cima ou embaixo
    }

   push: setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        canvas = false
    })

    player1Score = 0
    player2Score = 0

    servingPlayer = 1 -- o jogador 1 começa 

    winningPlayer = 0


    player1 = Paddle(10, 30, 5, 20) -- coordenadas x e y de lugar e largura e altura
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- inicia com a bola no meio
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4) -- coordenadas x e y de lugar e largura e altura

    gameState = 'start'
end

function love.resize(w, h) -- função pra ajeitar o tamanho do jogo de acordo com a altura e largura do pc que abriu
    push:resize(w, h)
end

function love.update(dt)

    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200) -- se o jogador um serve a bola vai aleatoriemente pra direita
        else
            ball.dx = -math.random(140, 200) -- se for o jogador 2, vai para esquerda
        end



    elseif gameState == 'play' then

        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03 -- a bola bate na raquete do jogador 1, volta(dx negativo reverte a posiçao inicial) e acelera um pouco
            ball.x = player1.x + 5 -- altera a coordenada da bola depois de bater na raquete p/ n ficar colidindo (5 é largura da raquete)

            -- aleatorizar o movimento da bola p/ n ir pro mesmo canto
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150) 
            else
                ball.dy = math.random(10, 150)
            end
            sounds['paddle_hit']:play()
        end

        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4 -- negativo porque bate e volta pro lado esquerdo (4 é a largura da bola)

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
            sounds['paddle_hit']:play()
        end

        -- evitando que a bola passe da extremidade de cima e de baixo da tela
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy  -- bate e volta
            
            sounds['wall_hit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then -- 4 é a altura da bola
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy

            sounds['wall_hit']:play()
        end

        if ball.x < 0 then -- quando o jogador 2 faz ponto, o próximo a servir é jogador 1 que perdeu
            servingPlayer = 1
            player2Score = player2Score + 1

            sounds['score']:play()

            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1

            sounds['score']:play()

            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end



    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED -- chama a função de Paddle que sobe a raquete do jogador 1
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED -- chama a função que desce a raquete do jogador 1 
    else
        player1.dy = 0
    end

    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED -- mesma coisa para o jogador 2
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    if  gameState == 'play' then -- a bola começa a se mover a aleatoriamente quando da o play
        ball:update(dt)
    end
    player1:update(dt)
    player2:update(dt)
end


function love.keypressed(key)

    if key == 'escape' then
        love.event.quit()

    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
         elseif gameState == 'done' then
            
            gameState = 'serve'

            ball:reset()

            player1Score = 0
            player2Score = 0

            if winningPlayer == 1 then  -- se um ganhou o outro que começa
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

--[[
    Called after update by LÖVE2D, used to draw anything to the screen, updated or otherwise.
]]
function love.draw()

    push:apply('start')

    -- clear the screen with a specific color; in this case, a color similar
    -- to some versions of the original Pong
    love.graphics.clear(40/255, 45/255, 52/255, 255/255)

    love.graphics.setFont(smallFont)

    displayScore()

    if gameState == "start" then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Bem-vindo ao Ping Pong da Leca!', 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Aperte enter para jogar!', 0, 40, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Jogador ' .. tostring(servingPlayer) .. ' serve!', 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Aperte enter para servir!', 0, 40, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- nada
    elseif gameState == 'done' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Jogador ' .. tostring(winningPlayer) .. ' venceu!', 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Aperte enter para jogar de novo!', 0, 50, VIRTUAL_WIDTH, 'center')

    end


    player1:render()
    player2:render()
    ball:render()

    displayFPS() 

    
    push:apply('end')
end

function displayFPS() -- -- funçao pra mostrar (frame per second) - opcional
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0 , 255/255, 0, 255/255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(255, 255, 255, 255)
end

function displayScore()

    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)
end