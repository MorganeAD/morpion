function love.load()
    love.graphics.setNewFont("font.ttf", 35)

    socket = require "socket"
    address, port = "localhost", 12345

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
                local dg = string.format("%s %s %s", user_pseudo, 'says', text)
                udp:send(dg)
                text = ""
            end
            if m_x > 400 and m_x < 700 and m_y > 100 and m_y < 400 and turn == 1 then
                
                local dg = string.format("%s %s %s %s %s", user_pseudo, 'plays', user_color, m_x, m_y)
                udp:send(dg)
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
                    table.insert(messages, pseudo .. " : " .. message)
                -- elseif action == 'enters' then
                --     table.insert(users, pseudo)
                --     for k, v in pairs(users) do
                --         print(k, v)
                --     end
                --     print()
                elseif action == 'plays' then
                    color_played_string, m_x, m_y = message:match("(%d*) (%d*) (%d*)$")
                    color_played, m_x, m_y = tonumber(color_played_string), tonumber(m_x), tonumber(m_y)

                    if  user_color == color_played then
                        turn = 0
                    else 
                        turn = 1
                    end
print(color_played .. " " .. user_color  .. " " .. turn)
                    for i=1, 3 do
                        if m_y > i*100 and m_y < (i+1)*100 then
                            for j=1, 3 do
                                if m_x > (j+3)*100 and m_x < (j+4)*100 then
                                    if board[j][i] == 0 then
                                        board[j][i] = color_played
                                    end
                                end
                            end
                        end
                    end
                    m_x = 0
                    m_y = 0

                    -- for i, column in pairs(board) do
                    --     for j, cell in pairs(column) do
                    --         print(cell)
                    --     end
                    -- end

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
        love.graphics.printf(ask_user, 0, HEIGHT/3, WIDTH, 'center')
        love.graphics.printf(text, 0, HEIGHT/2, WIDTH, 'center')
    end

    
    if screen ~= 1 then
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(background,0,0,0)
        love.graphics.setColor(236, 240, 241)
        love.graphics.setColor(0,15,85)
        love.graphics.printf(text, 30, HEIGHT-100, WIDTH, 'left')
        for k, v in pairs(messages) do
            love.graphics.printf(v, 30, k*25, love.graphics.getWidth())
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
            love.graphics.printf('WAIT', 0, HEIGHT/3, WIDTH, 'center')
        end
    end
end

function love.textinput(t)
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


