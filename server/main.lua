socket = require "socket"

udp = socket.udp()
udp:settimeout(0)
udp:setsockname('*', 12345)

users = {}
user_color = 0
local data, msg_or_ip, port_or_nil
local pseudo, action, message

board = {
    {0,0,0},
    {0,0,0},
    {0,0,0},
}
remaining_turns = 9
running = true

function size_of_array(array)
    local count = 0
    for _, _ in pairs(array) do
        count = count + 1
    end
    if (count % 2 == 0) then
        return 2
    else
        return 1
    end
end

print "Server launch"
while running do
    data, msg_or_ip, port_or_nil = udp:receivefrom()
    if data then
        pseudo, action, message = data:match("^(%S*) (%S*) (.*)")
        if action == 'loggin' then
            if users[pseudo] then
                udp:sendto(string.format("%s %s %s", pseudo, 'no', user_color), msg_or_ip,  port_or_nil)
            else
                users[pseudo] = {ip=msg_or_ip, port=port_or_nil}
                user_color = size_of_array(users)
                udp:sendto(string.format("%s %s %s", pseudo, 'yes', user_color), msg_or_ip,  port_or_nil)
                -- udp:sendto(string.format("%s %s %s", pseudo, 'enters', message), v.ip,  v.port)
                if user_color == 2 then
                    for k, v in pairs(users) do
                        udp:sendto(string.format("%s %s %s", pseudo, 'start', user_color), v.ip,  v.port)
                    end
                end
            end
        elseif action == 'says' then
            for k, v in pairs(users) do
                udp:sendto(string.format("%s %s %s", pseudo, 'says', message), v.ip,  v.port)
            end
        elseif action == 'plays' then
            color_played, column_played, line_played = message:match("(%d*) (%d*) (%d*)$")
            color_played, column_played, line_played = tonumber(color_played), tonumber(column_played), tonumber(line_played)
            if board[column_played][line_played] == 0 then
            board[column_played][line_played] = color_played
                for k, v in pairs(users) do
                    udp:sendto(string.format("%s %s %s", pseudo, 'plays', message), v.ip, v.port)
                end
                if  (board[1][1] ~= 0 and board[1][1] == board[1][2] and board[1][1] == board[1][3]) or
                    (board[2][1] ~= 0 and board[2][1] == board[2][2] and board[2][1] == board[2][3]) or
                    (board[3][1] ~= 0 and board[3][1] == board[3][2] and board[3][1] == board[3][3]) or
                    (board[1][1] ~= 0 and board[1][1] == board[2][1] and board[1][1] == board[3][1]) or
                    (board[1][2] ~= 0 and board[1][2] == board[2][2] and board[1][2] == board[3][2]) or
                    (board[1][3] ~= 0 and board[1][3] == board[2][3] and board[1][3] == board[3][3]) or
                    (board[1][1] ~= 0 and board[1][1] == board[2][2] and board[1][1] == board[3][3]) or
                    (board[3][1] ~= 0 and board[3][1] == board[2][2] and board[3][1] == board[1][3]) then
                        print(color_played)
                        for k, v in pairs(users) do
                            udp:sendto(string.format("%s %s %s", pseudo, 'wins', color_played), v.ip, v.port)
                        end
                end 
                remaining_turns = remaining_turns -1
                if remaining_turns == 0 then
                    for k, v in pairs(users) do
                        udp:sendto(string.format("%s %s %s", 'nobody', 'wins', '0'), v.ip, v.port)
                    end
                end          
            end
        elseif action == 'quits' then
            users[pseudo] = nil
        else
            print("unrecognised command:", action)
        end
    elseif msg_or_ip ~= 'timeout' then
        error("Unknown network error: "..tostring(msg))
    end
    socket.sleep(0.01)
end
