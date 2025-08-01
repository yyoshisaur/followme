_addon.version = '0.6.0'
_addon.name = 'followme'
_addon.author = 'yyoshisaur'
_addon.commands = {'followme','fm'}

require('strings')
-- //fm start
-- //fm stop

function fm_command(...)
    local args = {...}
    if args[1] == 'start' then
        local id = windower.ffxi.get_player().id
        windower.send_ipc_message('follow start '..id)
    elseif args[1] == 'stop' then
        windower.send_ipc_message('follow stop')
    end
end

function fm_ipc_msg(message)
    local msg = message:split(' ')
    if msg[1] == 'follow' then
        if msg[2] == 'start' then
            local id = msg[3]
            local mob = windower.ffxi.get_mob_by_id(id)
            if mob and mob.valid_target then
                local index = mob.index
                windower.ffxi.follow(index)
            end
        elseif msg[2] == 'stop' then
            -- windower.ffxi.follow(-1)
            windower.send_command('setkey numpad7 down;wait .5;setkey numpad7 up;')
        end
    end
end

windower.register_event('addon command', fm_command)
windower.register_event('ipc message', fm_ipc_msg)
