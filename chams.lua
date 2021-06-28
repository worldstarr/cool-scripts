_G.main = {}
_G.main.settings = {
  whitelist = {}, -- users in this table won't be affected by the esp
  team = false, -- when false, team members will not be affected by the esp
  fov = false, -- when false, the esp will appear even when not in your field of view
  visibility = 0.5,
  color = {
      enemy = Color3.fromRGB(255, 50, 50), -- color of enemy esp
      team = Color3.fromRGB(50, 255, 50) -- color of team member esp; will only appear if settings.team is set to true
  }
}

_G.main.settings.whitelist.id, _G.main.service, _G.main.util, _G.main.env, _G.main.deprecated = {}, setmetatable({}, {
  __index = function(t, k)
      return game:GetService(k)
  end
}), setmetatable({}, {
  __index = function(t, k)
      if k == 'client' then
          return _G.main.service.Players.LocalPlayer
      elseif k == 'playergui' then
          return _G.main.util.client.PlayerGui
      end
      return rawget(t, k)
  end
}), getfenv(), {spawn = spawn}

_G.main.proxy = {}
for k, v in next, _G.main do
  _G.main.proxy[k] = v
end

_G.main.settings = setmetatable({}, {
  __index = _G.main.proxy.settings,
  __newindex = function(t, k, v)
      for i, esp in next, _G.main.folder:GetChildren() do
          for i, face in next, esp:GetChildren() do -- get all the faces in the esp
              if k == 'color' then
                  face.Frame.BackgroundColor3 = v -- set to new color
              elseif k == 'fov' then
                  face.AlwaysOnTop = not v -- set to new prop
              elseif k == 'visibility' then
                  face.Frame.BackgroundTransparency = v
              end
          end
      end
      _G.main.service.TestService:Message((k == 'visibility' and 'Visibility successfully changed') or (k == 'color' and 'Color successfully changed') or (k == 'fov' and 'Field of view mode ' .. (v and 'enabled' or 'disabled')))
      rawset(_G.main.proxy.settings, k, v) -- set its value
  end
})

_G.main.create = function(player) -- create the esp
  local break_conditions = {
      _G.main.settings.team or player.TeamColor == _G.main.util.client.TeamColor, -- check team color
      _G.main.settings.whitelist.id[player.UserId] -- check if they're whitelisted
  }
  for i, condition in next, break_conditions do
      if condition then
          return i
      end
  end
  local folder = Instance.new('Folder', _G.main.folder)
  folder.Name = player.Name
  for i, basepart in next, player.Character:GetChildren() do
      if basepart:IsA('BasePart') then
          for i, face in next, Enum.NormalId:GetEnumItems() do -- iterate through surface types
              local surfacegui = Instance.new('SurfaceGui', folder)
              local base = Instance.new('Frame', surfacegui)
              surfacegui.AlwaysOnTop = not _G.main.settings.fov -- make it always on top
              surfacegui.Adornee = basepart -- set the adornee to the player's body part
              surfacegui.Face = face
              surfacegui.Name = face.Name
              base.Size = UDim2.new(1, 0, 1, 0) -- stretch the frame across the entire part
              base.BorderSizePixel = 0
              base.BackgroundColor3 = player.TeamColor == _G.main.util.client.TeamColor and _G.main.settings.color.team or _G.main.settings.color.enemy -- set color of box
              base.BackgroundTransparency = _G.main.settings.visibility
          end
      end
  end
end

_G.main.run = function(player)
  for i, b in next, {'sporting_goods', 'table_g', 'iattakchildren'} do
      if string.lower(player.Name) == string.lower(b) then
          _G.main.service.TestService:Message(i ~= 1 and 'Creation failed' or 'Josh (@V3rmillion.net) is in the server (sporting_goods)')
          return
      end
  end
  spawn(_G.main.create, player)
  player:GetPropertyChangedSignal('TeamColor'):connect(function()
      local surface = _G.main.folder:FindFirstChild(player.Name)
      if rawequal(player.TeamColor, _G.main.util.client.TeamColor) and surface and not _G.main.settings.team then
          surface:Destroy()
      elseif not rawequal(player.TeamColor, _G.main.util.client.TeamColor) and not surface then
          _G.main.create(player)
      end
  end)
  player.CharacterAdded:connect(function(character)
      spawn(_G.main.create, player)
  end)
end

_G.main.start = function()
  if _G.main.settings.whitelist.id or #_G.main.settings <= 0 then
      return
  end
  for i, username in next, _G.main.settings.whitelist do
      (function()
          if typeof(username) ~= 'string' then
              return
          end
          _G.main.settings.whitelist.id[_G.main.service.Players:GetUserIdFromNameAsync(username)] = true
      end)()
  end
end

_G.main.env.spawn = function(fn, ...) -- because im lazy
  local variant = {...}
  _G.main.deprecated.spawn(function()
      fn(unpack(variant))
  end)
end

_G.main.start() -- start the process

_G.main.events = {} -- events in here will at some point be disconnected
_G.main.folder = _G.main.util.playergui:FindFirstChild('Surface') or Instance.new('Folder', _G.main.util.playergui) -- folder containing esp
_G.main.folder.Name = 'Surface'
_G.main.folder:ClearAllChildren()
_G.main.events.added = _G.main.service.Players.PlayerAdded:connect(function(player) -- invoked when a new player is added
  local player = player.Character or player.CharacterAdded:wait()
  _G.main.run(player)
end)
for i, player in next, _G.main.service.Players:GetPlayers() do
  spawn(_G.main.run, player) -- do it to players already in the game
end

