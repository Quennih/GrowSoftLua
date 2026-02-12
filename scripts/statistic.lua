print('Statistic load port: ' .. getServerDefaultPort())

local file_path = 'currentState/statistic-data.json'
local Statistic = file.exists(file_path) and json.decode(file.read(file_path)) or {}

Statistic['registers'] = Statistic['registers'] or 0

local interval
local players = getAllPlayers()
local total_players = #players
local i = 1

if Statistic['registers'] == 0 and total_players > 0 then
  interval = timer.setInterval(0.05, function()
    if i > total_players then
      file.write(file_path, json.encode(Statistic))
      print('Statistic: success load ' .. total_players .. ' players')
      timer.clear(interval)
      return
    end

    local player = players[i]
    if player and player:getEmail() ~= '' then
      Statistic['registers'] = Statistic['registers'] + 1
    end

    i = i + 1
  end)
end

onPlayerRegisterCallback(function(world, player)
  Statistic['registers'] = Statistic['registers'] + 1
  file.write(file_path, json.encode(Statistic))
end)

onHTTPRequest(function(req)
  if req.method == 'get' and req.path == '/statistic' then
    local online = #getServerPlayers()
    local all_players = #getAllPlayers()

    return {
      status = 200,
      headers = { ['Content-Type'] = 'application/json' },
      body = json.encode({
        online = online,
        players = all_players,
        registers = Statistic['registers']
      })
    }
  end

  return { status = 404, body = 'Not Found', headers = {} }
end)