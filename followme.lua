_addon.version = '0.1.1'
_addon.name = 'followme'
_addon.author = 'yyoshisaur'
_addon.commands = {'followme','fm'}

require('strings')
require('logger')
require('coroutine')

packets = require('packets')

ionis_npcs = {
    [256] = {name = 'Fleuricette', menu = 1201},
    [257] = {name = 'Quiri-Aliri', menu = 1201},
}

local ionis_npc_state = 'idle'
local send_delay = 0.4
function get_delay()
    local self = windower.ffxi.get_player().name
    local members = {}
    for k, v in pairs(windower.ffxi.get_party()) do
        if type(v) == 'table' then
            members[#members + 1] = v.name
        end
    end
    table.sort(members)
    for k, v in pairs(members) do
        if v == self then
            return (k - 1) * send_delay
        end
    end
end

function get_ionis_npc()
    local zone = windower.ffxi.get_info().zone
    local ionis_npc = ionis_npcs[zone]
    local npc = nil

    if ionis_npc then
        npc = windower.ffxi.get_mob_by_name(ionis_npc.name)
    else
        log('No ionis npc found!')
        return nil
    end

    if npc and math.sqrt(npc.distance) < 6 then
        return npc
    else
        log(ionis_npc.name..' found, but too far!')
        return nil
    end
end

function start_ionis()

    local npc = get_ionis_npc()

    if npc then
        local p = packets.new('outgoing', 0x01A, {
            ["Target"] = npc.id,
            ["Target Index"] = npc.index
        })
        packets.inject(p)
        ionis_npc_state = 'start'
    end
end

function incoming_ionis(id, data, modified, injected, blocked)
    if id == 0x034 then
        if ionis_npc_state == 'start' then
            local in_p = packets.parse('incoming', data)
            local npc = get_ionis_npc()

            if npc and npc.id == in_p["NPC"] then
                windower.send_command('wait 3;setkey escape;wait 0.5;setkey escape up;')
            end
        end
    end
end

function outgoing_ionis(id, data, modified, injected, blocked)
    if id == 0x05B then
        if ionis_npc_state == 'start' then
            local out_p = packets.parse('outgoing', data)
            local npc = get_ionis_npc()

            if npc and npc.id == out_p["Target"] then
                out_p["Option Index"] = 1
                out_p["_unknown1"] = 0
                ionis_npc_state = 'idle'
                return packets.build(out_p)
            end
        end
    end
end

-- //fm start
-- //fm stop

function fm_command(...)
    local args = {...}
    if args[1] == 'start' then
        local id = windower.ffxi.get_player().id
        windower.send_ipc_message('follow start '..id)
    elseif args[1] == 'stop' then
        windower.send_ipc_message('follow stop')
    elseif args[1] == 'ionis' then
        local delay = get_delay()
        start_ionis:schedule(delay)
        windower.send_ipc_message('ionis')
    end
end

function fm_ipc_msg(message)
    local msg = message:split(' ')
    if msg[1] == 'follow' then
        if msg[2] == 'start' then
            local id = msg[3]
            local mob = windower.ffxi.get_mob_by_id(id)
            if mob then
                local index = mob.index
                windower.ffxi.follow(index)
            end
        elseif msg[2] == 'stop' then
            -- windower.ffxi.follow()
            windower.send_command('setkey numpad7 down;wait .5;setkey numpad7 up;')
        end
    elseif msg[1] == 'ionis' then
        local delay = get_delay()
        start_ionis:schedule(delay)
    end
end

windower.register_event('addon command', fm_command)
windower.register_event('ipc message', fm_ipc_msg)

windower.register_event('incoming chunk', incoming_ionis)
windower.register_event('outgoing chunk', outgoing_ionis)