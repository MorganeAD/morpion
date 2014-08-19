function love.load()
    love.graphics.setNewFont("font.ttf", 35)
    cross = love.graphics.newImage( "cross.png" )
    rond = love.graphics.newImage( "rond.png" )
    grid = love.graphics.newImage( "grid.png" )
    background = love.graphics.newImage( "bg.png" )

    socket = require "socket"
    address, port = "localhost", 12345
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername(address, port)

    WIDTH = love.graphics.getWidth()
    HEIGHT = love.graphics.getHeight()

    t = 0
    screen = 1

    user = {}
    user_color = 0
    user_pseudo = ""
    user_turn = 0

    used_color = 0

    messages = {}
    
    tapped_text = ""
    ask_user = "What's your pseudo?"

    board = {
        {0,0,0},
        {0,0,0},
        {0,0,0},
    }
end


function love.update(deltatime)
    -- erase string in the tapped text when the user use backspace
    if love.keyboard.isDown('backspace') and love.timer.getTime() > t + 0.3 then
        t = love.timer.getTime()
        if string.len(tapped_text) > 0 then
            tapped_text = string.sub(tapped_text, 1, -2)
        end
    end

    -- screen to ask user's user_pseudo
    if screen == 1 then 
        -- the user propose to the server a pseudo
        if love.keyboard.isDown('return') and love.timer.getTime() > t + 0.3 then
        t = love.timer.getTime()
            user_pseudo = tapped_text
            udp:send(string.format("%s %s ", user_pseudo, 'loggin'))
            tapped_text = ""
        end

        repeat
            data, msg = udp:receive()
            if data then
                pseudo, action, user_color_string = data:match("^(%S*) (%S*) (.*)$")
                if action == 'yes' then -- the proposed pseudo is available
                    user_color = tonumber(user_color_string)
                    if user_color == 2 then -- if the user is the 2nd players, go directly to the game screen
                        ask_user = ""
                        screen = 3
                    else -- if isn't, have to wait
                        ask_user = "Wait for the other player please"
                        screen = 2
                    end
                elseif action == 'no' then -- the proposed pseudo is unavailable
                    ask_user = 'Pseudo already taken, choose another one:'
                end
            end
        until not data
    end

    -- the game screen
    if screen == 2 or screen == 3 then 
        -- the user said something and send it to the server
        if love.keyboard.isDown('return') and love.timer.getTime() > t + 0.3 then
            t = love.timer.getTime()
            udp:send(string.format("%s %s %s %s", user_pseudo, 'says', user_color, tapped_text))
            tapped_text = ""
        end

        -- the user played 
        if love.mouse.isDown("l") and user_turn == 1 and love.timer.getTime() > t + 0.3 then
            t = love.timer.getTime()
            local m_x, m_y = love.mouse.getX(), love.mouse.getY() -- get the mouse's positions
            if m_x > 400 and m_x < 700 and m_y > 100 and m_y < 400 and user_turn == 1 then
                for i=1, 3 do
                    if m_y > i*100 and m_y < (i+1)*100 then
                        for j=1, 3 do
                            if m_x > (j+3)*100 and m_x < (j+4)*100 then -- checks where the user clics and send it to the server
                                if board[j][i] == 0 then
                                    udp:send(string.format("%s %s %s %s %s", user_pseudo, 'plays', user_color, j, i))
                                end
                            end
                        end
                    end
                end
            end
        end

        -- if the server send something to the user
        repeat
            data, msg = udp:receive()
            if data then 
                pseudo, action, parameter = data:match("^(%S*) (%S*) (.*)$")
                if action == 'start' then -- there is a 2nd player so go to the game screen
                    screen = 3
                    user_turn = 1 -- the 1st player begins
                    ask_user = ""
                elseif action == 'says' then -- someone have said something
                    used_color, message = parameter:match("(%d*) (.*)$")
                    table.insert(messages, pseudo .. " " .. used_color .. " " .. message)
                elseif action == 'plays' then -- someone have played something
                    used_color, column_played, line_played = parameter:match("(%d*) (%d*) (%d*)$")
                    used_color, column_played, line_played = tonumber(used_color), tonumber(column_played), tonumber(line_played)
                    board[column_played][line_played] = used_color
                    if  user_color == used_color then
                        user_turn = 0
                    else 
                        user_turn = 1
                    end
                    -- for i, column in pairs(board) do
                    --     for j, cell in pairs(column) do
                    --         print(cell)
                    --     end
                    -- end
                elseif action == 'wins' then -- someone wins
                    used_color = tonumber(parameter)
                    if user_color == used_color then
                        ask_user = 'You win !'
                    elseif used_color == 0 then
                        ask_user = 'Draw Game'
                    else
                        ask_user = 'You loose...'
                    end
                else
                    print("unrecognised command: ", data)
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
        love.graphics.printf(tapped_text, 0, HEIGHT/2, WIDTH, 'center')
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(ask_user, 0, HEIGHT/3, WIDTH, 'center')
    elseif screen == 2 or screen == 3 then
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(background,0,0,0)
        love.graphics.setColor(0,15,85)
        love.graphics.printf(tapped_text, 150, 24*30, WIDTH-150, 'left')
        for k, v in pairs(messages) do
            pseudo, used_color, message = v:match("(%S*) (%d*) (.*)$")
            used_color = tonumber(used_color)
            if used_color == 1 then
                love.graphics.setColor(0,15,85)
            elseif used_color == 2 then
                love.graphics.setColor(198,17,0)
            end
            love.graphics.printf(pseudo .. " : ", 0, 14*30+(k*30), 140, 'right')
            love.graphics.printf(message, 150, 14*30+(k*30), WIDTH, 'left')
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
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(ask_user, 0, 30, WIDTH, 'center')
        elseif screen == 2 then
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(ask_user, 0, 5*30, WIDTH, 'center')
        end
    end
end

function love.textinput(t)
    -- if screen == 1 then
    tapped_text = tapped_text .. t
end

function love.quit()
    udp:send(string.format("%s %s ", user_pseudo, 'quits'))
end
