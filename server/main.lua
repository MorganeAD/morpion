socket = require "socket"

udp = socket.udp()
udp:settimeout(0)
udp:setsockname('*', 12345)

users = {}
user_color = 0
local data, msg_or_ip, port_or_nil
local pseudo, action, message

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
            
            for k, v in pairs(users) do
                udp:sendto(string.format("%s %s %s", pseudo, 'plays', message), v.ip,  v.port)
            end
        elseif action == 'wins' then
            print(message)
            for k, v in pairs(users) do
                udp:sendto(string.format("%s %s %s", pseudo, 'wins', message), v.ip,  v.port)
            end
            print(WIN)
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


