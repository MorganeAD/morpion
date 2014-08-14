function love.load()
    love.graphics.setNewFont("font.ttf", 35)

    socket = require "socket"
    address, port = "kivutar.me", 12345

    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername(address, port)

    WIDTH = love.graphics.getWidth()
    HEIGHT = love.graphics.getHeight()

    t = 0
    updaterate = 0.2
    screen = 1
    user = {}
    cross = love.graphics.newImage( "cross.png" )
    rond = love.graphics.newImage( "rond.png" )
    grid = love.graphics.newImage( "grid.png" )
    background = love.graphics.newImage( "bg.png" )
    user_color = 0
    color_played = 0
    color = ""
    mes = ""


    messages = {}
    user_pseudo = ""
    text = ""
    ask_user = "What's your pseudo?"

    board = {
        {0,0,0},
        {0,0,0},
        {0,0,0},
    }
    turn = 0

    m_x = 0
    m_y = 0
end


function love.update(deltatime)
    t = t + deltatime
    if t > updaterate then
        if love.keyboard.isDown('backspace') then
            if string.len(text) > 0 then
                text = string.sub(text, 1, -2)
            end
            t=t-updaterate
        end
    end

    if screen == 1 then -- screen to ask user's user_pseudo
        if t > updaterate then
            if love.keyboard.isDown('return') then
                user_pseudo = text
                local dg = string.format("%s %s ", user_pseudo, 'loggin')
                udp:send(dg)
                text = ""
            end
            t=t-updaterate
        end

        repeat
        data, msg = udp:receive()
            if data then
                pseudo, action, user_color_string = data:match("^(%S*) (%S*) (.*)$")
                if action == 'yes' then
                    user_color = tonumber(user_color_string)
                    if user_color == 2 then
                        screen = 3
                    else
                        ask_user = "Wait the other player please"
                        screen = 2
                    end
                elseif action == 'no' then
                    ask_user = 'Pseudo already took, choose an other :'
                end
            end
        until not data
    end

    if screen ~= 1 then -- chat's screen
        -- the user send something to the server
        if t > updaterate then
            if love.keyboard.isDown('return') then
                local dg = string.format("%s %s %s %s", user_pseudo, 'says', user_color, text)
                udp:send(dg)
                text = ""
            end
            if m_x > 400 and m_x < 700 and m_y > 100 and m_y < 400 and turn == 1 then
                for i=1, 3 do
                    if m_y > i*100 and m_y < (i+1)*100 then
                        for j=1, 3 do
                            if m_x > (j+3)*100 and m_x < (j+4)*100 then
                                if board[j][i] == 0 then
                                    -- board[j][i] = color_played
                                    local dg = string.format("%s %s %s %s %s", user_pseudo, 'plays', user_color, j, i)
                                    udp:send(dg)
                                end
                            end
                        end
                    end
                end
                
                m_x = 0
                m_y = 0
            end
            t=t-updaterate -- set t for the next round
        end

        -- if the server send something to the user
        repeat
            data, msg = udp:receive()
            if data then 
                pseudo, action, message = data:match("^(%S*) (%S*) (.*)$")
                if action == 'start' then
                    screen = 3
                    turn = 1
                elseif action == 'says' then
                    color, mes = message:match("(%d*) (.*)$")
                    table.insert(messages, pseudo .. " " .. color .. " " .. mes)
                elseif action == 'plays' then
                    color_played, column_played, line_played = message:match("(%d*) (%d*) (%d*)$")
                    color_played, column_played, line_played = tonumber(color_played), tonumber(column_played), tonumber(line_played)
                    board[column_played][line_played] = color_played
                    if  user_color == color_played then
                        turn = 0
                    else 
                        turn = 1
                    end

                    m_x = 0
                    m_y = 0
                    if  (board[1][1] ~= 0 and board[1][1] == board[1][2] and board[1][1] == board[1][3]) or
                        (board[2][1] ~= 0 and board[2][1] == board[2][2] and board[2][1] == board[2][3]) or
                        (board[3][1] ~= 0 and board[3][1] == board[3][2] and board[3][1] == board[3][3]) or
                        (board[1][1] ~= 0 and board[1][1] == board[2][1] and board[1][1] == board[3][1]) or
                        (board[1][2] ~= 0 and board[1][2] == board[2][2] and board[1][2] == board[3][2]) or
                        (board[1][3] ~= 0 and board[1][3] == board[2][3] and board[1][3] == board[3][3]) or
                        (board[1][1] ~= 0 and board[1][1] == board[2][2] and board[1][1] == board[3][3]) or
                        (board[3][1] ~= 0 and board[3][1] == board[2][2] and board[3][1] == board[1][3]) then
                        print(color_played)
                        local dg = string.format("%s %s %s", pseudo, 'wins', color_played)
                        udp:send(dg)
                    end
                    if board[1][1] == board[1][2] == board[1][3] then
                        local dg = string.format("%s %s ", user_color, 'wins')
                        udp:send(dg)
                    end

                    -- for i, column in pairs(board) do
                    --     for j, cell in pairs(column) do
                    --         print(cell)
                    --     end
                    -- end
                elseif action == 'wins' then
                    color_played = tonumber(message)
                    if user_color == color_played then
                        ask_user = 'you win !'
                    else
                        ask_user = 'you loose...'
                    end
                    screen =2
                else
                    print("unrecognised command : ", data)
                end
            elseif msg ~= 'timeout' then
                error("Network error: "..tostring(msg))
            end
        until not data
    end
    if love.keyboard.isDown('escape') then 
        love.event.quit()
    end
