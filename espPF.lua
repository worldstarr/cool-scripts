local client = {}; do
    -- Tables
    client.esp = {}
    
    -- Modules
    for i,v in pairs(getgc(true)) do
        if (type(v) == "table") then
            if (rawget(v, "getplayerhealth")) then
                client.hud = v
            elseif (rawget(v, "getplayerhit")) then
                client.replication = v
            end
        end
    end

    client.chartable = debug.getupvalue(client.replication.getbodyparts, 1)
end

client.esp.Options = {
    Enable = true,
    TeamCheck = true,
    TeamColor = false,
    VisibleOnly = false,
    Color = Color3.fromRGB(255, 0, 255),
    Name = true,
    Box = true,
    Health = true,
    Distance = false,
    Tracer = false
}

client.esp.Services = setmetatable({}, {
    __index = function(Self, Index)
        local GetService = game.GetService
        local Service = GetService(game, Index)

        if Service then
            Self[Index] = Service
        end

        return Service
    end
})

local function GetDrawingObjects()
    return {
        Name = Drawing.new("Text"),
        Box = Drawing.new("Quad"),
        Tracer = Drawing.new("Line"),
    }
end

local function CreateEsp(Player)
    local Objects = GetDrawingObjects()
    local Character = client.chartable[Player].head.Parent
    local Head = Character.Head
    local HeadPosition = Head.Position
    local Head2dPosition, OnScreen = workspace.CurrentCamera:WorldToScreenPoint(HeadPosition)
    local Origin = workspace.CurrentCamera.CFrame.p
    local HeadPos = Head.Position
    local IgnoreList = { Character, client.esp.Services.Players.LocalPlayer.Character, workspace.CurrentCamera, workspace.Ignore }
    local PlayerRay = Ray.new(Origin, HeadPos - Origin)
    local Hit = workspace:FindPartOnRayWithIgnoreList(PlayerRay, IgnoreList)

    local function Create()
        if (OnScreen) then
            local Name = ""
            local Health = ""
            local Distance = ""
    
            if (client.esp.Options.Name) then
                Name = Player.Name
            end
    
            if (client.esp.Options.Health) then
                local Characters = debug.getupvalue(client.replication.getplayerhit, 1)
                Health = " [ " .. client.hud:getplayerhealth(Characters[Character]) .. "% ]"
            end
    
            if (client.esp.Options.Distance) then
                Distance = " [ " .. math.round((HeadPosition - workspace.CurrentCamera.CFrame.p).Magnitude) .. " studs ]"
            end
    
            Objects.Name.Visible = true
            Objects.Name.Transparency = 1
            Objects.Name.Text = string.format("%s%s%s", Name, Health, Distance)
            Objects.Name.Size = 18
            Objects.Name.Center = true
            Objects.Name.Outline = true
            Objects.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
            Objects.Name.Position = Vector2.new(Head2dPosition.X, Head2dPosition.Y)
    
            if (client.esp.Options.TeamColor) then
                Objects.Name.Color = Player.Team.TeamColor.Color
            else
                Objects.Name.Color = Color3.fromRGB(255, 255, 255)
            end
    
            if (client.esp.Options.Box) then
                local Part = Character.HumanoidRootPart
                local Size = Part.Size * Vector3.new(1, 1.5)
                local Sizes = {
                    TopRight = (Part.CFrame * CFrame.new(-Size.X, -Size.Y, 0)).Position,
                    BottomRight = (Part.CFrame * CFrame.new(-Size.X, Size.Y, 0)).Position,
                    TopLeft = (Part.CFrame * CFrame.new(Size.X, -Size.Y, 0)).Position,
                    BottomLeft = (Part.CFrame * CFrame.new(Size.X, Size.Y, 0)).Position,
                }
    
                local TL, OnScreenTL = workspace.CurrentCamera:WorldToScreenPoint(Sizes.TopLeft)
                local TR, OnScreenTR = workspace.CurrentCamera:WorldToScreenPoint(Sizes.TopRight)
                local BL, OnScreenBL = workspace.CurrentCamera:WorldToScreenPoint(Sizes.BottomLeft)
                local BR, OnScreenBR = workspace.CurrentCamera:WorldToScreenPoint(Sizes.BottomRight)
    
                if (OnScreenTL and OnScreenTR and OnScreenBL and OnScreenBR) then
                    Objects.Box.Visible = true
                    Objects.Box.Transparency = 1
                    Objects.Box.Thickness = 2
                    Objects.Box.Filled = false
                    Objects.Box.PointA = Vector2.new(TL.X, TL.Y + 36)
                    Objects.Box.PointB = Vector2.new(TR.X, TR.Y + 36)
                    Objects.Box.PointC = Vector2.new(BR.X, BR.Y + 36)
                    Objects.Box.PointD = Vector2.new(BL.X, BL.Y + 36)
    
                    if (client.esp.Options.TeamColor) then
                        Objects.Box.Color = Player.Team.TeamColor.Color
                    else
                        Objects.Box.Color = client.esp.Options.Color
                    end
                end
            end
    
            if (client.esp.Options.Tracer) then
                local CharTorso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
                local Torso, OnScreen = workspace.CurrentCamera:WorldToScreenPoint(CharTorso.Position)
    
                if (OnScreen) then
                    Objects.Tracer.Visible = true
                    Objects.Tracer.Transparency = 1
                    Objects.Tracer.Thickness = 2
                    Objects.Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                    Objects.Tracer.To = Vector2.new(Torso.X, Torso.Y + 36)
    
                    if (client.esp.Options.TeamColor) then
                        Objects.Tracer.Color = Player.Team.TeamColor.Color
                    else
                        Objects.Tracer.Color = client.esp.Options.Color
                    end
                end
            end
        end
    end

    if (client.esp.Options.VisibleOnly) then
        if (Hit == nil) then
            Create()
        end
    else
        Create()
    end

    client.esp.Services.RunService.Heartbeat:Wait()
    client.esp.Services.RunService.Heartbeat:Wait()

    Objects.Name:Remove()
    Objects.Box:Remove()
    Objects.Tracer:Remove()
end

client.esp.Services.RunService.RenderStepped:Connect(function()
    local LocalPlayer = client.esp.Services.Players.LocalPlayer

    for i,v in pairs(client.esp.Services.Players:GetPlayers()) do
        if (v and client.chartable[v] and v.Name ~= LocalPlayer.Name) then
            if (client.esp.Options.Enable) then
                if (client.esp.Options.TeamCheck) then
                    if (v.Team ~= LocalPlayer.Team) then
                        CreateEsp(v)
                    end
                else
                    CreateEsp(v)
                end
            end
        end
    end
end)
