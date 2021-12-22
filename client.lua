local showMenu = false
local drawText = false
local activeLaser = false

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(100)
    TriggerServerEvent("nui_drawtext:server:sendDrawText")
end)

RegisterNUICallback('closeMenu', function()
    Wait(50)
    showMenu = false
    SetNuiFocus(false, false)
end) 

RegisterKeyMapping('activeLaser', 'Open Menu', 'keyboard', Config.OpenKey)

local function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return c, e
end

local function rgbToHex(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

local function Draw2DText(content, font, colour, scale, x, y)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(colour[1],colour[2],colour[3], 255)
    SetTextEntry("STRING")
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    AddTextComponentString(content)
    DrawText(x, y)
end

local function Draw3DTextPermanent(params)
    CreateThread(function()
        while true do
            Wait(0) 
            if Vdist2(GetEntityCoords(PlayerPedId(), false), params.xyz.x,params.xyz.y,params.xyz.z) < (params.radius) then
                local onScreen, _x, _y = World3dToScreen2d(params.xyz.x,params.xyz.y,params.xyz.z)
                local p = GetGameplayCamCoords()
                local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, params.xyz.x,params.xyz.y,params.xyz.z, 1)
                local fov = (1 / GetGameplayCamFov()) * 75
                local scale = (1 / distance) * (params.perspectiveScale) * fov * (params.text.scaleMultiplier)
                local r,g,b=rgbToHex(params.text.rgb)
                if onScreen then
                    SetTextScale(0.0, scale)
                    SetTextFont(params.text.font)
                    SetTextProportional(true)
                    SetTextColour(r, g, b, 255)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    SetTextCentre(true)
                    AddTextComponentString(params.text.content)
                    DrawText(_x,_y)
                end
            end
        end
    end)
end

RegisterCommand('activeLaser', function()
    Wait(50)
    activeLaser = not activeLaser
    TriggerEvent('nui_drawtext:client:laser')
end)

RegisterNetEvent('nui_drawtext:client:laser', function()
    while true do 
    Wait(1000)
    while activeLaser do
        Wait(0)
        local color = {r = 2, g = 241, b = 181, a = 200}
        local position = GetEntityCoords(PlayerPedId())
        local coords, entity = RayCastGamePlayCamera(1000.0)
        Draw2DText('PRESS ~g~E~w~ TO OPEN DRAWTEXT MENU', 4, {255, 255, 255}, 0.4, 0.46, 0.888 + 0.025)
        if IsControlJustReleased(0, 38) then
            SetNuiFocus(true, true)
            SendNUIMessage({ action = "open"}) 
            showMenu = true
            activeLaser=false
        end
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false)      
    end
end
end)

RegisterNUICallback('createDrawText', function(data, cb)
    local coords, entity = RayCastGamePlayCamera(1000.0)
    arg = data
    if arg.font == 4 then
        arg.font = 7
    elseif arg.font == 3 then
        arg.font = 4
    elseif arg.font == 2 then
        arg.font = 1
    elseif arg.font == 1 then
        arg.font = 0
    end
   
    TriggerServerEvent('nui_drawtext:server:drawText', arg.content, arg.font, coords,arg.color,  arg.size, arg.radius)
    activeLaser = false
    cb('ok')
end)

RegisterNetEvent('nui_drawtext:client:drawText', function(params)
    Draw3DTextPermanent(params)  
end)