end

function love.draw()
    if screen == 1 then
        love.graphics.setColor(150, 150, 150)
        love.graphics.draw(background,0,0,0)
        love.graphics.setColor(236, 240, 241)
        love.graphics.rectangle("fill", WIDTH/4, HEIGHT/4, WIDTH/2, HEIGHT/2 )
        love.graphics.setColor(0,15,85)
        love.graphics.printf(text, 0, HEIGHT/2, WIDTH, 'center')
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(ask_user, 0, HEIGHT/3, WIDTH, 'center')
    end

    
    if screen ~= 1 then
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(background,0,0,0)
        love.graphics.setColor(236, 240, 241)
        love.graphics.setColor(0,15,85)
        love.graphics.printf(text, 30, HEIGHT-52, WIDTH, 'left')
        for k, v in pairs(messages) do
            id, color_string, mes = v:match("(%S*) (%d*) (.*)$")
            color = tonumber(color_string)
            if color == 1 then
                love.graphics.setColor(0,15,85)
            elseif color == 2 then
                love.graphics.setColor(198,17,0)
            end
            love.graphics.printf(id .. " : ", 0, 404+(k*31), 140, 'right')
            love.graphics.printf(mes, 150, 404+(k*31), love.graphics.getWidth(), 'left')
        end
        if screen == 3 then
            love.graphics.setColor(255, 255, 255)
            love.graphics.draw(grid, 300, 0, 0)
            for i, column in pairs(board) do
                for j, cell in pairs(column) do
                    if board[i][j] == 1 then
                        love.graphics.draw(cross, 400+100*(i-1), 100+100*(j-1), 0)
                    elseif board[i][j] == 2 then
                        love.graphics.draw(rond, 400+100*(i-1), 100+100*(j-1), 0)
                    end
                end
            end
        elseif screen == 2 then
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(ask_user, 0, 215, WIDTH, 'center')
        end
    end
end

function love.textinput(t)
    -- if screen == 1 then
     text = text .. t
end

function love.mousepressed(x, y, button)
   if button == "l" then
      m_x = x
      m_y = y
   end
end

function love.quit()
    local dg = string.format("%s %s ", user_pseudo, 'quits')
    udp:send(dg)
end

