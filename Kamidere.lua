-- KamidereHub v2
-- LocalScript -> StarterPlayerScripts
local Players  = game:GetService("Players")
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
SoundService = game:GetService("SoundService")
MarketplaceService = game:GetService("MarketplaceService")
Debris = game:GetService("Debris")
PhysicsService = game:GetService("PhysicsService")
local plr   = Players.LocalPlayer
local cam   = workspace.CurrentCamera
local mouse = plr:GetMouse()
-- ============================================================
-- WHITELIST
-- ============================================================
local WHITELIST = {
	--{ id = 000000000, expires = "31.12.2026" },
}
local function checkWhitelist()
	local uid = plr.UserId
	for _, e in ipairs(WHITELIST) do
		if e.id == uid then
			local d,m,y = e.expires:match("(%d+)%.(%d+)%.(%d+)")
			if d then
				local t = os.time({year=tonumber(y),month=tonumber(m),day=tonumber(d),hour=23,min=59,sec=59})
				if os.time() <= t then return true, e.expires
				else plr:Kick("KamidereHub: подписка истекла ("..e.expires..")") return false end
			end
		end
	end
	if #WHITELIST == 0 then return true, "∞" end
	plr:Kick("KamidereHub: нет в вайтлисте") return false
end
local wlOk, wlExpires = checkWhitelist()
if not wlOk then return end
-- ============================================================
-- THEMES
-- ============================================================
local THEMES = {
	black = { bg=Color3.fromRGB(13,16,23), card=Color3.fromRGB(20,25,35),
		hover=Color3.fromRGB(25,33,48), topbar=Color3.fromRGB(16,20,29),
		text=Color3.fromRGB(232,237,248), dim=Color3.fromRGB(105,118,138),
		border=Color3.fromRGB(39,48,64), off=Color3.fromRGB(35,43,57),
		dot=Color3.fromRGB(125,139,160), on=Color3.fromRGB(74,145,224),
		hudBg=Color3.fromRGB(13,16,23), hudText=Color3.fromRGB(232,237,248),
		hudDim=Color3.fromRGB(105,118,138) },
	blue = { bg=Color3.fromRGB(9,17,31), card=Color3.fromRGB(14,27,47),
		hover=Color3.fromRGB(20,40,68), topbar=Color3.fromRGB(11,22,39),
		text=Color3.fromRGB(220,233,255), dim=Color3.fromRGB(103,132,174),
		border=Color3.fromRGB(32,59,92), off=Color3.fromRGB(25,43,68),
		dot=Color3.fromRGB(112,139,177), on=Color3.fromRGB(74,145,224),
		hudBg=Color3.fromRGB(9,17,31), hudText=Color3.fromRGB(220,233,255),
		hudDim=Color3.fromRGB(103,132,174) },
	white = { bg=Color3.fromRGB(247,248,250), card=Color3.fromRGB(255,255,255),
		hover=Color3.fromRGB(239,243,248), topbar=Color3.fromRGB(252,252,253),
		text=Color3.fromRGB(31,38,50), dim=Color3.fromRGB(112,122,138),
		border=Color3.fromRGB(218,224,233), off=Color3.fromRGB(226,231,238),
		dot=Color3.fromRGB(145,154,168), on=Color3.fromRGB(39,131,222),
		hudBg=Color3.fromRGB(247,248,250), hudText=Color3.fromRGB(31,38,50),
		hudDim=Color3.fromRGB(112,122,138) },
}
local CT = "black"
local function C(k) return THEMES[CT][k] end
local themeCBs = {}
local function onTC(f) table.insert(themeCBs, f) end
local bgAlpha = 0.06
local function applyTheme(name)
	CT = name
	for _, f in ipairs(themeCBs) do pcall(f) end
	-- Refresh detached HUD widgets immediately without toggling them off/on.
	local pg=plr:FindFirstChild("PlayerGui")
	local root=pg and pg:FindFirstChild("KamidereHub")
	if not root then return end
	local kb=root:FindFirstChild("KamidereKB")
	if kb then
		local headerBG=kb:FindFirstChild("KBHeaderBG") if headerBG then headerBG.BackgroundColor3=C("hudBg") end
		local headerStroke=headerBG and headerBG:FindFirstChild("KBHeaderStroke") if headerStroke then headerStroke.Color=C("border") end
		local header=kb:FindFirstChild("KBHeader") if header then header.TextColor3=C("hudText") end
		local rows=kb:FindFirstChild("KBRows")
		if rows then
			for _,row in ipairs(rows:GetChildren()) do
				if row:IsA("Frame") then
					row.BackgroundColor3=C("hudBg")
					local action=row:FindFirstChild("Action") if action then action.TextColor3=C("hudText") end
					local state=row:FindFirstChild("State") if state then
						state.BackgroundColor3=C("off")
						local dot=state:FindFirstChild("Dot") if dot then dot.BackgroundColor3=C("on") end
					end
					local rowStroke=row:FindFirstChild("RowStroke") if rowStroke then rowStroke.Color=C("border") end
				end
			end
		end
	end
	local wasd=root:FindFirstChild("KamidereWASD")
	if wasd then
		for _,label in ipairs(wasd:GetChildren()) do
			if label:IsA("TextLabel") and not label:GetAttribute("pressed") then label.TextColor3=C("hudText") end
		end
	end
end
-- ============================================================
-- STATE
-- ============================================================
local S = {
	-- Aimbot
	aimbotOn=false, aimbotTarget=nil, aimbotParts={"Head"}, aimbotSmooth=0,
	aimbotFOV=false, aimbotFOVval=100, aimbotFOVcolor=Color3.fromRGB(255,255,255),
	aimbotKey=nil, aimbotKeyMode="hold", aimbotKeyActive=false,
	useTargetList=false, targetList={},
	-- Triggerbot
	trigOn=false, trigActive=false, trigKey=nil, trigKeyMode="hold", trigKeyActive=false,
	trigReaction=false, trigReactionMs=0, trigSpeedMs=100,
	trigParts={"Head"},
	-- Visual
	chinaHat=false, chinaColor=Color3.fromRGB(255,200,50), chinaTransparency=0.3,
	aura=false, auraColor=Color3.fromRGB(0,150,255),
	motionTrail=false, motionTrailColor=Color3.fromRGB(74,145,224),
	boxESP=false, boxColor=Color3.fromRGB(255,50,50),
	nameESP=false, nameColor=Color3.fromRGB(255,255,255),
	healthESP=false,
	toolESP=false, toolColor=Color3.fromRGB(255,255,255),
	chams=false, chamsColor=Color3.fromRGB(255,50,50), chamsAlpha=0.3,
	ffIndicator=false,
	fullbright=false, fbAmt=100, origLight={},
	rtx=false, rtxIntensity=70,
	motionBlur=false,
	dynamicCamera=false, dynamicCameraStrength=0.08, dynamicCameraSmoothness=12,
	customCrosshair=false, crosshairColor=Color3.fromRGB(255,255,255), crosshairSpin=false,
	toolViewmodel=false, visibleHands=false, viewmodelX=0, viewmodelY=0, viewmodelZ=0, screenFov=70, viewmodelFov=70,
	idPlayer=false, songId="",
	deathSparkles=false, selfDeathSparkles=false, sparklesColor=Color3.fromRGB(255,180,50), deathSparklesAmount=125, deathSparklesRadius=1, deathSparklesSpeed=15,
	playerTransparency=0, selfPlayerTransparency=0,
	velocityIndicator=false, velocityColor=Color3.fromRGB(255,255,255),
	snowParticles=false, snowAmount=58, snowRadius=32, snowSpeed=9,
	celestialSigil=false, celestialSigilColor=Color3.fromRGB(85,170,255), celestialSigilSize=5, celestialSigilIntensity=1,
	celestialWings=false, celestialWingsColor=Color3.fromRGB(245,248,255), celestialWingsSize=1, celestialWingsIntensity=1,
	etherealCubes=false, etherealCubesColor=Color3.fromRGB(105,180,255), etherealCubesAmount=10, etherealCubesRadius=16, etherealCubesSpeed=0.8,
	toolChams=false, toolChamsColor=Color3.fromRGB(100,200,255), toolChamsAlpha=0.3,
	toolOrigData={},
	myChams=false, myChamsColor=Color3.fromRGB(100,255,100), myChamsAlpha=0.3,
	worldColor=false, worldColorVal=Color3.fromRGB(255,50,50), worldColorIntensity=100, worldOrig={},
	watermark=false, hitlogs=false, targetHUD=false, keybindInd=false, wasdInd=false,
	-- Misc
	autoTrample=false,
	counterStrikeMovement=false, csMaxSpeed=90, csAcceleration=5, csAirAcceleration=2.2, csFriction=6,
	pixelSurf=false, pixelSurfKey=nil, pixelSurfKeyMode="hold", pixelSurfKeyActive=false, pixelSurfSound=true, pixelSurfSoundId="9045331159", pixelSurfAcceleration=4, pixelSurfMaxSpeed=60, pixelSurfVisualiser=false, pixelSurfVisualiserColor=Color3.fromRGB(80,180,255),
	edgeJump=false, edgeJumpKey=nil, edgeJumpKeyMode="hold", edgeJumpKeyActive=false, edgeBug=false, edgeBugKey=nil, edgeBugKeyMode="hold", edgeBugKeyActive=false, edgeBugSparkles=false, pixelSurfSparkles=false,
	jumpBug=false, jumpBugPower=75, jumpBugKey=nil, jumpBugKeyMode="hold", jumpBugKeyActive=false,
}
local cheatDisabled=false
local dynamicCameraOffset=Vector3.new(0,0,0)
local dynamicCameraHumanoid=nil
local DYNAMIC_CAMERA_BIND="KamidereDynamicCamera"
toolViewOriginals=setmetatable({}, {__mode="k"})
transparencyOriginals=setmetatable({}, {__mode="k"})
deathWatchConnections={}
crosshairAngle=0
songSound=Instance.new("Sound",SoundService)
songSound.Name="KamidereSongPlayer" songSound.Volume=1
originalScreenFov=cam.FieldOfView
S.screenFov=cam.FieldOfView
viewmodelPartMap={}
viewmodelCharacter=nil
viewmodelSignatureNext=0
transparencyUpdateAccumulator=0
espUpdateAccumulator=0
espRuntimeActive=false
rtxOriginal=nil
counterStrikeHumanoid=nil
counterStrikeOriginalWalkSpeed=nil
counterStrikeOriginalAutoRotate=nil
counterStrikeLastYaw=nil
counterStrikeAirVelocity=nil
counterStrikeBhopActive=false
pixelSurfSliding=false
pixelSurfHeight=0
pixelSurfWallNormal=nil
pixelSurfDirection=nil
pixelSurfSpeed=0
pixelSurfTravel=0
pixelSurfLastPosition=nil
pixelSurfCooldown=0
pixelSurfOriginalWalkSpeed=nil
pixelSurfSoundObject=Instance.new("Sound",SoundService)
pixelSurfSoundObject.Name="KamiderePixelSurfSound" pixelSurfSoundObject.Volume=0.55
pixelSurfVisualiserNext=0
edgeJumpCooldown=0
edgeJumpHadGround=false
edgeBugCooldown=0
edgeBugLastTriggered=0
jumpBugHumanoid=nil
jumpBugOriginalUseJumpPower=nil
jumpBugOriginalPower=nil
jumpBugOriginalHeight=nil
local SAFE_ZONES = {"ZoneSpawn1","CourtZone1"}
local ALL_PARTS = {"Head","Torso","UpperTorso","LeftUpperArm","RightUpperArm",
	"LeftUpperLeg","RightUpperLeg","HumanoidRootPart"}
-- Priority order for aimbot multi-part
local AIM_PRIORITY = {"Head","Torso","UpperTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","HumanoidRootPart"}
local CORNERS = {
	Vector3.new(-1,-1,-1),Vector3.new(1,-1,-1),Vector3.new(-1,1,-1),Vector3.new(1,1,-1),
	Vector3.new(-1,-1,1),Vector3.new(1,-1,1),Vector3.new(-1,1,1),Vector3.new(1,1,1),
}
-- ============================================================
-- HELPERS
-- ============================================================
local function getChar()  return plr.Character end
local function getHRP()   local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getBodyPart(char, pname)
	local map = {Head={"Head"}, Torso={"Torso","UpperTorso"}}
	for _,n in ipairs(map[pname] or {pname}) do
		local p=char:FindFirstChild(n)
		if p and p:IsA("BasePart") then return p end
	end
	return char:FindFirstChild("HumanoidRootPart")
end
safeZoneParts={}
safeZoneCacheStarted=false
safeZoneNames={}
for _,name in ipairs(SAFE_ZONES) do safeZoneNames[name]=true end
function warmSafeZoneCache()
	if safeZoneCacheStarted then return end
	safeZoneCacheStarted=true
	workspace.DescendantAdded:Connect(function(object)
		if safeZoneNames[object.Name] and object:IsA("BasePart") then table.insert(safeZoneParts,object) end
	end)
	task.spawn(function()
		for _,name in ipairs(SAFE_ZONES) do
			local zone=workspace:FindFirstChild(name,true)
			if zone and zone:IsA("BasePart") then table.insert(safeZoneParts,zone) end
			RS.Heartbeat:Wait()
		end
	end)
end
warmSafeZoneCache()
local function isInSafeZone(char)
	if not char then return false end
	local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return false end
	for index=#safeZoneParts,1,-1 do
		local zone=safeZoneParts[index]
		if not zone or not zone.Parent then table.remove(safeZoneParts,index)
		else
			local rel=zone.CFrame:PointToObjectSpace(hrp.Position) local half=zone.Size/2
			if math.abs(rel.X)<=half.X and math.abs(rel.Y)<=half.Y+3 and math.abs(rel.Z)<=half.Z then return true end
		end
	end
	return false
end
local function isPlayerAllowed(p2)
	if not S.useTargetList then return true end
	return S.targetList[p2.Name] == true
end
-- Smart visibility check for a specific part
local function isPartVisible(char, part)
	local myChar = getChar()
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = myChar and {myChar, cam} or {cam}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local camPos = cam.CFrame.Position
	local dir = part.Position - camPos
	local result = workspace:Raycast(camPos, dir, params)
	if not result then return true end
	local hit = result.Instance
	if not hit then return true end
	if hit.Transparency >= 0.9 or not hit.CanCollide then return true end
	local hitChar = hit.Parent
	if hitChar and hitChar:FindFirstChild("Humanoid") and hitChar == char then return true end
	return false
end
-- Find best aim point considering multiple parts with priority
local function findBestAimPoint(char, parts)
	local myChar = getChar()
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = myChar and {myChar, cam} or {cam}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local camPos = cam.CFrame.Position
	-- Build ordered list: priority parts first
	local orderedParts = {}
	-- First add priority parts that are in selected list
	for _, pname in ipairs(AIM_PRIORITY) do
		for _, selected in ipairs(parts) do
			if selected == pname then
				table.insert(orderedParts, pname)
				break
			end
		end
	end
	for _, pname in ipairs(orderedParts) do
		local part = getBodyPart(char, pname)
		if not part then continue end
		local centerResult=workspace:Raycast(camPos,part.Position-camPos,params)
		local centerHit=centerResult and centerResult.Instance
		local centerVisible=(not centerResult) or (centerHit and centerHit:IsDescendantOf(char)) or (centerHit and (centerHit.Transparency>=0.9 or not centerHit.CanCollide))
		if centerVisible then local _,inView=cam:WorldToViewportPoint(part.Position) if inView then return part.Position end end
		local toTarget = (part.Position - camPos).Unit
		local right = toTarget:Cross(Vector3.new(0,1,0)).Unit
		local up = right:Cross(toTarget).Unit
		local hs = part.Size * 0.45
		local testOffsets = {
			up*hs.Y, -up*hs.Y,
			right*hs.X, -right*hs.X,
			up*hs.Y*0.5 + right*hs.X*0.5,
			up*hs.Y*0.5 - right*hs.X*0.5,
		}
		local bestPos = nil
		local bestDist = math.huge
		for _, offset in ipairs(testOffsets) do
			local testPos = part.Position + offset
			local dir = testPos - camPos
			local result = workspace:Raycast(camPos, dir, params)
			local hit = result and result.Instance
			local visible = (not result) or (hit and hit:IsDescendantOf(char))
			if not visible and hit and (hit.Transparency >= 0.9 or not hit.CanCollide) then
				visible = true
			end
			if visible then
				local screenPos, inView = cam:WorldToViewportPoint(testPos)
				if inView then
					local vp = cam.ViewportSize
					local center = Vector2.new(vp.X/2, vp.Y/2)
					local d = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					if d < bestDist then
						bestDist = d
						bestPos = testPos
					end
				end
			end
		end
		if bestPos then return bestPos end
	end
	-- fallback: just use first available part
	for _, pname in ipairs(orderedParts) do
		local part = getBodyPart(char, pname)
		if part then return part.Position end
	end
	return nil
end
local function getClosestToCenter()
	local best, bd = nil, math.huge
	local vp = cam.ViewportSize
	local center = Vector2.new(vp.X/2, vp.Y/2)
	for index, p2 in ipairs(Players:GetPlayers()) do
		if index%8==0 then RS.Heartbeat:Wait() end
		if p2 ~= plr and p2.Character and isPlayerAllowed(p2) then
			local hum2 = p2.Character:FindFirstChild("Humanoid")
			if hum2 and hum2.Health > 0 and not isInSafeZone(p2.Character) then
				-- Try each selected part
				for _, pname in ipairs(S.aimbotParts) do
					local part = getBodyPart(p2.Character, pname)
					if part then
						local sp, vis = cam:WorldToViewportPoint(part.Position)
						if vis and sp.Z > 0 then
							local d = (Vector2.new(sp.X,sp.Y) - center).Magnitude
							local fovOk = (not S.aimbotFOV) or (d <= S.aimbotFOVval)
							if fovOk and d < bd then best, bd = p2, d end
						end
						break
					end
				end
			end
		end
	end
	return best
end
aimbotAcquiring=false
aimbotAcquireGeneration=0
aimbotCachedPoint=nil
aimbotCachedTarget=nil
aimbotPointNext=0
aimbotRespawnTarget=nil
function markAimbotTargetForRespawn()
	if S.aimbotTarget then aimbotRespawnTarget=S.aimbotTarget end
	S.aimbotTarget=nil aimbotCachedTarget=nil aimbotCachedPoint=nil aimbotPointNext=0
end
function requestAimbotTarget()
	if aimbotAcquiring or not S.aimbotOn or not S.aimbotKeyActive then return end
	aimbotAcquiring=true aimbotAcquireGeneration=aimbotAcquireGeneration+1
	local generation=aimbotAcquireGeneration
	task.defer(function()
		local target=getClosestToCenter()
		if generation==aimbotAcquireGeneration and S.aimbotOn and S.aimbotKeyActive then
			S.aimbotTarget=target aimbotCachedTarget=nil aimbotCachedPoint=nil
			if target then aimbotRespawnTarget=nil end
			if target then local viewport=cam.ViewportSize pcall(function() game:GetService("VirtualInputManager"):SendMouseMoveEvent(viewport.X/2,viewport.Y/2,game) end) end
		end
		aimbotAcquiring=false
	end)
end
-- ============================================================
-- KAMIDERE / TENZODERE UI ADAPTER
-- ============================================================
local UI_URL="https://raw.githubusercontent.com/tenzarek/TenzodereUI/main/init.lua"
local Library=loadstring(game:HttpGet(UI_URL))()
local Window=Library:CreateWindow({Name="KAMIDERE",Keybind=Enum.KeyCode.Insert,Accent=Color3.fromRGB(245,170,239)})
local sg=Window.Gui
sg.Name="Kamidere" sg.DisplayOrder=100000
local mainFrame=Window.Main
local MainUI=Window:CreateTab("Combat","Target")
local VisualUI=Window:CreateTab("Players","Eye")
local MiscUI=Window:CreateTab("Misc","SlidersHorizontal")
local ConfigUI=Window:CreateTab("Configs","Settings")
local tabColumns={
 main={left={tab=MainUI},right={tab=MainUI}},
 visuals={left={tab=VisualUI},right={tab=VisualUI}},
 misc={left={tab=MiscUI},right={tab=MiscUI}},
 cfg={left={tab=ConfigUI},right={tab=ConfigUI}},
}
local configControls,configControlOrder={},{}
local settingKey=false
local configSkip={['Turn Off Cheat']=true,['Infinite Yield']=true}
local function registerConfigControl(label,control)
 if configSkip[label] then return end
 configControls[label]=control table.insert(configControlOrder,label)
end
local function mkSection(parent,title) parent.current=parent.tab:CreateSection(title);return parent.current end
local function sectionOf(parent) if not parent.current then mkSection(parent,"General") end return parent.current end
local function latestRow(sec,before)
 local found=nil
 for _,v in ipairs(sec.Container:GetChildren()) do if v:IsA("GuiObject") and not before[v] then found=v end end
 return found
end
local function captureBefore(sec)local t={} for _,v in ipairs(sec.Container:GetChildren())do t[v]=true end return t end
local function mkToggle(parent,label,default,callback)
 local sec=sectionOf(parent);local c=sec:CreateToggle({Name=label,Flag=label,Default=default,Callback=callback})
 registerConfigControl(label,{kind="toggle",get=c.Get,set=c.Set});return c
end
local function mkSlider(parent,label,min,max,default,step,callback)
 local sec=sectionOf(parent);local before=captureBefore(sec)
 local c=sec:CreateSlider({Name=label,Flag=label,Min=min,Max=max,Default=default,Increment=step,Callback=callback})
 registerConfigControl(label,{kind="slider",get=c.Get,set=c.Set});return latestRow(sec,before)
end
local function mkRGB(parent,label,default,callback)
 local sec=sectionOf(parent);local c=sec:CreateColorPicker({Name=label,Flag=label,Default=default,Callback=callback})
 registerConfigControl(label,{kind="color",get=c.Get,set=c.Set});return c
end
local function mkDropdown(parent,label,options,default,callback)
 local sec=sectionOf(parent);local c=sec:CreateDropdown({Name=label,Flag=label,Options=options,Default=default,Callback=callback})
 registerConfigControl(label,{kind="dropdown",get=c.Get,set=c.Set});return c
end
local function mkButton(parent,label,callback)return sectionOf(parent):CreateButton({Name=label,Callback=callback})end
local function mkKeybind(parent,label,onKey,onMode)
 local sec=sectionOf(parent)
 local mode=sec:CreateDropdown({Name=label.." Mode",Options={"hold","toggle","always on"},Default="hold",Callback=onMode})
 local key=sec:CreateKeybind({Name=label,Default=Enum.KeyCode.None,Callback=onKey})
 local function set(data)
  if type(data)~="table" then return end
  mode.Set(data.mode or "hold")
  local k=(type(data.key)=="string" and Enum.KeyCode[data.key]) or Enum.KeyCode.None
  key.Set(k)
 end
 registerConfigControl(label,{kind="keybind",get=function()local k=key.Get();return{key=k and k.Name or "none",mode=mode.Get()}end,set=set})
 return key
end
local function mkMultiSelect(parent,label,options,defaults,callback)
 local selected={} for _,v in ipairs(defaults or {})do selected[v]=true end
 local controls={}
 local function emit()local out={}for _,v in ipairs(options)do if selected[v]then table.insert(out,v)end end;if #out==0 and options[1]then selected[options[1]]=true;out={options[1]}end;callback(out)end
 for _,opt in ipairs(options)do controls[opt]=sectionOf(parent):CreateToggle({Name=label..": "..opt,Default=selected[opt]==true,Callback=function(v)selected[opt]=v;emit()end})end
 local function get()local out={}for _,v in ipairs(options)do if selected[v]then table.insert(out,v)end end;return out end
 local function set(values)local wanted={}for _,v in ipairs(type(values)=="table" and values or {})do wanted[v]=true end;for _,opt in ipairs(options)do selected[opt]=wanted[opt]==true;controls[opt].Set(selected[opt],true)end;emit()end
 registerConfigControl(label,{kind="multiselect",get=get,set=set});return controls
end
function mkTextSetting(parent,label,default,callback)
 local sec=sectionOf(parent)
 local row=Instance.new("Frame",sec.Container);row.Size=UDim2.new(1,0,0,48);row.BackgroundTransparency=1
 local title=Instance.new("TextLabel",row);title.Size=UDim2.new(.45,0,1,0);title.BackgroundTransparency=1;title.Text=label;title.TextColor3=Color3.fromRGB(177,177,177);title.TextSize=13;title.Font=Enum.Font.Code;title.TextXAlignment=Enum.TextXAlignment.Left
 local box=Instance.new("TextBox",row);box.AnchorPoint=Vector2.new(1,.5);box.Position=UDim2.new(1,0,.5,0);box.Size=UDim2.fromOffset(128,27);box.BackgroundColor3=Color3.fromRGB(20,20,20);box.BorderSizePixel=0;box.Text=tostring(default or "");box.TextColor3=Color3.fromRGB(177,177,177);box.TextSize=11;box.Font=Enum.Font.Code;box.ClearTextOnFocus=false
 Instance.new("UICorner",box).CornerRadius=UDim.new(0,4)
 local current=tostring(default or "")
 local function set(v)current=tostring(v or "");box.Text=current;callback(current)end
 box.FocusLost:Connect(function()set(box.Text)end)
 registerConfigControl(label,{kind="text",get=function()return current end,set=set});return row
end
-- Target list popup kept as a detached Kamidere panel.
local targetListPanel=Instance.new("Frame",sg);targetListPanel.Name="KamidereTargetList";targetListPanel.Size=UDim2.fromOffset(360,430);targetListPanel.Position=UDim2.new(.5,-180,.5,-215);targetListPanel.BackgroundColor3=Color3.fromRGB(17,17,17);targetListPanel.BorderSizePixel=0;targetListPanel.Visible=false;targetListPanel.ZIndex=700;targetListPanel.Active=true;targetListPanel.Draggable=true
Instance.new("UICorner",targetListPanel).CornerRadius=UDim.new(0,14)
local targetTitle=Instance.new("TextLabel",targetListPanel);targetTitle.Size=UDim2.new(1,-55,0,50);targetTitle.Position=UDim2.fromOffset(16,4);targetTitle.BackgroundTransparency=1;targetTitle.Text="Target List";targetTitle.TextColor3=Color3.fromRGB(242,242,242);targetTitle.TextSize=16;targetTitle.Font=Enum.Font.Code;targetTitle.TextXAlignment=Enum.TextXAlignment.Left;targetTitle.ZIndex=701
local targetClose=Instance.new("TextButton",targetListPanel);targetClose.Size=UDim2.fromOffset(34,34);targetClose.Position=UDim2.new(1,-44,0,10);targetClose.BackgroundColor3=Color3.fromRGB(27,27,27);targetClose.Text="×";targetClose.TextColor3=Color3.fromRGB(177,177,177);targetClose.TextSize=20;targetClose.ZIndex=702;Instance.new("UICorner",targetClose).CornerRadius=UDim.new(0,8);targetClose.MouseButton1Click:Connect(function()targetListPanel.Visible=false end)
local targetScroll=Instance.new("ScrollingFrame",targetListPanel);targetScroll.Position=UDim2.fromOffset(12,56);targetScroll.Size=UDim2.new(1,-24,1,-68);targetScroll.BackgroundTransparency=1;targetScroll.BorderSizePixel=0;targetScroll.ScrollBarThickness=2;targetScroll.ScrollBarImageColor3=Color3.fromRGB(245,170,239);targetScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;targetScroll.CanvasSize=UDim2.new();targetScroll.ZIndex=701
local targetLayout=Instance.new("UIListLayout",targetScroll);targetLayout.Padding=UDim.new(0,6)
local function refreshTargetList()
 for _,v in ipairs(targetScroll:GetChildren())do if v:IsA("TextButton")then v:Destroy()end end
 for _,p2 in ipairs(Players:GetPlayers())do if p2~=plr then
  local b=Instance.new("TextButton",targetScroll);b.Size=UDim2.new(1,-4,0,42);b.BackgroundColor3=S.targetList[p2.Name] and Color3.fromRGB(50,36,49) or Color3.fromRGB(27,27,27);b.BorderSizePixel=0;b.Text=(S.targetList[p2.Name] and "✓  " or "○  ")..p2.DisplayName.."  @"..p2.Name;b.TextColor3=Color3.fromRGB(210,210,210);b.TextSize=12;b.Font=Enum.Font.Code;b.ZIndex=702;Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
  b.MouseButton1Click:Connect(function()S.targetList[p2.Name]=not S.targetList[p2.Name] or nil;refreshTargetList()end)
 end end
end

function removeScreenObject(name)
	local object=sg:FindFirstChild(name)
	if object then object:Destroy() end
end
function createCrosshair()
	removeScreenObject("KamidereCrosshair")
	local holder=Instance.new("Frame",sg) holder.Name="KamidereCrosshair"
	holder.AnchorPoint=Vector2.new(0.5,0.5) holder.Position=UDim2.new(0.5,0,0.5,0)
	holder.Size=UDim2.new(0,24,0,24) holder.BackgroundTransparency=1 holder.ZIndex=500
	local horizontal=Instance.new("Frame",holder) horizontal.Name="Horizontal"
	horizontal.Size=UDim2.new(0,20,0,1) horizontal.Position=UDim2.new(0.5,-10,0.5,0)
	horizontal.BorderSizePixel=0 horizontal.BackgroundColor3=S.crosshairColor horizontal.ZIndex=501
	local vertical=Instance.new("Frame",holder) vertical.Name="Vertical"
	vertical.Size=UDim2.new(0,1,0,20) vertical.Position=UDim2.new(0.5,0,0.5,-10)
	vertical.BorderSizePixel=0 vertical.BackgroundColor3=S.crosshairColor vertical.ZIndex=501
end
function destroyFirstPersonViewmodel()
	local frame=sg:FindFirstChild("KamidereFirstPersonViewmodel")
	if not frame and viewmodelCharacter==nil and next(viewmodelPartMap)==nil then return end
	if frame then frame:Destroy() end
	viewmodelPartMap={} viewmodelCharacter=nil viewmodelSignature=nil viewmodelSignatureNext=0
end
function isViewmodelArm(name)
	return name=="Left Arm" or name=="Right Arm" or name=="LeftHand" or name=="RightHand" or name=="LeftLowerArm" or name=="RightLowerArm" or name=="LeftUpperArm" or name=="RightUpperArm"
end
function getViewmodelSignature(char)
	if not char then return "none" end
	local items={S.visibleHands and "hands:on" or "hands:off"}
	for _,child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") or child:IsA("Accessory") then
			local count=0 for _,part in ipairs(child:GetDescendants()) do if part:IsA("BasePart") then count=count+1 end end
			table.insert(items,child.ClassName..":"..child.Name..":"..count)
		end
	end
	table.sort(items) return table.concat(items,"|")
end
function isClothingAccessory(accessory)
	if not accessory or not accessory:IsA("Accessory") then return false end
	local kind=accessory.AccessoryType
	return kind==Enum.AccessoryType.Shirt or kind==Enum.AccessoryType.TShirt or kind==Enum.AccessoryType.Sweater or kind==Enum.AccessoryType.Jacket or kind==Enum.AccessoryType.DressSkirt
end
function rebuildFirstPersonViewmodel(char)
	destroyFirstPersonViewmodel()
	if not char then return end
	local frame=Instance.new("ViewportFrame",sg) frame.Name="KamidereFirstPersonViewmodel"
	frame.Size=UDim2.new(1,0,1,0) frame.BackgroundTransparency=1 frame.BorderSizePixel=0
	frame.Ambient=Color3.new(1,1,1) frame.LightColor=Color3.new(1,1,1) frame.LightDirection=Vector3.new(-1,-1,-1)
	frame.ZIndex=90
	local world=Instance.new("WorldModel",frame) world.Name="ViewmodelWorld"
	local viewCamera=Instance.new("Camera",frame) viewCamera.Name="ViewmodelCamera" viewCamera.CFrame=CFrame.new()
	frame.CurrentCamera=viewCamera viewmodelCharacter=char viewmodelPartMap={}
	local oldArchivable=char.Archivable char.Archivable=true
	local ok,avatar=pcall(function() return char:Clone() end)
	char.Archivable=oldArchivable
	if not ok or not avatar then return end
	avatar.Name="ExactAvatarArms" avatar.Parent=world
	local humanoid=avatar:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
	for _,item in ipairs(avatar:GetDescendants()) do
		if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") or item:IsA("Highlight") or item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then item:Destroy() end
	end
	for _,clonePart in ipairs(avatar:GetDescendants()) do
		if clonePart:IsA("BasePart") then
			clonePart.Anchored=true clonePart.CanCollide=false clonePart.CanTouch=false clonePart.CanQuery=false clonePart.Massless=true
			clonePart.LocalTransparencyModifier=0 clonePart.Transparency=1
			local original=nil local keep=false
			local cloneTool=clonePart:FindFirstAncestorOfClass("Tool")
			local cloneAccessory=clonePart:FindFirstAncestorOfClass("Accessory")
			if cloneTool then
				local originalTool=char:FindFirstChild(cloneTool.Name)
				original=originalTool and originalTool:FindFirstChild(clonePart.Name,true)
				keep=original~=nil
			elseif cloneAccessory then
				local originalAccessory=char:FindFirstChild(cloneAccessory.Name)
				original=originalAccessory and originalAccessory:FindFirstChild(clonePart.Name,true)
				local weld=clonePart:FindFirstChild("AccessoryWeld") or clonePart:FindFirstChildWhichIsA("Weld")
				local armAttached=weld and weld.Part1 and isViewmodelArm(weld.Part1.Name)
				keep=original~=nil and S.visibleHands and (armAttached or isClothingAccessory(cloneAccessory))
			elseif S.visibleHands and isViewmodelArm(clonePart.Name) then
				original=char:FindFirstChild(clonePart.Name)
				keep=original~=nil
			end
			if keep and original then
				clonePart:SetAttribute("KamidereVisibleHandPart",cloneTool==nil)
				clonePart.Transparency=math.max(original.Transparency,S.selfPlayerTransparency)
				clonePart.Color=original.Color clonePart.Material=original.Material clonePart.Reflectance=original.Reflectance
				viewmodelPartMap[original]=clonePart
			end
		end
	end
	viewmodelSignature=getViewmodelSignature(char)
end
function updateFirstPersonViewmodel(char)
	local active=char and isFirstPersonCamera() and (S.visibleHands or S.toolViewmodel) and not char:GetAttribute("KamidereDeathHidden")
	if not active then destroyFirstPersonViewmodel() return end
	local frame=sg:FindFirstChild("KamidereFirstPersonViewmodel")
	local needsRebuild=viewmodelCharacter~=char or not frame
	if not needsRebuild and os.clock()>=viewmodelSignatureNext then
		viewmodelSignatureNext=os.clock()+0.5
		needsRebuild=getViewmodelSignature(char)~=viewmodelSignature
	end
	if needsRebuild then rebuildFirstPersonViewmodel(char) frame=sg:FindFirstChild("KamidereFirstPersonViewmodel") viewmodelSignatureNext=os.clock()+0.5 end
	local viewCamera=frame and frame:FindFirstChild("ViewmodelCamera")
	if not frame or not viewCamera then return end
	viewCamera.CFrame=CFrame.new()
	viewCamera.FieldOfView=math.clamp(S.screenFov+(S.viewmodelFov-70),20,120)
	local offset=S.toolViewmodel and CFrame.new(S.viewmodelX,-S.viewmodelY,S.viewmodelZ) or CFrame.new()
	for original,clone in pairs(viewmodelPartMap) do
		if original.Parent and clone.Parent then
			clone.CFrame=offset*cam.CFrame:ToObjectSpace(original.CFrame)
			local handsChams=S.visibleHands and S.myChams and clone:GetAttribute("KamidereVisibleHandPart")==true
			clone.Transparency=handsChams and math.max(original.Transparency,S.myChamsAlpha) or math.max(original.Transparency,S.selfPlayerTransparency)
			clone.Color=handsChams and S.myChamsColor or original.Color clone.Material=handsChams and Enum.Material.ForceField or original.Material clone.Reflectance=original.Reflectance
			local handHighlight=clone:FindFirstChild("KamidereVisibleHandsChams")
			if handsChams then
				if not handHighlight then handHighlight=Instance.new("Highlight",clone) handHighlight.Name="KamidereVisibleHandsChams" handHighlight.Adornee=clone handHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop end
				handHighlight.FillColor=S.myChamsColor handHighlight.OutlineColor=S.myChamsColor handHighlight.FillTransparency=S.myChamsAlpha handHighlight.OutlineTransparency=0
			elseif handHighlight then handHighlight:Destroy() end
			if clone:IsA("MeshPart") and original:IsA("MeshPart") then clone.TextureID=original.TextureID end
		end
	end
end
function restoreToolViewmodel()
	for tool,grip in pairs(toolViewOriginals) do
		if tool and tool.Parent then pcall(function() tool.Grip=grip end) end
		toolViewOriginals[tool]=nil
	end
end
function restoreAllTransparency()
	for part,value in pairs(transparencyOriginals) do
		if part and part.Parent then pcall(function() part.LocalTransparencyModifier=value end) end
		transparencyOriginals[part]=nil
	end
end
function createVelocityIndicator()
	removeScreenObject("KamidereVelocity")
	local label=Instance.new("TextLabel",sg) label.Name="KamidereVelocity"
	label.AnchorPoint=Vector2.new(0.5,1) label.Position=UDim2.new(0.5,0,1,-112)
	label.Size=UDim2.new(0,120,0,28) label.BackgroundTransparency=1 label.Text="0"
	label.TextColor3=S.velocityColor label.TextSize=22 label.Font=Enum.Font.GothamBold label.ZIndex=220
end
function removeWorldSnow()
	local snow=workspace:FindFirstChild("KamidereWorldSnow_"..plr.UserId)
	if snow then snow:Destroy() end
end
function createWorldSnow()
	removeWorldSnow()
	local source=Instance.new("Part",workspace) source.Name="KamidereWorldSnow_"..plr.UserId
	source.Anchored=true source.CanCollide=false source.CanTouch=false source.CanQuery=false
	source.Transparency=1 source.Size=Vector3.new(S.snowRadius*2,1,S.snowRadius*2)
	local emitter=Instance.new("ParticleEmitter",source) emitter.Name="SnowEmitter"
	emitter.Texture="rbxasset://textures/particles/smoke_main.dds"
	emitter.Color=ColorSequence.new(Color3.new(1,1,1)) emitter.LightEmission=0.35 emitter.LightInfluence=0.2
	emitter.Rate=S.snowAmount emitter.Lifetime=NumberRange.new(5,7) emitter.Speed=NumberRange.new(S.snowSpeed*0.75,S.snowSpeed*1.25)
	emitter.Acceleration=Vector3.new(0,-2.5,0) emitter.Drag=0.25 emitter.EmissionDirection=Enum.NormalId.Bottom
	emitter.SpreadAngle=Vector2.new(8,8) emitter.Rotation=NumberRange.new(0,360) emitter.RotSpeed=NumberRange.new(-25,25)
	emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.12),NumberSequenceKeypoint.new(0.5,0.2),NumberSequenceKeypoint.new(1,0.08)})
	emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(0.8,0.25),NumberSequenceKeypoint.new(1,1)})
	pcall(function() emitter.Shape=Enum.ParticleEmitterShape.Box emitter.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume end)
	local char=plr.Character local hrp=char and char:FindFirstChild("HumanoidRootPart")
	if hrp then source.CFrame=CFrame.new(hrp.Position+Vector3.new(0,28,0)) end
end
function getVisibleEnergyColor(color)
	local peak=math.max(color.R,color.G,color.B)
	if peak<0.18 then
		local lift=0.18-peak
		return Color3.new(math.clamp(color.R+lift,0,1),math.clamp(color.G+lift,0,1),math.clamp(color.B+lift,0,1))
	end
	return color
end
function removeCelestialSigil()
	local model=workspace:FindFirstChild("KamidereCelestialSigil_"..plr.UserId)
	if model then model:Destroy() end
end
function addSigilRing(model,index,radiusFactor,segments,spin,widthFactor)
	local anchor=Instance.new("Part",model) anchor.Name="SigilRing"..index
	anchor.Anchored=true anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.Transparency=1 anchor.Size=Vector3.new(1,0.05,1)
	anchor:SetAttribute("Spin",spin) anchor:SetAttribute("RadiusFactor",radiusFactor) anchor:SetAttribute("WidthFactor",widthFactor)
	local attachments={}
	for i=1,segments do
		local angle=((i-1)/segments)*math.pi*2
		local attachment=Instance.new("Attachment",anchor) attachment.Name="RingPoint"
		attachment:SetAttribute("Theta",angle) table.insert(attachments,attachment)
	end
	for i=1,segments do
		local beam=Instance.new("Beam",anchor) beam.Name="SigilBeam"
		beam.Attachment0=attachments[i] beam.Attachment1=attachments[(i%segments)+1]
		beam.FaceCamera=true beam.Segments=1 beam.LightEmission=1 beam.Brightness=3
		beam.Color=ColorSequence.new(S.celestialSigilColor) beam.Width0=0.055 beam.Width1=0.055
		beam.Transparency=NumberSequence.new(0.12)
	end
end
function createCelestialSigil()
	removeCelestialSigil()
	local model=Instance.new("Model",workspace) model.Name="KamidereCelestialSigil_"..plr.UserId
	local center=Instance.new("Part",model) center.Name="SigilCenter"
	center.Anchored=true center.CanCollide=false center.CanTouch=false center.CanQuery=false center.Transparency=1 center.Size=Vector3.new(1,0.05,1)
	model.PrimaryPart=center
	addSigilRing(model,1,0.45,24,0.42,0.8)
	addSigilRing(model,2,0.72,28,-0.25,1)
	addSigilRing(model,3,1,32,0.14,1.25)
	local spokeAnchor=Instance.new("Part",model) spokeAnchor.Name="SigilSpokes"
	spokeAnchor.Anchored=true spokeAnchor.CanCollide=false spokeAnchor.CanTouch=false spokeAnchor.CanQuery=false spokeAnchor.Transparency=1 spokeAnchor.Size=Vector3.new(1,0.05,1)
	for i=1,12 do
		local angle=((i-1)/12)*math.pi*2
		local inner=Instance.new("Attachment",spokeAnchor) inner.Name="SpokeInner" inner:SetAttribute("Theta",angle) inner:SetAttribute("RadiusFactor",0.18)
		local outer=Instance.new("Attachment",spokeAnchor) outer.Name="SpokeOuter" outer:SetAttribute("Theta",angle) outer:SetAttribute("RadiusFactor",0.88)
		local beam=Instance.new("Beam",spokeAnchor) beam.Name="SigilBeam" beam.Attachment0=inner beam.Attachment1=outer
		beam.FaceCamera=true beam.LightEmission=1 beam.Brightness=2 beam.Width0=0.025 beam.Width1=0.055
		beam.Color=ColorSequence.new(S.celestialSigilColor) beam.Transparency=NumberSequence.new(0.3)
	end
	for i=1,12 do
		local rune=Instance.new("Part",model) rune.Name="SigilRune" rune.Anchored=true rune.CanCollide=false rune.CanTouch=false rune.CanQuery=false
		rune.Material=Enum.Material.Neon rune.Color=S.celestialSigilColor rune.Size=Vector3.new(0.08,0.035,0.46)
		rune:SetAttribute("Theta",((i-1)/12)*math.pi*2) rune:SetAttribute("Phase",i*0.63)
	end
	for i=1,8 do
		local node=Instance.new("Part",model) node.Name="SigilNode" node.Anchored=true node.CanCollide=false node.CanTouch=false node.CanQuery=false
		node.Shape=Enum.PartType.Ball node.Material=Enum.Material.Neon node.Color=S.celestialSigilColor node.Size=Vector3.new(0.14,0.14,0.14)
		node:SetAttribute("Theta",((i-1)/8)*math.pi*2) node:SetAttribute("Phase",i*0.77)
	end
	local light=Instance.new("PointLight",center) light.Name="SigilLight" light.Color=S.celestialSigilColor light.Brightness=2 light.Range=12 light.Shadows=false
	local sparks=Instance.new("ParticleEmitter",center) sparks.Name="SigilSparks"
	sparks.Texture="rbxasset://textures/particles/sparkles_main.dds" sparks.Color=ColorSequence.new(S.celestialSigilColor)
	sparks.Rate=12 sparks.Lifetime=NumberRange.new(0.7,1.3) sparks.Speed=NumberRange.new(0.5,1.7) sparks.Acceleration=Vector3.new(0,1.5,0)
	sparks.SpreadAngle=Vector2.new(180,180) sparks.LightEmission=1 sparks.LightInfluence=0
	sparks.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.16),NumberSequenceKeypoint.new(1,0)})
	sparks.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,1)})
end
function updateCelestialSigil(dt,char)
	if not S.celestialSigil or not char then removeCelestialSigil() return end
	local model=workspace:FindFirstChild("KamidereCelestialSigil_"..plr.UserId)
	if not model then createCelestialSigil() model=workspace:FindFirstChild("KamidereCelestialSigil_"..plr.UserId) end
	if not model then return end
	local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={char,model}
	local hit=workspace:Raycast(hrp.Position+Vector3.new(0,3,0),Vector3.new(0,-35,0),params)
	local ground=hit and hit.Position or (hrp.Position-Vector3.new(0,3,0))
	local now=os.clock() local size=S.celestialSigilSize local intensity=S.celestialSigilIntensity
	local base=CFrame.new(ground+Vector3.new(0,0.07,0))
	local center=model:FindFirstChild("SigilCenter") if center then center.CFrame=base end
	for _,object in ipairs(model:GetChildren()) do
		if object:IsA("BasePart") and object.Name:match("^SigilRing") then
			local spin=object:GetAttribute("Spin") or 0 local radius=(object:GetAttribute("RadiusFactor") or 1)*size
			object.CFrame=base*CFrame.Angles(0,now*spin,0)
			for _,attachment in ipairs(object:GetChildren()) do
				if attachment:IsA("Attachment") then local theta=attachment:GetAttribute("Theta") or 0 attachment.Position=Vector3.new(math.cos(theta)*radius,0,math.sin(theta)*radius) end
			end
		elseif object.Name=="SigilSpokes" then
			object.CFrame=base*CFrame.Angles(0,-now*0.1,0)
			for _,attachment in ipairs(object:GetChildren()) do
				if attachment:IsA("Attachment") then local theta=attachment:GetAttribute("Theta") or 0 local radius=(attachment:GetAttribute("RadiusFactor") or 1)*size attachment.Position=Vector3.new(math.cos(theta)*radius,0,math.sin(theta)*radius) end
			end
		elseif object.Name=="SigilRune" then
			local theta=(object:GetAttribute("Theta") or 0)+now*0.18 local phase=object:GetAttribute("Phase") or 0 local radius=size*0.82
			local pulse=0.75+math.sin(now*2.4+phase)*0.25
			object.CFrame=base*CFrame.Angles(0,-theta,0)*CFrame.new(radius,0.025,0)*CFrame.Angles(0,math.pi/4,0)
			object.Color=S.celestialSigilColor object.Material=Enum.Material.Neon object.Transparency=math.clamp(0.08+(1-pulse)*0.35,0,0.7)
			object.Size=Vector3.new(0.07*intensity,0.03,0.42+0.16*pulse)
		elseif object.Name=="SigilNode" then
			local theta=(object:GetAttribute("Theta") or 0)-now*0.55 local phase=object:GetAttribute("Phase") or 0 local radius=size*(0.58+math.sin(now*1.7+phase)*0.05)
			local height=0.12+math.sin(now*2+phase)*0.1
			object.CFrame=base*CFrame.new(math.cos(theta)*radius,height,math.sin(theta)*radius)
			object.Color=S.celestialSigilColor object.Material=Enum.Material.Neon object.Size=Vector3.new(0.12,0.12,0.12)*(0.8+0.3*intensity)
		end
	end
	local darkSigil=math.max(S.celestialSigilColor.R,S.celestialSigilColor.G,S.celestialSigilColor.B)<0.06
	for _,desc in ipairs(model:GetDescendants()) do
		if desc:IsA("Beam") then
			desc.Color=ColorSequence.new(S.celestialSigilColor) desc.Brightness=darkSigil and 0 or (2+intensity*2) desc.LightEmission=darkSigil and 0 or 1
			desc.Transparency=NumberSequence.new(darkSigil and 0.015 or math.clamp(0.28-intensity*0.1,0.04,0.35))
		elseif desc:IsA("PointLight") then desc.Color=S.celestialSigilColor desc.Brightness=darkSigil and 0 or (1.5+intensity*1.5) desc.Range=size*2.4
		elseif desc:IsA("ParticleEmitter") then desc.Color=ColorSequence.new(S.celestialSigilColor) desc.LightEmission=darkSigil and 0 or 1 desc.Rate=math.floor(8+intensity*10)
		elseif desc:IsA("BasePart") and (desc.Name=="SigilRune" or desc.Name=="SigilNode") then desc.Color=S.celestialSigilColor desc.Material=Enum.Material.Neon
		end
	end
end
function removeCelestialWings()
	local model=workspace:FindFirstChild("KamidereCelestialWings_"..plr.UserId)
	if model then model:Destroy() end
end
function wingFeatherCFrame(root,tip)
	local direction=tip-root
	if direction.Magnitude<0.001 then return CFrame.new(root) end
	local yAxis=direction.Unit local xAxis=yAxis:Cross(Vector3.new(0,0,1))
	if xAxis.Magnitude<0.001 then xAxis=Vector3.new(1,0,0) else xAxis=xAxis.Unit end
	local zAxis=xAxis:Cross(yAxis).Unit
	return CFrame.fromMatrix((root+tip)*0.5,xAxis,yAxis,zAxis)
end
function createCelestialWings()
	removeCelestialWings()
	local model=Instance.new("Model",workspace) model.Name="KamidereCelestialWings_"..plr.UserId
	for _,side in ipairs({-1,1}) do
		local core=Instance.new("Part",model) core.Name=side<0 and "LeftWingCore" or "RightWingCore"
		core.Anchored=true core.CanCollide=false core.CanTouch=false core.CanQuery=false core.Transparency=1 core.Size=Vector3.new(0.3,0.3,0.3) core:SetAttribute("Side",side)
		for layer,count in ipairs({12,10,8}) do
			for i=1,count do
				local feather=Instance.new("Part",model) feather.Name="AngelFeather"
				feather.Anchored=true feather.CanCollide=false feather.CanTouch=false feather.CanQuery=false feather.CastShadow=false
				feather.Material=Enum.Material.Neon feather.Size=Vector3.new(1,1,1)
				feather:SetAttribute("Side",side) feather:SetAttribute("Layer",layer) feather:SetAttribute("Index",i) feather:SetAttribute("Count",count) feather:SetAttribute("Phase",i*0.37+layer*0.81+side)
				local mesh=Instance.new("SpecialMesh",feather) mesh.Name="FeatherMesh" mesh.MeshType=Enum.MeshType.Sphere mesh.Scale=Vector3.new(0.25,1,0.12)
			end
		end
		local light=Instance.new("PointLight",core) light.Name="WingLight" light.Shadows=false light.Brightness=1.5 light.Range=8
		local sparks=Instance.new("ParticleEmitter",core) sparks.Name="WingSparks" sparks.Texture="rbxasset://textures/particles/sparkles_main.dds"
		sparks.Rate=7 sparks.Lifetime=NumberRange.new(0.6,1.2) sparks.Speed=NumberRange.new(0.08,0.5) sparks.SpreadAngle=Vector2.new(120,120) sparks.LightEmission=1 sparks.LightInfluence=0
		sparks.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,0)}) sparks.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.18),NumberSequenceKeypoint.new(1,1)})
	end
	local outline=Instance.new("Highlight",model) outline.Name="WingSoftOutline" outline.Adornee=model outline.DepthMode=Enum.HighlightDepthMode.Occluded outline.FillTransparency=1 outline.OutlineTransparency=0.75
end
function updateCelestialWings(dt,char)
	if not S.celestialWings or not char then removeCelestialWings() return end
	local model=workspace:FindFirstChild("KamidereCelestialWings_"..plr.UserId)
	if not model then createCelestialWings() model=workspace:FindFirstChild("KamidereCelestialWings_"..plr.UserId) end
	if not model then return end
	local torso=char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") if not torso then return end
	local now=os.clock() local size=S.celestialWingsSize local intensity=S.celestialWingsIntensity local color=getVisibleEnergyColor(S.celestialWingsColor)
	local base=torso.CFrame*CFrame.new(0,0,0.52)
	local firstPersonHidden=isFirstPersonCamera()
	for _,object in ipairs(model:GetChildren()) do
		if object.Name=="AngelFeather" then
			local side=object:GetAttribute("Side") or 1 local layer=object:GetAttribute("Layer") or 1 local index=object:GetAttribute("Index") or 1 local count=object:GetAttribute("Count") or 1
			local progress=count>1 and (index-1)/(count-1) or 0 local phase=object:GetAttribute("Phase") or 0
			local rootX,rootY,tipX,tipY,width
			if layer==1 then
				rootX=0.24+0.16*progress rootY=0.25+0.16*progress tipX=1.05+2.45*progress tipY=2.95-2.0*progress width=0.2+0.08*(1-progress)
			elseif layer==2 then
				rootX=0.28+0.18*progress rootY=0.12-0.12*progress tipX=0.82+2.0*progress tipY=2.12-1.65*progress width=0.27+0.06*(1-progress)
			else
				rootX=0.3+0.16*progress rootY=-0.02-0.22*progress tipX=0.68+1.55*progress tipY=1.42-1.34*progress width=0.31+0.07*(1-progress)
			end
			local root=Vector3.new(side*rootX*size,rootY*size,0)
			local tip=Vector3.new(side*tipX*size,(tipY+math.sin(now*1.8+phase)*0.025)*size,0.08*layer)
			local localFrame=wingFeatherCFrame(root,tip) local flap=math.rad(2.5+math.sin(now*1.7)*2.2)*side
			object.CFrame=base*CFrame.Angles(0,0,flap)*localFrame
			object.Material=Enum.Material.Neon object.Color=color object.Transparency=firstPersonHidden and 1 or math.clamp(0.025+(layer-1)*0.055+(1-intensity)*0.04,0,0.28)
			local mesh=object:FindFirstChild("FeatherMesh")
			if mesh then mesh.Scale=Vector3.new(width*size,(tip-root).Magnitude,math.max(0.1,width*0.42)*size) end
		elseif object.Name=="LeftWingCore" or object.Name=="RightWingCore" then
			local side=object:GetAttribute("Side") or 1 object.CFrame=base*CFrame.new(side*0.34*size,0.32*size,0)
			local light=object:FindFirstChild("WingLight") if light then light.Enabled=not firstPersonHidden light.Color=color light.Brightness=0.8+intensity*1.6 light.Range=5+size*5 end
			local sparks=object:FindFirstChild("WingSparks") if sparks then sparks.Enabled=not firstPersonHidden sparks.Color=ColorSequence.new(color) sparks.Rate=math.floor(4+intensity*8) end
		elseif object:IsA("Highlight") then object.Enabled=not firstPersonHidden object.OutlineColor=color object.OutlineTransparency=math.clamp(0.86-intensity*0.12,0.55,0.9) end
	end
end
function removeEtherealCubes()
	local model=workspace:FindFirstChild("KamidereEtherealCubes_"..plr.UserId)
	if model then model:Destroy() end
end
function createEtherealCubes()
	removeEtherealCubes()
	local model=Instance.new("Model",workspace) model.Name="KamidereEtherealCubes_"..plr.UserId
	local amount=math.floor(S.etherealCubesAmount+0.5) model:SetAttribute("Amount",amount)
	for i=1,amount do
		local cube=Instance.new("Part",model) cube.Name="EtherealCube" cube.Anchored=true cube.CanCollide=false cube.CanTouch=false cube.CanQuery=false cube.CastShadow=false
		local cubeSize=0.65+((i*37)%7)*0.11 cube.Size=Vector3.new(cubeSize,cubeSize,cubeSize) cube.Material=Enum.Material.Glass cube.Transparency=0.92
		cube:SetAttribute("Phase",(i/amount)*math.pi*2) cube:SetAttribute("RadiusScale",0.58+((i*29)%9)/18)
		cube:SetAttribute("Height",2+((i*43)%8)*0.9) cube:SetAttribute("SpeedScale",0.55+((i*17)%11)/12)
		cube:SetAttribute("SpinX",0.35+((i*13)%8)*0.12) cube:SetAttribute("SpinY",0.45+((i*19)%9)*0.13) cube:SetAttribute("SpinZ",0.25+((i*23)%7)*0.11)
		local edge=Instance.new("Highlight",cube) edge.Name="CubeEdge" edge.Adornee=cube edge.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop edge.FillTransparency=1 edge.OutlineTransparency=0.03
		local wire=Instance.new("SelectionBox",cube) wire.Name="CubeWire" wire.Adornee=cube wire.SurfaceTransparency=1 wire.LineThickness=0.035
		local a0=Instance.new("Attachment",cube) a0.Name="TrailA" a0.Position=Vector3.new(-cubeSize*0.32,cubeSize*0.32,0)
		local a1=Instance.new("Attachment",cube) a1.Name="TrailB" a1.Position=Vector3.new(cubeSize*0.32,-cubeSize*0.32,0)
		local trail=Instance.new("Trail",cube) trail.Name="CubeTrail" trail.Attachment0=a0 trail.Attachment1=a1 trail.FaceCamera=true trail.LightEmission=1 trail.Lifetime=1.15 trail.MinLength=0.08
		trail.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(0.45,0.34),NumberSequenceKeypoint.new(1,0)})
		trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.12),NumberSequenceKeypoint.new(0.55,0.45),NumberSequenceKeypoint.new(1,1)})
	end
end
function updateEtherealCubes(dt,char)
	if not S.etherealCubes or not char then removeEtherealCubes() return end
	local model=workspace:FindFirstChild("KamidereEtherealCubes_"..plr.UserId)
	local wanted=math.floor(S.etherealCubesAmount+0.5)
	if not model or model:GetAttribute("Amount")~=wanted then createEtherealCubes() model=workspace:FindFirstChild("KamidereEtherealCubes_"..plr.UserId) end
	if not model then return end
	local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
	local now=os.clock() local color=getVisibleEnergyColor(S.etherealCubesColor) local radius=S.etherealCubesRadius local speed=S.etherealCubesSpeed
	for _,cube in ipairs(model:GetChildren()) do
		if cube:IsA("BasePart") then
			local phase=cube:GetAttribute("Phase") or 0 local radiusScale=cube:GetAttribute("RadiusScale") or 1 local speedScale=cube:GetAttribute("SpeedScale") or 1
			local angle=phase+now*speed*speedScale local distance=radius*radiusScale
			local height=(cube:GetAttribute("Height") or 3)+math.sin(now*(0.8+speedScale)+phase)*2.2
			local position=hrp.Position+Vector3.new(math.cos(angle)*distance,height,math.sin(angle)*distance)
			local rx=now*(cube:GetAttribute("SpinX") or 0.5)*speed local ry=now*(cube:GetAttribute("SpinY") or 0.6)*speed local rz=now*(cube:GetAttribute("SpinZ") or 0.4)*speed
			cube.CFrame=CFrame.new(position)*CFrame.Angles(rx,ry,rz) cube.Color=color cube.Material=Enum.Material.Glass cube.Transparency=0.92
			local edge=cube:FindFirstChild("CubeEdge") if edge then edge.FillTransparency=1 edge.OutlineColor=color edge.OutlineTransparency=0.03 end
			local wire=cube:FindFirstChild("CubeWire") if wire then wire.Color3=color wire.SurfaceColor3=color wire.SurfaceTransparency=1 end
			local trail=cube:FindFirstChild("CubeTrail") if trail then trail.Color=ColorSequence.new(color) trail.Lifetime=0.7+1.1/math.max(speed,0.2) trail.LightEmission=1 end
		end
	end
end
function counterStrikeYaw()
	local look=cam.CFrame.LookVector
	return math.atan2(look.X,-look.Z)
end
function counterStrikeAngleDelta(current,previous)
	local delta=current-previous
	if delta>math.pi then delta=delta-math.pi*2 elseif delta<-math.pi then delta=delta+math.pi*2 end
	return delta
end
function restoreCounterStrikeMovement()
	if counterStrikeHumanoid and counterStrikeHumanoid.Parent then
		if counterStrikeOriginalWalkSpeed~=nil then counterStrikeHumanoid.WalkSpeed=counterStrikeOriginalWalkSpeed end
		if counterStrikeOriginalAutoRotate~=nil then counterStrikeHumanoid.AutoRotate=counterStrikeOriginalAutoRotate end
	end
	counterStrikeHumanoid=nil counterStrikeOriginalWalkSpeed=nil counterStrikeOriginalAutoRotate=nil counterStrikeLastYaw=nil counterStrikeAirVelocity=nil counterStrikeBhopActive=false
end
function updateCounterStrikeMovement(dt)
	if pixelSurfSliding then return end
	if not S.counterStrikeMovement then restoreCounterStrikeMovement() return end
	local char=plr.Character local hum=char and char:FindFirstChildOfClass("Humanoid") local root=char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health<=0 or hum.Sit then restoreCounterStrikeMovement() return end
	if counterStrikeHumanoid~=hum then
		restoreCounterStrikeMovement()
		counterStrikeHumanoid=hum counterStrikeOriginalWalkSpeed=hum.WalkSpeed counterStrikeOriginalAutoRotate=hum.AutoRotate counterStrikeLastYaw=counterStrikeYaw()
	end
	dt=math.min(dt,0.05) hum.AutoRotate=true
	local velocity=root.AssemblyLinearVelocity local measuredHorizontal=Vector3.new(velocity.X,0,velocity.Z)
	local cameraForward=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
	local cameraRight=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)
	if cameraForward.Magnitude>0.001 then cameraForward=cameraForward.Unit else cameraForward=Vector3.new(0,0,-1) end
	if cameraRight.Magnitude>0.001 then cameraRight=cameraRight.Unit else cameraRight=Vector3.new(1,0,0) end
	local currentYaw=counterStrikeYaw() local yawDelta=counterStrikeLastYaw and counterStrikeAngleDelta(currentYaw,counterStrikeLastYaw) or 0 counterStrikeLastYaw=currentYaw
	local typing=UIS:GetFocusedTextBox()~=nil
	local forwardInput=not typing and ((UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0)-(UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0)) or 0
	local sideInput=not typing and ((UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0)-(UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0)) or 0
	local spaceHeld=not typing and UIS:IsKeyDown(Enum.KeyCode.Space)
	local wish=cameraForward*forwardInput+cameraRight*sideInput
	if wish.Magnitude>0.001 then wish=wish.Unit else wish=Vector3.zero end
	local grounded=hum.FloorMaterial~=Enum.Material.Air
	if grounded then
		if spaceHeld then
			local launch=counterStrikeAirVelocity or measuredHorizontal
			if launch.Magnitude<16 and wish.Magnitude>0 then
				local launchDirection=launch.Magnitude>0.5 and launch.Unit or wish
				launch=launchDirection*16
			end
			counterStrikeAirVelocity=launch counterStrikeBhopActive=true hum.WalkSpeed=16
			local jumpVelocity=hum.UseJumpPower and hum.JumpPower or math.sqrt(2*workspace.Gravity*hum.JumpHeight)
			root.AssemblyLinearVelocity=Vector3.new(launch.X,jumpVelocity,launch.Z) hum:ChangeState(Enum.HumanoidStateType.Jumping)
		elseif counterStrikeBhopActive then
			local landing=counterStrikeAirVelocity or measuredHorizontal local speed=landing.Magnitude
			if speed>0.001 then
				local reduced=0
				landing=landing*(reduced/speed) counterStrikeAirVelocity=landing
				root.AssemblyLinearVelocity=Vector3.new(landing.X,velocity.Y,landing.Z) speed=reduced
			end
			hum.WalkSpeed=0 hum:Move(Vector3.zero,false)
			if speed<0.35 then counterStrikeAirVelocity=nil counterStrikeBhopActive=false hum.WalkSpeed=16 end
		else
			counterStrikeAirVelocity=nil hum.WalkSpeed=16
			if wish.Magnitude>0 then hum:Move(wish,false) end
		end
	else
		hum.WalkSpeed=0
		local air=counterStrikeAirVelocity or measuredHorizontal
		if air.Magnitude<1 and forwardInput>0 then air=cameraForward*16 end
		local left=not typing and UIS:IsKeyDown(Enum.KeyCode.A) local right=not typing and UIS:IsKeyDown(Enum.KeyCode.D)
		local validLeft=spaceHeld and left and not right and yawDelta<-0.00005
		local validRight=spaceHeld and right and not left and yawDelta>0.00005
		if validLeft or validRight then
			local speed=math.max(air.Magnitude,16) local currentDirection=air.Magnitude>0.01 and air.Unit or cameraForward
			local turnAlpha=math.clamp(math.abs(yawDelta)*12+S.csAirAcceleration*0.18*dt,0,0.24)
			local turnedDirection=currentDirection:Lerp(cameraForward,turnAlpha)
			if turnedDirection.Magnitude>0.001 then turnedDirection=turnedDirection.Unit else turnedDirection=currentDirection end
			local gainedSpeed=math.min(S.csMaxSpeed,speed+S.csAirAcceleration*6*dt)
			air=turnedDirection*gainedSpeed
		end
		if air.Magnitude>2 then
			local collisionParams=RaycastParams.new() collisionParams.FilterType=Enum.RaycastFilterType.Exclude collisionParams.FilterDescendantsInstances={char}
			local wallHit=workspace:Raycast(root.Position,air.Unit*math.max(1.7,air.Magnitude*dt+1.15),collisionParams)
			if wallHit and wallHit.Instance and wallHit.Instance.CanCollide and math.abs(wallHit.Normal.Y)<0.45 then
				counterStrikeAirVelocity=Vector3.zero counterStrikeBhopActive=false
				root.AssemblyLinearVelocity=Vector3.new(0,math.min(velocity.Y,-4),0)
				return
			end
		end
		counterStrikeAirVelocity=air root.AssemblyLinearVelocity=Vector3.new(air.X,velocity.Y,air.Z)
	end
end
function pixelSurfRayParams(char,root)
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.RespectCanCollide=true params.CollisionGroup=root and root.CollisionGroup or "Default"
	local excluded={char}
	for _,name in ipairs({"KamidereAura_"..plr.UserId,"KamidereCelestialSigil_"..plr.UserId,"KamidereCelestialWings_"..plr.UserId,"KamidereEtherealCubes_"..plr.UserId,"KamidereWorldSnow_"..plr.UserId}) do local object=workspace:FindFirstChild(name) if object then table.insert(excluded,object) end end
	params.FilterDescendantsInstances=excluded return params
end
function isPixelSurfEdge(hit,threshold)
	if not hit or not hit.Instance or not hit.Instance:IsA("BasePart") then return false end
	local part=hit.Instance local localPoint=part.CFrame:PointToObjectSpace(hit.Position) local localNormal=part.CFrame:VectorToObjectSpace(hit.Normal)
	local half=part.Size*0.5 local edgeDistance=math.huge
	if math.abs(localNormal.X)>math.abs(localNormal.Z) then
		edgeDistance=math.min(math.abs(math.abs(localPoint.Y)-half.Y),math.abs(math.abs(localPoint.Z)-half.Z))
	elseif math.abs(localNormal.Z)>0.5 then
		edgeDistance=math.min(math.abs(math.abs(localPoint.Y)-half.Y),math.abs(math.abs(localPoint.X)-half.X))
	else return false end
	return edgeDistance<=(threshold or 1.05)
end
function findPixelSurfWall(char,root)
	local params=pixelSurfRayParams(char,root) local best=nil
	for i=0,15 do
		local angle=(i/16)*math.pi*2 local direction=Vector3.new(math.cos(angle),0,math.sin(angle))
		local hit=workspace:Raycast(root.Position,direction*2.8,params)
		if hit and hit.Instance and hit.Instance.CanCollide and math.abs(hit.Normal.Y)<0.3 and isPixelSurfEdge(hit,1.05) and (not best or hit.Distance<best.Distance) then best=hit end
	end
	return best
end
function playPixelSurfStep(suppressSparkles)
	if not S.pixelSurfSound then return end
	local id=tostring(S.pixelSurfSoundId or ""):gsub("%D","")
	if id=="" then return end
	pcall(function()
		local sound=Instance.new("Sound",SoundService) sound.Name="KamiderePixelSurfStep"
		sound.SoundId="rbxassetid://"..id sound.Volume=0.55 sound:Play()
		Debris:AddItem(sound,8)
	end)
	if S.pixelSurfSparkles and not suppressSparkles then emitMovementSparkles(plr.Character,"KamiderePixelSurfSparkles") end
end
function stopPixelSurf(keepVelocity)
	if pixelSurfSliding then
		local char=plr.Character local root=char and char:FindFirstChild("HumanoidRootPart")
		if keepVelocity and root and pixelSurfDirection then root.AssemblyLinearVelocity=Vector3.new(pixelSurfDirection.X*pixelSurfSpeed,root.AssemblyLinearVelocity.Y,pixelSurfDirection.Z*pixelSurfSpeed) end
	end
	local char=plr.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
	if hum and pixelSurfOriginalWalkSpeed~=nil and not S.counterStrikeMovement then hum.WalkSpeed=pixelSurfOriginalWalkSpeed end
	pixelSurfSliding=false pixelSurfWallNormal=nil pixelSurfDirection=nil pixelSurfSpeed=0 pixelSurfTravel=0 pixelSurfLastPosition=nil pixelSurfOriginalWalkSpeed=nil
end
function beginPixelSurf(char,hum,root,wall)
	local normal=Vector3.new(wall.Normal.X,0,wall.Normal.Z)
	if normal.Magnitude<0.5 then return false end
	normal=normal.Unit
	local horizontal=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z)
	local along=horizontal-normal*horizontal:Dot(normal)
	if along.Magnitude<1 then
		local forward=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
		along=forward-normal*forward:Dot(normal)
	end
	if along.Magnitude<0.1 then along=Vector3.new(0,1,0):Cross(normal) end
	pixelSurfSliding=true pixelSurfHeight=root.Position.Y pixelSurfWallNormal=normal pixelSurfDirection=along.Unit pixelSurfSpeed=math.max(horizontal.Magnitude,10) pixelSurfTravel=0 pixelSurfLastPosition=root.Position pixelSurfOriginalWalkSpeed=hum.WalkSpeed
	playPixelSurfStep()
	hum.WalkSpeed=0 hum:ChangeState(Enum.HumanoidStateType.Freefall)
	return true
end
function updatePixelSurf(dt)
	if not S.pixelSurf or not S.pixelSurfKeyActive then stopPixelSurf(true) return end
	local char=plr.Character local hum=char and char:FindFirstChildOfClass("Humanoid") local root=char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health<=0 then stopPixelSurf(false) return end
	if not pixelSurfSliding then
		if hum.FloorMaterial~=Enum.Material.Air or root.AssemblyLinearVelocity.Y>=-0.5 or os.clock()<pixelSurfCooldown then return end
		local wall=findPixelSurfWall(char,root)
		if not wall or not beginPixelSurf(char,hum,root,wall) then return end
	end
	local params=pixelSurfRayParams(char,root)
	local wall=workspace:Raycast(root.Position,-pixelSurfWallNormal*3.2,params)
	if not wall or not wall.Instance or not wall.Instance.CanCollide or math.abs(wall.Normal.Y)>=0.3 or not isPixelSurfEdge(wall,1.15) then
		pixelSurfCooldown=os.clock()+0.25 stopPixelSurf(true) return
	end
	local normal=Vector3.new(wall.Normal.X,0,wall.Normal.Z)
	if normal.Magnitude<0.5 then pixelSurfCooldown=os.clock()+0.25 stopPixelSurf(true) return end
	normal=normal.Unit pixelSurfWallNormal=normal
	local projected=pixelSurfDirection-normal*pixelSurfDirection:Dot(normal)
	if projected.Magnitude>0.05 then pixelSurfDirection=projected.Unit end
	local obstacle=workspace:Raycast(root.Position,pixelSurfDirection*math.max(1.5,pixelSurfSpeed*dt+1.1),params)
	local blocked=obstacle and obstacle.Instance and obstacle.Instance.CanCollide and math.abs(obstacle.Normal.Y)<0.65
	if not blocked then pixelSurfSpeed=math.min(S.pixelSurfMaxSpeed,pixelSurfSpeed+S.pixelSurfAcceleration*dt) else pixelSurfSpeed=0 end
	local desiredDistance=1.45 local correction=(-normal)*(wall.Distance-desiredDistance)*7
	if blocked then correction=(-normal)*(wall.Distance-desiredDistance)*7 end
	local horizontal=(blocked and Vector3.zero or pixelSurfDirection*pixelSurfSpeed)+correction
	root.CFrame=CFrame.new(root.Position.X,pixelSurfHeight,root.Position.Z)*root.CFrame.Rotation
	root.AssemblyLinearVelocity=Vector3.new(horizontal.X,0,horizontal.Z) hum.WalkSpeed=0
	if S.counterStrikeMovement then counterStrikeAirVelocity=blocked and Vector3.zero or pixelSurfDirection*pixelSurfSpeed end
	local moved=pixelSurfLastPosition and (root.Position-pixelSurfLastPosition).Magnitude or 0 pixelSurfLastPosition=root.Position pixelSurfTravel=pixelSurfTravel+moved
	while pixelSurfTravel>=5 do pixelSurfTravel=pixelSurfTravel-5 playPixelSurfStep() end
end
function removePixelSurfVisualiser()
	local folder=sg:FindFirstChild("KamiderePixelSurfVisualiser")
	if folder then folder:Destroy() end
end
function pixelSurfVisualiserCanCollide(part,root)
	if not part or not part:IsA("BasePart") or not part.CanCollide then return false end
	local groupsCollide=true
	pcall(function() groupsCollide=PhysicsService:CollisionGroupsAreCollidable(part.CollisionGroup,root.CollisionGroup) end)
	return groupsCollide
end
function updatePixelSurfVisualiser()
	if not S.pixelSurfVisualiser then removePixelSurfVisualiser() return end
	if os.clock()<pixelSurfVisualiserNext then
		local folder=sg:FindFirstChild("KamiderePixelSurfVisualiser")
		if folder then for _,box in ipairs(folder:GetChildren()) do if box:IsA("SelectionBox") then box.Color3=S.pixelSurfVisualiserColor box.SurfaceColor3=S.pixelSurfVisualiserColor end end end
		return
	end
	pixelSurfVisualiserNext=os.clock()+0.45 removePixelSurfVisualiser()
	local char=plr.Character local root=char and char:FindFirstChild("HumanoidRootPart") if not root then return end
	local folder=Instance.new("Folder",sg) folder.Name="KamiderePixelSurfVisualiser"
	local params=OverlapParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={char} params.MaxParts=90 params.RespectCanCollide=true params.CollisionGroup=root.CollisionGroup
	local parts=workspace:GetPartBoundsInRadius(root.Position,38,params) local count=0
	for _,part in ipairs(parts) do
		if pixelSurfVisualiserCanCollide(part,root) and part.Transparency<1 and part.Size.Y>=2.5 and math.max(part.Size.X,part.Size.Z)>=2 then
			count=count+1
			local box=Instance.new("SelectionBox",folder) box.Name="SurfableEdges" box.Adornee=part box.Color3=S.pixelSurfVisualiserColor box.SurfaceColor3=S.pixelSurfVisualiserColor box.SurfaceTransparency=1 box.LineThickness=0.035
			if count>=70 then break end
		end
	end
end
function edgeMovementRayParams(char)
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={char} return params
end
function edgeBugSurfaceData(hit)
	if not hit or not hit.Instance or not hit.Instance:IsA("BasePart") or hit.Normal.Y<0.65 then return false,nil end
	local part=hit.Instance local point=part.CFrame:PointToObjectSpace(hit.Position) local half=part.Size*0.5
	local xDistance=math.abs(math.abs(point.X)-half.X) local zDistance=math.abs(math.abs(point.Z)-half.Z)
	local edgeDistance=math.min(xDistance,zDistance)
	if edgeDistance>0.9 then return false,nil end
	local localOut
	if xDistance<zDistance then localOut=Vector3.new(point.X>=0 and 1 or -1,0,0) else localOut=Vector3.new(0,0,point.Z>=0 and 1 or -1) end
	local worldOut=part.CFrame:VectorToWorldSpace(localOut) worldOut=Vector3.new(worldOut.X,0,worldOut.Z)
	return true,worldOut.Magnitude>0.1 and worldOut.Unit or Vector3.new(1,0,0)
end
function playEdgeBugEffect()
	playPixelSurfStep(true)
	if S.edgeBugSparkles then emitMovementSparkles(plr.Character,"KamidereEdgeBugSparkles") end
	local glow=Instance.new("Frame",sg) glow.Name="KamidereEdgeBugGlow" glow.Size=UDim2.fromScale(1,1) glow.BackgroundColor3=Color3.new(1,1,1) glow.BackgroundTransparency=1 glow.BorderSizePixel=0 glow.ZIndex=999
	local stroke=Instance.new("UIStroke",glow) stroke.Color=Color3.new(1,1,1) stroke.Thickness=14 stroke.Transparency=1 stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	local flashIn=TS:Create(glow,TweenInfo.new(0.08,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0.88})
	local edgeIn=TS:Create(stroke,TweenInfo.new(0.08,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=0.05,Thickness=22})
	flashIn:Play() edgeIn:Play()
	task.delay(0.09,function()
		if not glow.Parent then return end
		TS:Create(glow,TweenInfo.new(0.48,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
		TS:Create(stroke,TweenInfo.new(0.48,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Transparency=1,Thickness=8}):Play()
	end)
	Debris:AddItem(glow,0.65)
end
function triggerEdgeBug(hum,root,hit,outward)
	local feetOffset=hum.HipHeight+root.Size.Y*0.5 local horizontal=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z)
	local contactY=hit.Position.Y+feetOffset+0.08 local clearance=math.max(root.Size.X,root.Size.Z)*0.5+0.7
	local outside=hit.Position+outward*clearance
	root.CFrame=CFrame.new(outside.X,contactY,outside.Z)*root.CFrame.Rotation
	local falling=Vector3.new(horizontal.X+outward.X*2.5,-8,horizontal.Z+outward.Z*2.5)
	root.AssemblyLinearVelocity=falling hum:ChangeState(Enum.HumanoidStateType.Freefall)
	counterStrikeAirVelocity=Vector3.new(falling.X,0,falling.Z) edgeBugCooldown=os.clock()+0.7 edgeBugLastTriggered=os.clock()
	task.defer(function()
		if root.Parent and hum.Parent and hum.Health>0 then hum:ChangeState(Enum.HumanoidStateType.Freefall) local velocity=root.AssemblyLinearVelocity root.AssemblyLinearVelocity=Vector3.new(velocity.X,math.min(velocity.Y,-8),velocity.Z) end
	end)
	playEdgeBugEffect()
end
function restoreJumpBug()
	if jumpBugHumanoid and jumpBugHumanoid.Parent then
		if jumpBugOriginalUseJumpPower~=nil then jumpBugHumanoid.UseJumpPower=jumpBugOriginalUseJumpPower end
		if jumpBugOriginalPower~=nil then jumpBugHumanoid.JumpPower=jumpBugOriginalPower end
		if jumpBugOriginalHeight~=nil then jumpBugHumanoid.JumpHeight=jumpBugOriginalHeight end
	end
	jumpBugHumanoid=nil jumpBugOriginalUseJumpPower=nil jumpBugOriginalPower=nil jumpBugOriginalHeight=nil
end
function updateJumpBug()
	if not S.jumpBug or not S.jumpBugKeyActive then restoreJumpBug() return end
	local char=plr.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health<=0 then restoreJumpBug() return end
	if jumpBugHumanoid~=hum then
		restoreJumpBug() jumpBugHumanoid=hum jumpBugOriginalUseJumpPower=hum.UseJumpPower jumpBugOriginalPower=hum.JumpPower jumpBugOriginalHeight=hum.JumpHeight
	end
	if not hum.UseJumpPower then hum.UseJumpPower=true end
	if hum.JumpPower~=S.jumpBugPower then hum.JumpPower=S.jumpBugPower end
end
function updateEdgeMovement(dt)
	if not S.edgeJump and not S.edgeBug then return end
	local char=plr.Character local hum=char and char:FindFirstChildOfClass("Humanoid") local root=char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health<=0 or pixelSurfSliding then edgeJumpHadGround=false return end
	local params=edgeMovementRayParams(char) local velocity=root.AssemblyLinearVelocity local horizontal=Vector3.new(velocity.X,0,velocity.Z)
	local moveDirection=hum.MoveDirection local travel=horizontal.Magnitude>1 and horizontal.Unit or (moveDirection.Magnitude>0.1 and moveDirection.Unit or Vector3.zero)
	local feetOffset=hum.HipHeight+root.Size.Y*0.5 local grounded=hum.FloorMaterial~=Enum.Material.Air
	if S.edgeJump and S.edgeJumpKeyActive and grounded and travel.Magnitude>0 and os.clock()>=edgeJumpCooldown then
		local currentGround=workspace:Raycast(root.Position,Vector3.new(0,-feetOffset-1.1,0),params)
		local aheadOrigin=root.Position+travel*math.max(1.15,horizontal.Magnitude*dt+0.8)
		local aheadGround=workspace:Raycast(aheadOrigin,Vector3.new(0,-feetOffset-1.35,0),params)
		if currentGround and currentGround.Normal.Y>0.55 and not aheadGround then
			local jumpVelocity=hum.UseJumpPower and hum.JumpPower or math.sqrt(2*workspace.Gravity*hum.JumpHeight)
			root.AssemblyLinearVelocity=Vector3.new(velocity.X,jumpVelocity,velocity.Z) hum:ChangeState(Enum.HumanoidStateType.Jumping)
			if S.counterStrikeMovement then counterStrikeAirVelocity=horizontal counterStrikeBhopActive=true end
			edgeJumpCooldown=os.clock()+0.3
		end
	end
	edgeJumpHadGround=grounded
	if not S.edgeBug or not S.edgeBugKeyActive or grounded or velocity.Y>=-2 or os.clock()<edgeBugCooldown then return end
	local predicted=root.Position+horizontal*math.min(dt*1.6,0.08)
	local hit=workspace:Raycast(predicted,Vector3.new(0,-feetOffset-2.2,0),params)
	if not hit then return end
	local feetY=root.Position.Y-feetOffset local distance=feetY-hit.Position.Y
	if distance<-0.08 or distance>math.max(1.25,-velocity.Y*dt+0.55) then return end
	local valid,outward=edgeBugSurfaceData(hit)
	if valid then triggerEdgeBug(hum,root,hit,outward) end
end
function removeRTXEffects()
	for _,name in ipairs({"KamidereRTXColor","KamidereRTXBloom","KamidereRTXSunRays","KamidereRTXAtmosphere","KamidereRTXDepth"}) do
		local effect=Lighting:FindFirstChild(name) if effect then effect:Destroy() end
	end
end
function captureRTXOriginal()
	if rtxOriginal then return end
	rtxOriginal={Brightness=Lighting.Brightness,ExposureCompensation=Lighting.ExposureCompensation,ShadowSoftness=Lighting.ShadowSoftness,EnvironmentDiffuseScale=Lighting.EnvironmentDiffuseScale,EnvironmentSpecularScale=Lighting.EnvironmentSpecularScale,GlobalShadows=Lighting.GlobalShadows,OutdoorAmbient=Lighting.OutdoorAmbient}
	pcall(function() rtxOriginal.Technology=Lighting.Technology end)
end
function updateRTXVisuals()
	if not S.rtx then return end
	captureRTXOriginal()
	local intensity=math.clamp(S.rtxIntensity/100,0,1) local original=rtxOriginal
	pcall(function()
		Lighting.GlobalShadows=true
		Lighting.Brightness=math.clamp(original.Brightness*(1+0.12*intensity),0,10)
		Lighting.ExposureCompensation=original.ExposureCompensation+0.04*intensity
		Lighting.ShadowSoftness=0.42-0.22*intensity
		Lighting.EnvironmentDiffuseScale=math.max(original.EnvironmentDiffuseScale,0.7+0.3*intensity)
		Lighting.EnvironmentSpecularScale=math.max(original.EnvironmentSpecularScale,0.72+0.28*intensity)
		Lighting.OutdoorAmbient=original.OutdoorAmbient:Lerp(Color3.fromRGB(105,112,125),0.16*intensity)
		Lighting.Technology=Enum.Technology.Future
	end)
	local color=Lighting:FindFirstChild("KamidereRTXColor") or Instance.new("ColorCorrectionEffect",Lighting) color.Name="KamidereRTXColor" color.Enabled=true color.Brightness=0.008+0.012*intensity color.Contrast=0.035+0.075*intensity color.Saturation=0.035+0.11*intensity color.TintColor=Color3.fromRGB(255,248+math.floor(5*intensity),242+math.floor(8*intensity))
	local bloom=Lighting:FindFirstChild("KamidereRTXBloom") or Instance.new("BloomEffect",Lighting) bloom.Name="KamidereRTXBloom" bloom.Enabled=true bloom.Intensity=0.08+0.24*intensity bloom.Size=24+16*intensity bloom.Threshold=1.35-0.25*intensity
	local rays=Lighting:FindFirstChild("KamidereRTXSunRays") or Instance.new("SunRaysEffect",Lighting) rays.Name="KamidereRTXSunRays" rays.Enabled=true rays.Intensity=0.015+0.055*intensity rays.Spread=0.72+0.12*intensity
	local atmosphere=Lighting:FindFirstChild("KamidereRTXAtmosphere") or Instance.new("Atmosphere",Lighting) atmosphere.Name="KamidereRTXAtmosphere" atmosphere.Density=0.1+0.08*intensity atmosphere.Offset=0.18 atmosphere.Color=Color3.fromRGB(210,225,245) atmosphere.Decay=Color3.fromRGB(115,125,145) atmosphere.Glare=0.04+0.14*intensity atmosphere.Haze=0.45+0.95*intensity
	local depth=Lighting:FindFirstChild("KamidereRTXDepth") or Instance.new("DepthOfFieldEffect",Lighting) depth.Name="KamidereRTXDepth" depth.Enabled=true depth.FocusDistance=38 depth.InFocusRadius=55 depth.NearIntensity=0.005+0.015*intensity depth.FarIntensity=0.018+0.052*intensity
end
function setRTXEnabled(enabled)
	if enabled then captureRTXOriginal() removeRTXEffects() updateRTXVisuals() return end
	removeRTXEffects()
	if rtxOriginal then
		pcall(function()
			Lighting.Brightness=rtxOriginal.Brightness Lighting.ExposureCompensation=rtxOriginal.ExposureCompensation Lighting.ShadowSoftness=rtxOriginal.ShadowSoftness Lighting.EnvironmentDiffuseScale=rtxOriginal.EnvironmentDiffuseScale Lighting.EnvironmentSpecularScale=rtxOriginal.EnvironmentSpecularScale Lighting.GlobalShadows=rtxOriginal.GlobalShadows Lighting.OutdoorAmbient=rtxOriginal.OutdoorAmbient
			if rtxOriginal.Technology then Lighting.Technology=rtxOriginal.Technology end
		end)
	end
	rtxOriginal=nil
end
function createSongPlayer()
	removeScreenObject("KamidereSongWindow")
	local frame=Instance.new("Frame",sg) frame.Name="KamidereSongWindow"
	frame.Size=UDim2.new(0,280,0,158) frame.Position=UDim2.new(0.5,-140,0,18)
	frame.BackgroundColor3=C("bg") frame.BackgroundTransparency=0.04 frame.BorderSizePixel=0
	frame.Active=true frame.Draggable=true frame.ZIndex=600
	Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
	local stroke=Instance.new("UIStroke",frame) stroke.Color=C("border") stroke.Transparency=0.1
	local title=Instance.new("TextLabel",frame) title.Size=UDim2.new(1,-20,0,28) title.Position=UDim2.new(0,10,0,4)
	title.BackgroundTransparency=1 title.Text="Song Player" title.TextColor3=C("text") title.TextSize=14 title.Font=Enum.Font.GothamBold title.ZIndex=601
	local songName=Instance.new("TextLabel",frame) songName.Name="SongName"
	songName.Size=UDim2.new(1,-20,0,22) songName.Position=UDim2.new(0,10,0,32)
	songName.BackgroundTransparency=1 songName.Text="No song selected" songName.TextColor3=C("dim")
	songName.TextSize=10 songName.TextTruncate=Enum.TextTruncate.AtEnd songName.Font=Enum.Font.Gotham songName.ZIndex=601
	local box=Instance.new("TextBox",frame) box.Name="SongIdBox"
	box.Size=UDim2.new(1,-24,0,32) box.Position=UDim2.new(0,12,0,60)
	box.BackgroundColor3=C("card") box.BorderSizePixel=0 box.Text=S.songId or "" box.PlaceholderText="Enter song ID"
	box.TextColor3=C("text") box.PlaceholderColor3=C("dim") box.TextSize=12 box.Font=Enum.Font.Gotham box.ClearTextOnFocus=false box.ZIndex=601
	Instance.new("UICorner",box).CornerRadius=UDim.new(0,6)
	local play=Instance.new("TextButton",frame) play.Name="PlayButton"
	play.Size=UDim2.new(1,-24,0,36) play.Position=UDim2.new(0,12,0,104)
	play.BackgroundColor3=C("on") play.BorderSizePixel=0 play.Text=songSound.Playing and "Stop" or "Play"
	play.TextColor3=Color3.new(1,1,1) play.TextSize=13 play.Font=Enum.Font.GothamBold play.ZIndex=601
	Instance.new("UICorner",play).CornerRadius=UDim.new(0,7)
	box.FocusLost:Connect(function() S.songId=box.Text:gsub("%D","") box.Text=S.songId end)
	play.MouseButton1Click:Connect(function()
		if songSound.Playing then songSound:Stop() play.Text="Play" return end
		S.songId=box.Text:gsub("%D","") box.Text=S.songId
		if S.songId=="" then songName.Text="Enter a valid song ID" return end
		songSound.SoundId="rbxassetid://"..S.songId
		songName.Text="Loading..."
		task.spawn(function()
			local ok,info=pcall(function() return MarketplaceService:GetProductInfo(tonumber(S.songId),Enum.InfoType.Asset) end)
			if songName.Parent then songName.Text=ok and info and info.Name or ("Audio "..S.songId) end
		end)
		local ok=pcall(function() songSound:Play() end)
		play.Text=ok and "Stop" or "Play"
	end)
	songSound.Ended:Connect(function() if play.Parent then play.Text="Play" end end)
	onTC(function()
		if frame.Parent then frame.BackgroundColor3=C("bg") stroke.Color=C("border") title.TextColor3=C("text") songName.TextColor3=C("dim") box.BackgroundColor3=C("card") box.TextColor3=C("text") play.BackgroundColor3=C("on") end
	end)
end
function emitMovementSparkles(char,effectName)
	if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
	if not root then return end
	local source=Instance.new("Part",workspace) source.Name=effectName or "KamidereMovementSparkles"
	source.Anchored=true source.CanCollide=false source.CanTouch=false source.CanQuery=false source.Transparency=1 source.Size=Vector3.new(S.deathSparklesRadius*2,S.deathSparklesRadius*2,S.deathSparklesRadius*2) source.CFrame=root.CFrame
	local emitter=Instance.new("ParticleEmitter",source)
	emitter.Texture="rbxasset://textures/particles/sparkles_main.dds" emitter.Color=ColorSequence.new(S.sparklesColor)
	emitter.LightEmission=1 emitter.LightInfluence=0 emitter.Lifetime=NumberRange.new(1.2,2.4)
	emitter.Speed=NumberRange.new(S.deathSparklesSpeed*0.6,S.deathSparklesSpeed*1.45) emitter.Drag=2 emitter.Acceleration=Vector3.new(0,-28,0)
	emitter.SpreadAngle=Vector2.new(180,180) emitter.Rotation=NumberRange.new(0,360) emitter.RotSpeed=NumberRange.new(-180,180)
	emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.35),NumberSequenceKeypoint.new(0.65,0.16),NumberSequenceKeypoint.new(1,0)})
	emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.72,0.15),NumberSequenceKeypoint.new(1,1)})
	pcall(function() emitter.Shape=Enum.ParticleEmitterShape.Sphere emitter.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume end)
	emitter.Rate=0 emitter:Emit(math.floor(S.deathSparklesAmount+0.5)) Debris:AddItem(source,3)
end
function emitDeathSparkles(char)
	if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
	if not root then return end
	char:SetAttribute("KamidereDeathHidden",true)
	for _,object in ipairs(char:GetDescendants()) do
		if object:IsA("BasePart") then
			if transparencyOriginals[object]==nil then transparencyOriginals[object]=object.LocalTransparencyModifier end
			object.LocalTransparencyModifier=1
		elseif object:IsA("Decal") or object:IsA("Texture") then object.Transparency=1
		elseif object:IsA("ParticleEmitter") or object:IsA("Trail") then object.Enabled=false end
	end
	local source=Instance.new("Part",workspace) source.Name="KamidereDeathSparkles"
	source.Anchored=true source.CanCollide=false source.CanTouch=false source.CanQuery=false source.Transparency=1 source.Size=Vector3.new(S.deathSparklesRadius*2,S.deathSparklesRadius*2,S.deathSparklesRadius*2) source.CFrame=root.CFrame
	local emitter=Instance.new("ParticleEmitter",source)
	emitter.Texture="rbxasset://textures/particles/sparkles_main.dds" emitter.Color=ColorSequence.new(S.sparklesColor)
	emitter.LightEmission=1 emitter.LightInfluence=0 emitter.Lifetime=NumberRange.new(1.2,2.4)
	emitter.Speed=NumberRange.new(S.deathSparklesSpeed*0.6,S.deathSparklesSpeed*1.45) emitter.Drag=2 emitter.Acceleration=Vector3.new(0,-28,0)
	emitter.SpreadAngle=Vector2.new(180,180) emitter.Rotation=NumberRange.new(0,360) emitter.RotSpeed=NumberRange.new(-180,180)
	emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.35),NumberSequenceKeypoint.new(0.65,0.16),NumberSequenceKeypoint.new(1,0)})
	emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.72,0.15),NumberSequenceKeypoint.new(1,1)})
	pcall(function() emitter.Shape=Enum.ParticleEmitterShape.Sphere emitter.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume end)
	emitter.Rate=0 emitter:Emit(math.floor(S.deathSparklesAmount+0.5)) Debris:AddItem(source,3)
end
function bindDeathPlayer(player)
	if deathWatchConnections[player] then return end
	local bundle={}
	local function bindCharacter(char)
		char:SetAttribute("KamidereDeathHidden",false)
		local hum=char:WaitForChild("Humanoid",8)
		if hum then table.insert(bundle,hum.Died:Connect(function()
			local enabled=(player==plr and S.selfDeathSparkles) or (player~=plr and S.deathSparkles)
			if enabled then emitDeathSparkles(char) end
		end)) end
	end
	table.insert(bundle,player.CharacterAdded:Connect(bindCharacter))
	if player.Character then task.spawn(bindCharacter,player.Character) end
	deathWatchConnections[player]=bundle
end
for _,player in ipairs(Players:GetPlayers()) do bindDeathPlayer(player) end
Players.PlayerAdded:Connect(bindDeathPlayer)
registerConfigControl("Song ID",{kind="text",get=function() return S.songId end,set=function(value)
	S.songId=tostring(value or ""):gsub("%D","")
	local window=sg:FindFirstChild("KamidereSongWindow") local box=window and window:FindFirstChild("SongIdBox")
	if box then box.Text=S.songId end
end})
-- ============================================================
-- MAIN TAB
-- ============================================================
local mainTab=tabColumns["main"].left
mkSection(mainTab,"Aimbot")
mkToggle(mainTab,"Aimbot",false,function(v)
	S.aimbotOn=v if not v then S.aimbotTarget=nil S.aimbotKeyActive=false aimbotRespawnTarget=nil aimbotCachedTarget=nil aimbotCachedPoint=nil end
end)
mkKeybind(mainTab,"Aimbot Keybind",function(k) S.aimbotKey=k end,function(m)
	S.aimbotKeyMode=m
	S.aimbotKeyActive=(m=="always on" and S.aimbotOn) or false
	if not S.aimbotKeyActive then S.aimbotTarget=nil aimbotRespawnTarget=nil aimbotCachedTarget=nil aimbotCachedPoint=nil end
end)
-- Multi-hitbox for aimbot
mkMultiSelect(mainTab,"Aim Target Parts",ALL_PARTS,{"Head"},function(v) S.aimbotParts=v end)
mkSlider(mainTab,"Smooth (0=instant)",0,20,0,0.5,function(v) S.aimbotSmooth=v end)
mkToggle(mainTab,"Aim FOV",false,function(v) S.aimbotFOV=v end)
mkRGB(mainTab,"Aim FOV Color",Color3.fromRGB(255,255,255),function(c) S.aimbotFOVcolor=c end)
mkSlider(mainTab,"FOV Radius",20,600,100,5,function(v) S.aimbotFOVval=v end)
mainTab=tabColumns["main"].right
mkSection(mainTab,"Triggerbot")
mkToggle(mainTab,"Trigger Bot",false,function(v)
	S.trigOn=v if not v then S.trigActive=false S.trigKeyActive=false end
end)
mkKeybind(mainTab,"Trigger Keybind",function(k) S.trigKey=k end,function(m)
	S.trigKeyMode=m
	S.trigKeyActive=(m=="always on" and S.trigOn) or false
end)
mkToggle(mainTab,"Trigger Reaction",false,function(v) S.trigReaction=v end)
mkSlider(mainTab,"Reaction Delay (ms)",0,1000,0,10,function(v) S.trigReactionMs=v end)
-- Multi-hitbox for trigger
mkMultiSelect(mainTab,"Trigger Target Parts",ALL_PARTS,{"Head"},function(v) S.trigParts=v end)
mkToggle(mainTab,"Trigger Speed",false,function(v) S.trigSpeedOn=v end)
mkSlider(mainTab,"Speed Delay (ms)",1,1000,100,1,function(v) S.trigSpeedMs=v end)
mkSection(mainTab,"Target Filter")
mkToggle(mainTab,"Use Target List",false,function(v) S.useTargetList=v end)
mkButton(mainTab,"Target List ▸",function()
	refreshTargetList()
	targetListPanel.Visible=true
end)
-- ============================================================
-- VISUALS TAB
-- ============================================================
local visTab=tabColumns["visuals"].left
mkSection(visTab,"Cosmetics")
mkToggle(visTab,"China Hat",false,function(v)
	S.chinaHat=v
	if not v then local c=getChar() if c then local h=c:FindFirstChild("ConeHat") if h then h:Destroy() end end end
end)
mkRGB(visTab,"China Hat Color",Color3.fromRGB(255,200,50),function(c) S.chinaColor=c end)
mkSlider(visTab,"China Hat Transparency",0,1,0.3,0.05,function(v) S.chinaTransparency=v end)
mkToggle(visTab,"Aura",false,function(v)
	S.aura=v
	if not v then local a=workspace:FindFirstChild("KamidereAura_"..plr.UserId) if a then a:Destroy() end end
end)
mkRGB(visTab,"Aura Color",Color3.fromRGB(0,150,255),function(c) S.auraColor=c end)
mkToggle(visTab,"Motion Trail",false,function(v)
	S.motionTrail=v
	if not v then
		local c=getChar() if not c then return end
		for _,object in ipairs(c:GetDescendants()) do
			if object.Name=="KamidereTrail" or object.Name=="TrailA0" or object.Name=="TrailA1" then object:Destroy() end
		end
	end
end)
mkRGB(visTab,"Trail Color",Color3.fromRGB(74,145,224),function(c)
	S.motionTrailColor=c
	local ch=getChar() if not ch then return end
	local t=ch:FindFirstChild("KamidereTrail",true)
	if t then t.Color=ColorSequence.new(c) end
end)
mkSection(visTab,"Player ESP")
mkToggle(visTab,"Box ESP",false,function(v) S.boxESP=v end)
mkRGB(visTab,"Box Color",Color3.fromRGB(255,50,50),function(c) S.boxColor=c end)
mkToggle(visTab,"Name ESP",false,function(v) S.nameESP=v end)
mkRGB(visTab,"Name Color",Color3.fromRGB(255,255,255),function(c) S.nameColor=c end)
mkToggle(visTab,"Health ESP",false,function(v) S.healthESP=v end)
mkToggle(visTab,"Tool ESP",false,function(v) S.toolESP=v end)
mkRGB(visTab,"Tool Color",Color3.fromRGB(255,255,255),function(c) S.toolColor=c end)
mkToggle(visTab,"Chams",false,function(v) S.chams=v end)
mkRGB(visTab,"Chams Color",Color3.fromRGB(255,50,50),function(c) S.chamsColor=c end)
mkSlider(visTab,"Chams Transparency",0,1,0.3,0.05,function(v) S.chamsAlpha=v end)
mkToggle(visTab,"Forcefield Indicator",false,function(v) S.ffIndicator=v end)
mkSection(visTab,"Death Effects")
mkToggle(visTab,"Death Sparkles",false,function(v) S.deathSparkles=v end)
mkToggle(visTab,"Self Death Sparkles",false,function(v) S.selfDeathSparkles=v end)
mkRGB(visTab,"Sparkles Color",Color3.fromRGB(255,180,50),function(c) S.sparklesColor=c end)
mkSlider(visTab,"Death Sparkles Amount",10,300,125,5,function(v) S.deathSparklesAmount=v end)
mkSlider(visTab,"Death Sparkles Radius",0.5,8,1,0.5,function(v) S.deathSparklesRadius=v end)
mkSlider(visTab,"Death Sparkles Speed",1,30,15,1,function(v) S.deathSparklesSpeed=v end)
mkSection(visTab,"Transparency")
mkSlider(visTab,"Player Transparency",0,1,0,0.05,function(v) S.playerTransparency=v end)
mkSlider(visTab,"Self Player Transparency",0,1,0,0.05,function(v) S.selfPlayerTransparency=v end)
visTab=tabColumns["visuals"].right
mkSection(visTab,"World")
mkToggle(visTab,"RTX",false,function(v) S.rtx=v setRTXEnabled(v) end)
mkSlider(visTab,"RTX Intensity",0,100,70,5,function(v) S.rtxIntensity=v if S.rtx then updateRTXVisuals() end end)
mkToggle(visTab,"Fullbright",false,function(v)
	S.fullbright=v
	if v then S.origLight.Ambient=Lighting.Ambient S.origLight.CSB=Lighting.ColorShift_Bottom S.origLight.CST=Lighting.ColorShift_Top
	else
		Lighting.Ambient=S.origLight.Ambient or Color3.fromRGB(0,0,0)
		Lighting.ColorShift_Bottom=S.origLight.CSB or Color3.fromRGB(0,0,0)
		Lighting.ColorShift_Top=S.origLight.CST or Color3.fromRGB(0,0,0)
	end
end)
mkSlider(visTab,"Brightness %",0,100,100,1,function(v) S.fbAmt=v end)
mkToggle(visTab,"World Color",false,function(v)
	if v and not S.worldColor then
		S.worldOrig={Ambient=Lighting.Ambient,CSB=Lighting.ColorShift_Bottom,CST=Lighting.ColorShift_Top}
	end
	S.worldColor=v
	if not v then
		local orig=S.worldOrig or {}
		Lighting.Ambient=orig.Ambient or Color3.fromRGB(0,0,0)
		Lighting.ColorShift_Bottom=orig.CSB or Color3.fromRGB(0,0,0)
		Lighting.ColorShift_Top=orig.CST or Color3.fromRGB(0,0,0)
		S.worldOrig={}
	end
end)
mkRGB(visTab,"World Color RGB",Color3.fromRGB(255,50,50),function(c) S.worldColorVal=c end)
mkSlider(visTab,"World Color Intensity",0,100,100,1,function(v) S.worldColorIntensity=v end)
mkToggle(visTab,"Motion Blur",false,function(v)
	S.motionBlur=v
	local ex=Lighting:FindFirstChild("KamidereBlur")
	if v then if not ex then local bl=Instance.new("BlurEffect",Lighting) bl.Name="KamidereBlur" bl.Size=0 end
	else if ex then ex:Destroy() end end
end)
mkSection(visTab,"Camera")
mkSlider(visTab,"FOV",40,120,math.floor(cam.FieldOfView+0.5),1,function(v) S.screenFov=v cam.FieldOfView=v end)
mkToggle(visTab,"Dynamic Camera",false,function(v) S.dynamicCamera=v end)
mkSlider(visTab,"Dynamic Camera Lag",0.01,0.2,0.08,0.01,function(v) S.dynamicCameraStrength=v end)
mkSlider(visTab,"Dynamic Camera Smoothness",1,20,12,1,function(v) S.dynamicCameraSmoothness=v end)
mkSection(visTab,"Crosshair")
mkToggle(visTab,"Custom Crosshair",false,function(v)
	S.customCrosshair=v crosshairAngle=0
	if v then createCrosshair() else removeScreenObject("KamidereCrosshair") end
end)
mkRGB(visTab,"Crosshair Color",Color3.fromRGB(255,255,255),function(c) S.crosshairColor=c end)
mkToggle(visTab,"Crosshair Spin",false,function(v) S.crosshairSpin=v end)
mkSection(visTab,"Viewmodel")
mkToggle(visTab,"Visible Hands",false,function(v)
	S.visibleHands=v destroyFirstPersonViewmodel()
end)
vmXRow,vmYRow,vmZRow=nil,nil,nil
mkToggle(visTab,"Tool Viewmodel",false,function(v)
	S.toolViewmodel=v
	if vmXRow then vmXRow.Visible=v vmYRow.Visible=v vmZRow.Visible=v end
	if not v then restoreToolViewmodel() end
	destroyFirstPersonViewmodel()
end)
vmXRow=mkSlider(visTab,"Viewmodel Right-Left",-2,2,0,0.05,function(v) S.viewmodelX=v end)
vmYRow=mkSlider(visTab,"Viewmodel Up-Down",-2,2,0,0.05,function(v) S.viewmodelY=v end)
vmZRow=mkSlider(visTab,"Viewmodel Back-Forth",-2,2,0,0.05,function(v) S.viewmodelZ=v end)
vmXRow.Visible=false vmYRow.Visible=false vmZRow.Visible=false
mkSlider(visTab,"Tool Viewmodel FOV",40,120,70,1,function(v) S.viewmodelFov=v end)
mkSection(visTab,"Extra Visuals")
mkToggle(visTab,"Celestial Sigil",false,function(v)
	S.celestialSigil=v
	if v then createCelestialSigil() else removeCelestialSigil() end
end)
mkRGB(visTab,"Celestial Sigil Color",Color3.fromRGB(85,170,255),function(c) S.celestialSigilColor=c end)
mkSlider(visTab,"Celestial Sigil Size",3,10,5,0.5,function(v) S.celestialSigilSize=v end)
mkSlider(visTab,"Celestial Sigil Intensity",0.2,2,1,0.1,function(v) S.celestialSigilIntensity=v end)
mkToggle(visTab,"Celestial Wings",false,function(v)
	S.celestialWings=v
	if v then createCelestialWings() else removeCelestialWings() end
end)
mkRGB(visTab,"Celestial Wings Color",Color3.fromRGB(245,248,255),function(c) S.celestialWingsColor=c end)
mkSlider(visTab,"Celestial Wings Size",0.6,1.8,1,0.1,function(v) S.celestialWingsSize=v end)
mkSlider(visTab,"Celestial Wings Intensity",0.2,2,1,0.1,function(v) S.celestialWingsIntensity=v end)
mkToggle(visTab,"Ethereal Cubes",false,function(v)
	S.etherealCubes=v
	if v then createEtherealCubes() else removeEtherealCubes() end
end)
mkRGB(visTab,"Ethereal Cubes Color",Color3.fromRGB(105,180,255),function(c) S.etherealCubesColor=c end)
mkSlider(visTab,"Ethereal Cubes Amount",4,18,10,1,function(v) S.etherealCubesAmount=v end)
mkSlider(visTab,"Ethereal Cubes Radius",8,30,16,1,function(v) S.etherealCubesRadius=v end)
mkSlider(visTab,"Ethereal Cubes Speed",0.2,2,0.8,0.1,function(v) S.etherealCubesSpeed=v end)
mkToggle(visTab,"Snow Particles",false,function(v)
	S.snowParticles=v
	if v then createWorldSnow() else removeWorldSnow() end
end)
mkSlider(visTab,"Snow Amount",10,200,58,1,function(v) S.snowAmount=v end)
mkSlider(visTab,"Snow Radius",8,60,32,1,function(v) S.snowRadius=v end)
mkSlider(visTab,"Snow Speed",1,20,9,1,function(v) S.snowSpeed=v end)
mkSection(visTab,"Self")
mkToggle(visTab,"My Chams",false,function(v) S.myChams=v end)
mkRGB(visTab,"My Chams Color",Color3.fromRGB(100,255,100),function(c) S.myChamsColor=c end)
mkSlider(visTab,"My Chams Transparency",0,1,0.3,0.05,function(v) S.myChamsAlpha=v end)
mkToggle(visTab,"Tool Chams",false,function(v)
	S.toolChams=v
	if not v then
		for _,obj in ipairs(game:GetDescendants()) do
			if obj:IsA("Highlight") and obj.Name=="KamidereToolChams" then obj:Destroy() end
		end
	end
end)
mkRGB(visTab,"Tool Chams Color",Color3.fromRGB(100,200,255),function(c) S.toolChamsColor=c end)
mkSlider(visTab,"Tool Chams Transparency",0,1,0.3,0.05,function(v) S.toolChamsAlpha=v end)
mkSection(visTab,"HUD")
mkToggle(visTab,"ID Player",false,function(v)
	S.idPlayer=v
	if v then createSongPlayer() else songSound:Stop() removeScreenObject("KamidereSongWindow") end
end)
mkToggle(visTab,"Velocity Indicator",false,function(v)
	S.velocityIndicator=v
	if v then createVelocityIndicator() else removeScreenObject("KamidereVelocity") end
end)
mkRGB(visTab,"Velocity Indicator Color",Color3.fromRGB(255,255,255),function(c) S.velocityColor=c end)
mkToggle(visTab,"Watermark",false,function(v)
	S.watermark=v
	local wm=sg:FindFirstChild("KamidereWM")
	if v and not wm then
		local f=Instance.new("Frame",sg) f.Name="KamidereWM"
		f.Size=UDim2.new(0,230,0,28) f.Position=UDim2.new(1,-8,0,8) f.AnchorPoint=Vector2.new(1,0)
		f.BackgroundTransparency=1 f.BorderSizePixel=0 f.Active=true f.Draggable=true f.ZIndex=200
		local logoBox=Instance.new("Frame",f) logoBox.Name="WMLogoBox"
		logoBox.Size=UDim2.new(0,36,0,28) logoBox.BackgroundColor3=C("hudBg") logoBox.BackgroundTransparency=0.04 logoBox.BorderSizePixel=0 logoBox.ZIndex=201
		Instance.new("UICorner",logoBox).CornerRadius=UDim.new(0,8)
		local logoStroke=Instance.new("UIStroke",logoBox) logoStroke.Name="WMLogoStroke" logoStroke.Color=C("border") logoStroke.Transparency=0.12
		local logo=Instance.new("TextLabel",logoBox) logo.Name="WMLogo"
		logo.Size=UDim2.new(1,0,1,0) logo.BackgroundTransparency=1 logo.Text="PH"
		logo.TextColor3=C("on") logo.TextSize=12 logo.Font=Enum.Font.GothamBold logo.ZIndex=202
		local infoBox=Instance.new("Frame",f) infoBox.Name="WMInfoBox"
		infoBox.Size=UDim2.new(0,190,0,28) infoBox.Position=UDim2.new(0,40,0,0)
		infoBox.BackgroundColor3=C("hudBg") infoBox.BackgroundTransparency=0.04 infoBox.BorderSizePixel=0 infoBox.ZIndex=201
		Instance.new("UICorner",infoBox).CornerRadius=UDim.new(0,8)
		local infoStroke=Instance.new("UIStroke",infoBox) infoStroke.Name="WMInfoStroke" infoStroke.Color=C("border") infoStroke.Transparency=0.12
		local wl=Instance.new("TextLabel",f) wl.Name="WML"
		wl.Size=UDim2.new(0,174,0,28) wl.Position=UDim2.new(0,48,0,0)
		wl.BackgroundTransparency=1 wl.RichText=true wl.Text=""
		wl.TextColor3=C("hudText") wl.TextSize=11 wl.Font=Enum.Font.GothamMedium
		wl.TextXAlignment=Enum.TextXAlignment.Left wl.TextTruncate=Enum.TextTruncate.None wl.ZIndex=203
	elseif not v and wm then wm:Destroy() end
end)
mkToggle(visTab,"Hit Logs",false,function(v) S.hitlogs=v end)
mkToggle(visTab,"Target HUD",false,function(v)
	S.targetHUD=v
	local hud=sg:FindFirstChild("KamidereHUD")
	if v and not hud then
		local hf=Instance.new("Frame",sg) hf.Name="KamidereHUD"
		hf.Size=UDim2.new(0,270,0,72) hf.Position=UDim2.new(0.5,-135,1,-90)
		hf.BackgroundColor3=C("hudBg") hf.BackgroundTransparency=0.2 hf.BorderSizePixel=0
		hf.Active=true hf.Draggable=true hf.ZIndex=200
		Instance.new("UICorner",hf).CornerRadius=UDim.new(0,10)
		local av=Instance.new("ImageLabel",hf) av.Name="Avatar"
		av.Size=UDim2.new(0,48,0,48) av.Position=UDim2.new(0,10,0.5,-24)
		av.BackgroundColor3=Color3.fromRGB(20,20,20) av.BorderSizePixel=0 av.ZIndex=201
		Instance.new("UICorner",av).CornerRadius=UDim.new(0,8)
		local dn=Instance.new("TextLabel",hf) dn.Name="DisplayName"
		dn.Size=UDim2.new(1,-72,0,22) dn.Position=UDim2.new(0,64,0,10)
		dn.BackgroundTransparency=1 dn.Text="No target" dn.TextColor3=C("hudText")
		dn.TextSize=14 dn.Font=Enum.Font.GothamBold dn.TextXAlignment=Enum.TextXAlignment.Left dn.ZIndex=201
		local un=Instance.new("TextLabel",hf) un.Name="Username"
		un.Size=UDim2.new(1,-72,0,14) un.Position=UDim2.new(0,64,0,34)
		un.BackgroundTransparency=1 un.Text="" un.TextColor3=C("hudDim")
		un.TextSize=10 un.Font=Enum.Font.Gotham un.TextXAlignment=Enum.TextXAlignment.Left un.ZIndex=201
		local hp=Instance.new("TextLabel",hf) hp.Name="HP"
		hp.Size=UDim2.new(1,-72,0,14) hp.Position=UDim2.new(0,64,0,52)
		hp.BackgroundTransparency=1 hp.Text="" hp.TextColor3=Color3.fromRGB(80,220,80)
		hp.TextSize=11 hp.Font=Enum.Font.GothamMedium hp.TextXAlignment=Enum.TextXAlignment.Left hp.ZIndex=201
	elseif not v and hud then hud:Destroy() end
end)
mkToggle(visTab,"Keybind Indicator",false,function(v)
	S.keybindInd=v
	local ki=sg:FindFirstChild("KamidereKB")
	if v and not ki then
		local kf=Instance.new("Frame",sg) kf.Name="KamidereKB"
		kf.Size=UDim2.new(0,132,0,26) kf.Position=UDim2.new(0,8,0,44)
		kf.BackgroundTransparency=1 kf.BorderSizePixel=0
		kf.Active=true kf.Draggable=true kf.ClipsDescendants=true kf.ZIndex=200
		local headerBG=Instance.new("Frame",kf) headerBG.Name="KBHeaderBG"
		headerBG.Size=UDim2.new(1,0,0,26) headerBG.BackgroundColor3=C("hudBg") headerBG.BackgroundTransparency=0.03 headerBG.BorderSizePixel=0 headerBG.ZIndex=201
		Instance.new("UICorner",headerBG).CornerRadius=UDim.new(0,8)
		local headerStroke=Instance.new("UIStroke",headerBG) headerStroke.Name="KBHeaderStroke" headerStroke.Color=C("border") headerStroke.Transparency=0.14
		local khlbl=Instance.new("TextLabel",kf) khlbl.Name="KBHeader"
		khlbl.Size=UDim2.new(1,-16,0,26) khlbl.Position=UDim2.new(0,9,0,0) khlbl.BackgroundTransparency=1
		khlbl.Text="Hotkeys" khlbl.TextColor3=C("hudText") khlbl.TextSize=11 khlbl.Font=Enum.Font.GothamBold
		khlbl.TextXAlignment=Enum.TextXAlignment.Left khlbl.ZIndex=203
		local rows=Instance.new("Frame",kf) rows.Name="KBRows"
		rows.Size=UDim2.new(1,0,1,-30) rows.Position=UDim2.new(0,0,0,30)
		rows.BackgroundTransparency=1 rows.ClipsDescendants=true rows.ZIndex=201
		onTC(function()
			if kf.Parent then
				headerBG.BackgroundColor3=C("hudBg") headerStroke.Color=C("border") khlbl.TextColor3=C("hudText")
			end
		end)
	elseif not v and ki then ki:Destroy() end
end)
mkToggle(visTab,"WASD Indicator",false,function(v)
	S.wasdInd=v
	local wi=sg:FindFirstChild("KamidereWASD")
	if v and not wi then
		local wf=Instance.new("Frame",sg) wf.Name="KamidereWASD"
		wf.Size=UDim2.new(0,118,0,72) wf.Position=UDim2.new(1,-136,1,-96)
		wf.BackgroundTransparency=1 wf.Active=true wf.Draggable=true wf.ZIndex=200
		for _,kd in ipairs({{n="W",x=47,y=0},{n="A",x=12,y=35},{n="S",x=47,y=35},{n="D",x=82,y=35}}) do
			local key=Instance.new("TextLabel",wf) key.Name="K_"..kd.n
			key.Size=UDim2.new(0,24,0,30) key.Position=UDim2.new(0,kd.x,0,kd.y)
			key.BackgroundTransparency=1 key.Text=kd.n key.TextColor3=C("hudText")
			key.TextTransparency=0 key.TextSize=18 key.Font=Enum.Font.GothamBold key.ZIndex=202
		end
	elseif not v and wi then wi:Destroy() end
end)
-- ============================================================
-- MISC TAB
-- ============================================================
local miscTab=tabColumns["misc"].left
mkSection(miscTab,"Player")
mkToggle(miscTab,"Auto Trample",false,function(v) S.autoTrample=v end)
mkToggle(miscTab,"Counter Strike Movement",false,function(v)
	S.counterStrikeMovement=v
	if not v then restoreCounterStrikeMovement() end
end)
mkSlider(miscTab,"CS Max Speed",40,140,90,5,function(v) S.csMaxSpeed=v end)
mkSlider(miscTab,"CS Acceleration",1,12,5,0.5,function(v) S.csAcceleration=v end)
mkSlider(miscTab,"CS Air Acceleration",0.2,5,2.2,0.1,function(v) S.csAirAcceleration=v end)
mkSlider(miscTab,"CS Friction",1,12,6,0.5,function(v) S.csFriction=v end)
mkToggle(miscTab,"Pixel Surf",false,function(v)
	S.pixelSurf=v
	if not v then S.pixelSurfKeyActive=false stopPixelSurf(true) end
end)
mkKeybind(miscTab,"Pixel Surf Keybind",function(k) S.pixelSurfKey=k end,function(m)
	S.pixelSurfKeyMode=m S.pixelSurfKeyActive=(m=="always on" and S.pixelSurf) or false
	if not S.pixelSurfKeyActive then stopPixelSurf(true) end
end)
mkSlider(miscTab,"Pixel Surf Acceleration",0.5,10,4,0.5,function(v) S.pixelSurfAcceleration=v end)
mkSlider(miscTab,"Pixel Surf Max Speed",10,100,60,5,function(v) S.pixelSurfMaxSpeed=v end)
mkToggle(miscTab,"Pixel Surf Sound",true,function(v) S.pixelSurfSound=v end)
mkTextSetting(miscTab,"Pixel Surf Sound ID","9045331159",function(value) S.pixelSurfSoundId=tostring(value or ""):gsub("%D","") end)
mkToggle(miscTab,"Pixel Surf Sparkles",false,function(v) S.pixelSurfSparkles=v end)
mkToggle(miscTab,"Pixel Surf Visualiser",false,function(v) S.pixelSurfVisualiser=v if not v then removePixelSurfVisualiser() end end)
mkRGB(miscTab,"Pixel Surf Visualiser Color",Color3.fromRGB(80,180,255),function(c) S.pixelSurfVisualiserColor=c end)
mkToggle(miscTab,"EdgeJump",false,function(v) S.edgeJump=v if not v then S.edgeJumpKeyActive=false end end)
mkKeybind(miscTab,"EdgeJump Keybind",function(k) S.edgeJumpKey=k end,function(m)
	S.edgeJumpKeyMode=m S.edgeJumpKeyActive=(m=="always on" and S.edgeJump) or false
end)
mkToggle(miscTab,"EdgeBug",false,function(v) S.edgeBug=v if not v then S.edgeBugKeyActive=false end end)
mkKeybind(miscTab,"EdgeBug Keybind",function(k) S.edgeBugKey=k end,function(m)
	S.edgeBugKeyMode=m S.edgeBugKeyActive=(m=="always on" and S.edgeBug) or false
end)
mkToggle(miscTab,"EdgeBug Sparkles",false,function(v) S.edgeBugSparkles=v end)
mkToggle(miscTab,"JumpBug",false,function(v)
	S.jumpBug=v
	if not v then S.jumpBugKeyActive=false restoreJumpBug() elseif S.jumpBugKeyMode=="always on" then S.jumpBugKeyActive=true updateJumpBug() end
end)
mkKeybind(miscTab,"JumpBug Keybind",function(k) S.jumpBugKey=k end,function(m)
	S.jumpBugKeyMode=m S.jumpBugKeyActive=(m=="always on" and S.jumpBug) or false
	if S.jumpBugKeyActive then updateJumpBug() else restoreJumpBug() end
end)
mkSlider(miscTab,"JumpBug Power",50,150,75,5,function(v) S.jumpBugPower=v if jumpBugHumanoid then jumpBugHumanoid.JumpPower=v end end)
mkSection(miscTab,"Console")
mkButton(miscTab,"Infinite Yield",function()
	pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
end)
mkButton(miscTab,"Azure Modded",function()
	pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Actyrn/Scripts/main/AzureModded"))() end)
end)
miscTab=tabColumns["misc"].right
mkSection(miscTab,"System")
mkToggle(miscTab,"Turn Off Cheat",false,function(v)
	if not v or cheatDisabled then return end
	-- First disable every feature/state.
	for key,value in pairs(S) do
		if type(value)=="boolean" then S[key]=false end
	end
	S.aimbotTarget=nil S.aimbotKeyActive=false S.trigActive=false S.trigKeyActive=false S.edgeBugKeyActive=false S.edgeJumpKeyActive=false S.jumpBugKeyActive=false
	stopPixelSurf(false) removePixelSurfVisualiser() restoreCounterStrikeMovement() restoreJumpBug() setRTXEnabled(false)
	if pixelSurfSoundObject and pixelSurfSoundObject.Parent then pixelSurfSoundObject:Destroy() end
	cheatDisabled=true
	-- Restore Lighting and remove effects created by the script.
	if S.origLight.Ambient then Lighting.Ambient=S.origLight.Ambient end
	if S.origLight.CSB then Lighting.ColorShift_Bottom=S.origLight.CSB end
	if S.origLight.CST then Lighting.ColorShift_Top=S.origLight.CST end
	if S.worldOrig.Ambient then Lighting.Ambient=S.worldOrig.Ambient end
	if S.worldOrig.CSB then Lighting.ColorShift_Bottom=S.worldOrig.CSB end
	if S.worldOrig.CST then Lighting.ColorShift_Top=S.worldOrig.CST end
	for _,effectName in ipairs({"KamidereBlur","KamidereRTXColor","KamidereRTXBloom","KamidereRTXSunRays","KamidereRTXAtmosphere","KamidereRTXDepth"}) do
		local effect=Lighting:FindFirstChild(effectName)
		if effect then effect:Destroy() end
	end
	-- Restore tools changed by Tool Chams.
	for _,orig in pairs(S.toolOrigData or {}) do
		local part=orig.part
		if part and part.Parent then
			part.Material=orig.mat part.Color=orig.color
			if orig.texAlphas then
				for decal,alpha in pairs(orig.texAlphas) do
					if decal.Parent then decal.Transparency=alpha end
				end
			end
		end
	end
	S.toolOrigData={}
	-- Remove character/world visuals created by the script.
	for _,player in ipairs(Players:GetPlayers()) do
		local char=player.Character
		if char then
			for _,name in ipairs({"ConeHat","KamidereAura","KamidereChams","KamidereMyChams"}) do
				local obj=char:FindFirstChild(name)
				if obj then obj:Destroy() end
			end
			for _,obj in ipairs(char:GetDescendants()) do
				if obj.Name=="KamidereAntiHL" or obj.Name=="KamidereToolChams" or obj.Name=="KamidereTrail" or obj.Name=="TrailA0" or obj.Name=="TrailA1" then obj:Destroy() end
			end
			local hrp=char:FindFirstChild("HumanoidRootPart")
			if hrp then
				for _,name in ipairs({"KamidereTrail","TrailA0","TrailA1","AuraCenter"}) do
					local obj=hrp:FindFirstChild(name)
					if obj then obj:Destroy() end
				end
			end
		end
	end
	local workspaceAura=workspace:FindFirstChild("KamidereAura_"..plr.UserId)
	if workspaceAura then workspaceAura:Destroy() end
	if dynamicCameraHumanoid and dynamicCameraHumanoid.Parent then dynamicCameraHumanoid.CameraOffset=Vector3.new(0,0,0) end
	dynamicCameraOffset=Vector3.new(0,0,0)
	pcall(function() RS:UnbindFromRenderStep(DYNAMIC_CAMERA_BIND) end)
	restoreToolViewmodel() restoreAllTransparency() destroyFirstPersonViewmodel()
	cam.FieldOfView=originalScreenFov
	songSound:Stop() if songSound.Parent then songSound:Destroy() end
	for _,name in ipairs({"KamidereCrosshair","KamidereSongWindow","KamidereVelocity"}) do removeScreenObject(name) end
	removeWorldSnow() removeCelestialSigil() removeCelestialWings() removeEtherealCubes()
	for _,bundle in pairs(deathWatchConnections) do for _,connection in ipairs(bundle) do pcall(function() connection:Disconnect() end) end end
	-- Close smoothly, then remove the entire interface and stop the LocalScript.
	_G.KamidereCloseGUI()
	task.delay(0.3,function()
		if sg and sg.Parent then sg:Destroy() end
		pcall(function() script.Disabled=true end)
	end)
end)
-- ============================================================
-- CONFIGURATION
-- ============================================================
local function packConfigValue(value)
 local valueType=typeof(value)
 if valueType=="Color3" then return {__type="Color3",r=value.R,g=value.G,b=value.B} end
 if type(value)=="table" then local copy={} for key,item in pairs(value)do copy[key]=packConfigValue(item)end return copy end
 if type(value)=="boolean" or type(value)=="number" or type(value)=="string" then return value end
end
local function unpackConfigValue(value)
 if type(value)~="table" then return value end
 if value.__type=="Color3" then return Color3.new(tonumber(value.r)or 0,tonumber(value.g)or 0,tonumber(value.b)or 0) end
 local copy={}for key,item in pairs(value)do copy[key]=unpackConfigValue(item)end return copy
end
local function exportConfig()
 local payload={version=2,controls={},targetList=packConfigValue(S.targetList or {})}
 for _,label in ipairs(configControlOrder)do local control=configControls[label];if control and control.get then payload.controls[label]=packConfigValue(control.get())end end
 local ok,json=pcall(function()return HttpService:JSONEncode(payload)end);return ok and ("KAMIv2:"..json) or ""
end
local function importConfig(str)
 if type(str)~="string" or not str:match("^KAMIv2:")then return false,"Invalid KAMIv2 config"end
 local ok,payload=pcall(function()return HttpService:JSONDecode(str:sub(8))end)
 if not ok or type(payload)~="table" or type(payload.controls)~="table"then return false,"Config is damaged"end
 if type(payload.targetList)=="table"then S.targetList=unpackConfigValue(payload.targetList)end
 for pass=1,2 do for _,label in ipairs(configControlOrder)do local control=configControls[label];local saved=payload.controls[label];if control and saved~=nil and ((pass==2)==(control.kind=="toggle"))then local applied=pcall(function()control.set(unpackConfigValue(saved))end);if not applied then return false,"Failed: "..label end end end end
 pcall(refreshTargetList);return true,"Settings restored"
end
local cfgProxy=tabColumns.cfg.left
mkSection(cfgProxy,"Configuration")
local configText=""
mkTextSetting(cfgProxy,"Config string","",function(v)configText=v end)
mkButton(cfgProxy,"Import Config",function()local ok,msg=importConfig(configText);print("[KAMIDERE]",msg)end)
mkButton(cfgProxy,"Export Config",function()configText=exportConfig();pcall(function()setclipboard(configText)end);print("[KAMIDERE] config copied")end)

-- ============================================================
-- OPEN / CLOSE
-- ============================================================
firstPersonCameraStable=false
function isFirstPersonCamera()
	if plr.CameraMode==Enum.CameraMode.LockFirstPerson then firstPersonCameraStable=true return true end
	local distance=(cam.CFrame.Position-cam.Focus.Position).Magnitude
	if firstPersonCameraStable then
		if distance>1.45 then firstPersonCameraStable=false end
	elseif distance<1.15 then firstPersonCameraStable=true end
	return firstPersonCameraStable
end
-- Menu no longer overrides MouseBehavior in first person.
local function enableMenuCursor()
	pcall(function() RS:UnbindFromRenderStep(menuMouseBinding) end)
end
local function disableMenuCursor()
	pcall(function() RS:UnbindFromRenderStep(menuMouseBinding) end)
end
-- Third-person movement lag. CameraType and RMB input remain controlled by Roblox.
RS:BindToRenderStep(DYNAMIC_CAMERA_BIND,Enum.RenderPriority.Camera.Value+2,function(dt)
	local char=plr.Character
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	local hrp=char and char:FindFirstChild("HumanoidRootPart")
	if dynamicCameraHumanoid and dynamicCameraHumanoid~=hum and dynamicCameraHumanoid.Parent then
		dynamicCameraHumanoid.CameraOffset=Vector3.new(0,0,0)
	end
	dynamicCameraHumanoid=hum
	local firstPerson=isFirstPersonCamera()
	if firstPerson then
		dynamicCameraOffset=Vector3.new(0,0,0)
		if hum then hum.CameraOffset=Vector3.new(0,0,0) end
		return
	end
	local targetOffset=Vector3.new(0,0,0)
	if not cheatDisabled and S.dynamicCamera and hum and hrp then
		local velocity=hrp.AssemblyLinearVelocity
		local worldLag=-velocity*S.dynamicCameraStrength
		if worldLag.Magnitude>3 then worldLag=worldLag.Unit*3 end
		targetOffset=hrp.CFrame:VectorToObjectSpace(worldLag)
	end
	local response=math.max(1,22-S.dynamicCameraSmoothness)
	local alpha=1-math.exp(-response*math.min(dt,0.1))
	dynamicCameraOffset=dynamicCameraOffset:Lerp(targetOffset,alpha)
	if dynamicCameraOffset.Magnitude<0.001 and targetOffset.Magnitude==0 then dynamicCameraOffset=Vector3.new(0,0,0) end
	if hum then hum.CameraOffset=dynamicCameraOffset end
end)
local guiOpen=true
function _G.KamidereOpenGUI() guiOpen=true Window:SetVisible(true) end
function _G.KamidereCloseGUI() guiOpen=false Window:SetVisible(false) end

-- ============================================================
-- FOV CIRCLE
-- ============================================================
local fovCircle=Instance.new("Frame",sg)
fovCircle.BackgroundTransparency=1 fovCircle.BorderSizePixel=0 fovCircle.ZIndex=180
fovCircle.Visible=false fovCircle.Name="FOVCircle"
local fovStroke=Instance.new("UIStroke",fovCircle) fovStroke.Thickness=1.5
Instance.new("UICorner",fovCircle).CornerRadius=UDim.new(1,0)
-- ============================================================
-- BOX ESP 2D + TOOL ESP LABEL BELOW BOX
-- ============================================================
local boxLines={}
local toolESPLabels={}
local function getBoxLines(p2)
	if boxLines[p2] then return boxLines[p2] end
	local t={}
	for i=1,4 do
		local f=Instance.new("Frame",sg) f.BackgroundColor3=S.boxColor f.BorderSizePixel=0 f.ZIndex=150 f.Visible=false
		t[i]=f
	end
	boxLines[p2]=t return t
end
local function removeBoxLines(p2)
	if not boxLines[p2] then return end
	for _,f in ipairs(boxLines[p2]) do f:Destroy() end boxLines[p2]=nil
end
local function getToolESPLabel(p2)
	if toolESPLabels[p2] then return toolESPLabels[p2] end
	local lbl=Instance.new("TextLabel",sg)
	lbl.BackgroundTransparency=1 lbl.BorderSizePixel=0 lbl.ZIndex=151
	lbl.TextSize=11 lbl.Font=Enum.Font.GothamMedium
	lbl.TextStrokeTransparency=0.4 lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
	lbl.Visible=false lbl.Text=""
	toolESPLabels[p2]=lbl return lbl
end
local function removeToolESPLabel(p2)
	local l=toolESPLabels[p2] if not l then return end l:Destroy() toolESPLabels[p2]=nil
end
local function getBBox(p2)
	local char2=p2.Character if not char2 then return nil end
	local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
	local anyVis=false
	for _,pt in ipairs(char2:GetDescendants()) do
		if pt:IsA("BasePart") and not pt:FindFirstAncestorOfClass("Tool") then
			local hs=pt.Size/2
			for _,co in ipairs(CORNERS) do
				local wp=(pt.CFrame*CFrame.new(co*hs)).Position
				local sp,vis=cam:WorldToViewportPoint(wp)
				if vis and sp.Z>0 then
					anyVis=true
					if sp.X<minX then minX=sp.X end if sp.Y<minY then minY=sp.Y end
					if sp.X>maxX then maxX=sp.X end if sp.Y>maxY then maxY=sp.Y end
				end
			end
		end
	end
	if not anyVis then return nil end
	return minX,minY,maxX,maxY
end
local function drawBox2D(p2,lines,minX,minY,maxX,maxY)
	local col=S.boxColor
	lines[1].Position=UDim2.new(0,minX,0,minY) lines[1].Size=UDim2.new(0,maxX-minX,0,1) lines[1].BackgroundColor3=col lines[1].Visible=true
	lines[2].Position=UDim2.new(0,minX,0,maxY) lines[2].Size=UDim2.new(0,maxX-minX,0,1) lines[2].BackgroundColor3=col lines[2].Visible=true
	lines[3].Position=UDim2.new(0,minX,0,minY) lines[3].Size=UDim2.new(0,1,0,maxY-minY) lines[3].BackgroundColor3=col lines[3].Visible=true
	lines[4].Position=UDim2.new(0,maxX,0,minY) lines[4].Size=UDim2.new(0,1,0,maxY-minY) lines[4].BackgroundColor3=col lines[4].Visible=true
end
-- ============================================================
-- HP BAR
-- ============================================================
local hpBars={}
local function getHPBar(p2)
	if hpBars[p2] then return hpBars[p2] end
	local bg=Instance.new("Frame",sg) bg.BackgroundColor3=Color3.fromRGB(30,30,30)
	bg.BorderSizePixel=0 bg.ZIndex=149
	Instance.new("UICorner",bg).CornerRadius=UDim.new(0,2)
	local fill=Instance.new("Frame",bg) fill.Name="Fill"
	fill.Size=UDim2.new(1,0,1,0) fill.AnchorPoint=Vector2.new(0,1)
	fill.Position=UDim2.new(0,0,1,0) fill.BackgroundColor3=Color3.fromRGB(200,200,0)
	fill.BorderSizePixel=0
	Instance.new("UICorner",fill).CornerRadius=UDim.new(0,2)
	local num=Instance.new("TextLabel",bg) num.Size=UDim2.new(0,30,0,12)
	num.Position=UDim2.new(1,2,1,-12) num.BackgroundTransparency=1
	num.TextColor3=Color3.fromRGB(220,220,0) num.TextSize=9 num.Font=Enum.Font.GothamBold
	hpBars[p2]={bg=bg,fill=fill,num=num}
	return hpBars[p2]
end
local function removeHPBar(p2)
	local d=hpBars[p2] if not d then return end
	d.bg:Destroy() hpBars[p2]=nil
end
-- ============================================================
-- ESP LABELS
-- ============================================================
local espData={}
local function getESP(p2)
	if espData[p2] then return espData[p2] end
	local d={}
	local namebb=Instance.new("BillboardGui",sg) namebb.Size=UDim2.new(0,200,0,20)
	namebb.StudsOffset=Vector3.new(0,4,0) namebb.AlwaysOnTop=true namebb.ResetOnSpawn=false namebb.Enabled=false
	d.namebb=namebb
	local nameL=Instance.new("TextLabel",namebb) nameL.Size=UDim2.new(1,0,1,0)
	nameL.BackgroundTransparency=1 nameL.TextSize=13 nameL.Font=Enum.Font.GothamBold
	nameL.TextStrokeTransparency=0.3 nameL.TextColor3=Color3.new(1,1,1)
	d.nameLabel=nameL
	-- FF dot
	local ffbb=Instance.new("BillboardGui",sg) ffbb.Size=UDim2.new(0,14,0,14)
	ffbb.StudsOffset=Vector3.new(2,0,0) ffbb.AlwaysOnTop=true ffbb.ResetOnSpawn=false ffbb.Enabled=false
	d.ffbb=ffbb
	local ffdot=Instance.new("Frame",ffbb) ffdot.Size=UDim2.new(1,0,1,0)
	ffdot.BackgroundColor3=Color3.fromRGB(50,180,255) ffdot.BorderSizePixel=0
	Instance.new("UICorner",ffdot).CornerRadius=UDim.new(1,0)
	espData[p2]=d return d
end
local function cleanESP(p2)
	local d=espData[p2] if not d then return end
	if d.namebb then d.namebb:Destroy() end
	if d.ffbb then d.ffbb:Destroy() end
	if d.highlight then pcall(function() d.highlight:Destroy() end) end
	espData[p2]=nil
	removeToolESPLabel(p2)
end
-- ============================================================
-- HIT LOGS
-- ============================================================
local hitLogHolder=Instance.new("Frame",sg)
hitLogHolder.Name="HitLogs" hitLogHolder.Size=UDim2.new(0,300,0,200)
hitLogHolder.Position=UDim2.new(1,-320,0,50) hitLogHolder.BackgroundTransparency=1 hitLogHolder.ZIndex=160
local hlLay=Instance.new("UIListLayout",hitLogHolder)
hlLay.VerticalAlignment=Enum.VerticalAlignment.Top hlLay.Padding=UDim.new(0,3)
local prevHP={}
local function addHitLog(msg)
	if not S.hitlogs then return end
	local l=Instance.new("TextLabel",hitLogHolder) l.Size=UDim2.new(1,0,0,20)
	l.BackgroundColor3=C("hudBg") l.BackgroundTransparency=0.25 l.BorderSizePixel=0
	l.Text="  "..msg l.TextColor3=C("hudText") l.TextSize=11 l.Font=Enum.Font.Gotham
	l.TextXAlignment=Enum.TextXAlignment.Left l.ZIndex=161
	Instance.new("UICorner",l).CornerRadius=UDim.new(0,4)
	TS:Create(l,TweenInfo.new(3.5),{TextTransparency=1,BackgroundTransparency=1}):Play()
	task.delay(3.7,function() if l.Parent then l:Destroy() end end)
end
-- ============================================================
-- AURA & TRAIL
-- ============================================================
local auraAngle=0
local function createAura(char)
	if not char then return end
	local old=workspace:FindFirstChild("KamidereAura_"..plr.UserId) if old then old:Destroy() end
	local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
	local aura=Instance.new("Model",workspace) aura.Name="KamidereAura_"..plr.UserId
	for i=1,10 do
		local orb=Instance.new("Part",aura) orb.Name="GlowOrb"
		orb.Shape=Enum.PartType.Ball orb.Size=Vector3.new(0.18,0.18,0.18)
		orb.Material=Enum.Material.Neon orb.Color=S.auraColor
		orb.Transparency=0.18 orb.CanCollide=false orb.CanTouch=false orb.CanQuery=false orb.Massless=true orb.CastShadow=false
		local weld=Instance.new("Weld",orb) weld.Part0=hrp weld.Part1=orb
		orb:SetAttribute("Phase",(i/10)*math.pi*2)
		orb:SetAttribute("Radius",2.0+(i%3)*0.32)
		orb:SetAttribute("Speed",0.55+(i%4)*0.08)
		orb:SetAttribute("Height",(i%5-2)*0.38)
		orb:SetAttribute("Bob",0.25+(i%3)*0.08)
		local light=Instance.new("PointLight",orb) light.Name="Glow"
		light.Color=S.auraColor light.Brightness=1.4 light.Range=4 light.Shadows=false
		local emitter=Instance.new("ParticleEmitter",orb) emitter.Name="Sparkle"
		emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
		emitter.Rate=4 emitter.Lifetime=NumberRange.new(0.7,1.1) emitter.Speed=NumberRange.new(0,0.08)
		emitter.Rotation=NumberRange.new(0,360) emitter.RotSpeed=NumberRange.new(-30,30)
		emitter.LightEmission=1 emitter.LightInfluence=0 emitter.SpreadAngle=Vector2.new(180,180)
		emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.28),NumberSequenceKeypoint.new(0.5,0.14),NumberSequenceKeypoint.new(1,0)})
		emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.28),NumberSequenceKeypoint.new(0.75,0.55),NumberSequenceKeypoint.new(1,1)})
		emitter.Color=ColorSequence.new(S.auraColor)
	end
end
local function createTrail(char)
	local torso=char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso")
	if not torso or char:FindFirstChild("KamidereTrail",true) then return end
	local a0=Instance.new("Attachment",torso) a0.Name="TrailA0" a0.Position=Vector3.new(-0.035,-0.38,0.35)
	local a1=Instance.new("Attachment",torso) a1.Name="TrailA1" a1.Position=Vector3.new(0.035,-0.38,0.35)
	local trail=Instance.new("Trail",torso) trail.Name="KamidereTrail"
	trail.Attachment0=a0 trail.Attachment1=a1 trail.Lifetime=0.9 trail.MinLength=0.02
	trail.FaceCamera=true trail.LightEmission=1 trail.Color=ColorSequence.new(S.motionTrailColor)
	trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.08),NumberSequenceKeypoint.new(0.72,0.25),NumberSequenceKeypoint.new(1,1)})
	trail.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
end
-- ============================================================
-- TOOL / PLAYER CHAMS SEPARATION
-- ============================================================
local function updateEquippedToolChams(tool,playerChamsEnabled)
	if not tool or not tool:IsA("Tool") then return end
	local toolHL=tool:FindFirstChild("KamidereToolChams")
	local excludeHL=tool:FindFirstChild("KamidereAntiHL")
	if S.toolChams then
		if excludeHL then excludeHL:Destroy() excludeHL=nil end
		if not toolHL then
			toolHL=Instance.new("Highlight",tool) toolHL.Name="KamidereToolChams"
			toolHL.Adornee=tool toolHL.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
		end
		toolHL.FillColor=S.toolChamsColor toolHL.OutlineColor=S.toolChamsColor
		toolHL.FillTransparency=S.toolChamsAlpha toolHL.OutlineTransparency=0
	else
		if toolHL then toolHL:Destroy() toolHL=nil end
		if playerChamsEnabled then
			if not excludeHL then
				excludeHL=Instance.new("Highlight",tool) excludeHL.Name="KamidereAntiHL"
				excludeHL.Adornee=tool excludeHL.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
			end
			excludeHL.FillTransparency=1 excludeHL.OutlineTransparency=1
		elseif excludeHL then excludeHL:Destroy() end
	end
end
-- ============================================================
-- CHAMS: apply/remove per character, hooked to CharacterAdded
-- ============================================================
local function applyChamsToChar(char, p2)
	if cheatDisabled or not char then return end
	-- Remove old
	local old = char:FindFirstChild("KamidereChams")
	if old then old:Destroy() end
	if not S.chams then return end
	task.defer(function()
		if cheatDisabled or not char.Parent then return end
		local hl = Instance.new("Highlight", char)
		hl.Name = "KamidereChams"
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillColor = S.chamsColor
		hl.OutlineColor = S.chamsColor
		hl.FillTransparency = S.chamsAlpha
		hl.OutlineTransparency = 0
		-- Store in espData
		local d = getESP(p2)
		d.highlight = hl
	end)
end
-- Hook all existing players
for _, p2 in ipairs(Players:GetPlayers()) do
	if p2 ~= plr then
		p2.CharacterAdded:Connect(function(char)
			task.wait(0.3)
			applyChamsToChar(char, p2)
		end)
		if p2.Character then applyChamsToChar(p2.Character, p2) end
	end
end
-- Hook new players
Players.PlayerAdded:Connect(function(p2)
	if p2 == plr then return end
	p2.CharacterAdded:Connect(function(char)
		task.wait(0.3)
		applyChamsToChar(char, p2)
	end)
end)
-- ============================================================
-- MAIN LOOPS
-- ============================================================
local lastCamCF=cam.CFrame
local trigLastFire=0
local wm_fps,wm_fc,wm_lf=0,0,0
local wm_ping,wm_lp=0,0
RS.Heartbeat:Connect(function(dt)
	if cheatDisabled then return end
	wm_fc=wm_fc+1
	local now=tick()
	if now-wm_lf>=1 then wm_fps=math.floor(wm_fc/(now-wm_lf)) wm_fc=0 wm_lf=now end
	if now-wm_lp>=1 then
		pcall(function() wm_ping=math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
		wm_lp=now
	end
	-- AUTO TRAMPLE
	if S.autoTrample and S.aimbotTarget and S.aimbotTarget.Character then
		local tc=S.aimbotTarget.Character
		local thrp=tc:FindFirstChild("HumanoidRootPart")
		local mhrp=getHRP()
		local mhum=getChar() and getChar():FindFirstChild("Humanoid")
		if thrp and mhrp and mhum then
			local behindPos=thrp.CFrame*CFrame.new(0,0,2)
			mhum:MoveTo(behindPos.Position)
		end
	end
	-- TRIGGERBOT — FIX: run every heartbeat, no per-second gate
	if S.trigOn and S.trigKeyActive then
		local delay = S.trigSpeedOn and (S.trigSpeedMs/1000) or 0.05
		if now - trigLastFire >= delay then
			local vp = cam.ViewportSize
			local myC = getChar()
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = myC and {myC} or {}
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.IgnoreWater = true
			-- Check each selected trigger part
			local fired = false
			for _, pname in ipairs(S.trigParts) do
				if fired then break end
				local unitRay = cam:ScreenPointToRay(vp.X/2, vp.Y/2)
				local result = workspace:Raycast(unitRay.Origin, unitRay.Direction*1000, params)
				if result then
					local hit = result.Instance
					local char2 = hit and hit.Parent
					if char2 and char2:FindFirstChild("Humanoid") then
						local tp2 = Players:GetPlayerFromCharacter(char2)
						if tp2 and tp2 ~= plr and not isInSafeZone(char2) and isPlayerAllowed(tp2) then
							local fireFunc = function()
								pcall(function()
									local vim = game:GetService("VirtualInputManager")
									vim:SendMouseButtonEvent(vp.X/2, vp.Y/2, 0, true, game, 0)
									task.wait(0.001)
									vim:SendMouseButtonEvent(vp.X/2, vp.Y/2, 0, false, game, 0)
								end)
							end
							if S.trigReaction and S.trigReactionMs > 0 then
								task.delay(S.trigReactionMs/1000, fireFunc)
							else
								fireFunc()
							end
							trigLastFire = now
							fired = true
						end
					end
				end
			end
		end
	end
end)
RS.Heartbeat:Connect(function(dt)
	if cheatDisabled then return end
	if S.counterStrikeMovement then updateCounterStrikeMovement(dt) elseif counterStrikeHumanoid then restoreCounterStrikeMovement() end
end)
RS.Heartbeat:Connect(function(dt)
	if cheatDisabled then return end
	if S.pixelSurf or pixelSurfSliding then updatePixelSurf(dt) end
	if S.pixelSurfVisualiser then updatePixelSurfVisualiser() elseif sg:FindFirstChild("KamiderePixelSurfVisualiser") then removePixelSurfVisualiser() end
end)
RS.Heartbeat:Connect(function(dt)
	if not cheatDisabled then updateEdgeMovement(dt) end
end)
RS.Heartbeat:Connect(function()
	if not cheatDisabled and ((S.jumpBug and S.jumpBugKeyActive) or jumpBugHumanoid) then updateJumpBug() end
end)
RS.RenderStepped:Connect(function(dt)
	if cheatDisabled then return end
	-- Split PH watermark with theme-colored separators
	local wm=sg:FindFirstChild("KamidereWM")
	if wm and S.watermark then
		local wl=wm:FindFirstChild("WML")
		local logoBox=wm:FindFirstChild("WMLogoBox")
		local infoBox=wm:FindFirstChild("WMInfoBox")
		local logo=logoBox and logoBox:FindFirstChild("WMLogo")
		if wl and logoBox and infoBox then
			logoBox.BackgroundColor3=C("hudBg") infoBox.BackgroundColor3=C("hudBg")
			local ls=logoBox:FindFirstChild("WMLogoStroke") if ls then ls.Color=C("border") end
			local is=infoBox:FindFirstChild("WMInfoStroke") if is then is.Color=C("border") end
			if logo then logo.TextColor3=C("on") end
			wl.TextColor3=C("hudText")
			local ac=C("on")
			local r,g,b=math.floor(ac.R*255+0.5),math.floor(ac.G*255+0.5),math.floor(ac.B*255+0.5)
			local accent=string.format("rgb(%d,%d,%d)",r,g,b)
			local timeText=os.date("%H:%M",os.time())
			local plainText=string.format("%s  ●  %d ms  ●  %d fps  ●  %s",plr.Name,wm_ping,wm_fps,timeText)
			wl.Text=string.format(
				'%s  <font color="%s">●</font>  %d ms  <font color="%s">●</font>  %d fps  <font color="%s">●</font>  %s',
				plr.Name,accent,wm_ping,accent,wm_fps,accent,timeText)
			local textWidth=TextService:GetTextSize(plainText,11,Enum.Font.GothamMedium,Vector2.new(1000,28)).X
			local infoWidth=math.clamp(math.ceil(textWidth)+16,150,520)
			infoBox.Size=UDim2.new(0,infoWidth,0,28)
			wl.Size=UDim2.new(0,infoWidth-16,0,28)
			wm.Size=UDim2.new(0,40+infoWidth,0,28)
		end
	end
	-- AIMBOT — FIX: smooth uses lerp on direction vector, not camera CFrame lerp (prevents shake)
	if S.aimbotOn and S.aimbotKeyActive and S.aimbotTarget then
		if S.aimbotTarget.Character then
			local hum2=S.aimbotTarget.Character:FindFirstChild("Humanoid")
			if hum2 and hum2.Health>0 then
				if aimbotCachedTarget~=S.aimbotTarget then aimbotCachedTarget=S.aimbotTarget aimbotCachedPoint=nil aimbotPointNext=0 end
				if os.clock()>=aimbotPointNext then aimbotPointNext=os.clock()+1/30 aimbotCachedPoint=findBestAimPoint(S.aimbotTarget.Character,S.aimbotParts) end
				local bestPos=aimbotCachedPoint
				if bestPos then
					if S.aimbotSmooth > 0 then
						-- FIX: smooth by interpolating the look direction, not the full CFrame
						local currentLook = cam.CFrame.LookVector
						local targetDir = (bestPos - cam.CFrame.Position).Unit
						local alpha = math.clamp(dt * (21 - S.aimbotSmooth) * 2.5, 0, 1)
						local newLook = currentLook:Lerp(targetDir, alpha).Unit
						local rightRaw = newLook:Cross(Vector3.new(0,1,0))
						local right = rightRaw.Magnitude>0.001 and rightRaw.Unit or cam.CFrame.RightVector
						local up = right:Cross(newLook).Unit
						cam.CFrame = CFrame.fromMatrix(cam.CFrame.Position, right, up, -newLook)
					else
						cam.CFrame = CFrame.new(cam.CFrame.Position, bestPos)
					end
				else aimbotCachedPoint=nil aimbotPointNext=0 end
			else markAimbotTargetForRespawn() end
		else markAimbotTargetForRespawn() end
	end
	-- FOV circle
	if S.aimbotFOV then
		local r=S.aimbotFOVval
		local vp=cam.ViewportSize
		fovCircle.Size=UDim2.new(0,r*2,0,r*2)
		fovCircle.Position=UDim2.new(0,vp.X/2-r,0,vp.Y/2-r)
		fovStroke.Color=S.aimbotFOVcolor fovCircle.Visible=true
	else fovCircle.Visible=false end
	-- Motion blur
	local blurFx=Lighting:FindFirstChild("KamidereBlur")
	if blurFx then
		if S.motionBlur then
			local delta=cam.CFrame:ToObjectSpace(lastCamCF)
			local rx,ry,rz=delta:ToEulerAnglesXYZ()
			blurFx.Size=blurFx.Size+(math.clamp(math.sqrt(rx*rx+ry*ry+rz*rz)*90,0,22)-blurFx.Size)*0.25
		else blurFx.Size=0 end
	end
	lastCamCF=cam.CFrame
	auraAngle=auraAngle+dt*55
	local myChar=getChar()
	-- CUSTOM CROSSHAIR
	local crosshair=sg:FindFirstChild("KamidereCrosshair")
	if crosshair and S.customCrosshair then
		local horizontal=crosshair:FindFirstChild("Horizontal") local vertical=crosshair:FindFirstChild("Vertical")
		if horizontal then horizontal.BackgroundColor3=S.crosshairColor end
		if vertical then vertical.BackgroundColor3=S.crosshairColor end
		if S.crosshairSpin then crosshairAngle=(crosshairAngle+dt*42)%360
		else
			if crosshairAngle>180 then crosshairAngle=crosshairAngle-360 end
			crosshairAngle=crosshairAngle+(0-crosshairAngle)*(1-math.exp(-10*math.min(dt,0.1)))
			if math.abs(crosshairAngle)<0.05 then crosshairAngle=0 end
		end
		crosshair.Rotation=crosshairAngle
	end
	-- Overall FOV affects the world and is also the baseline for the hands/tool ViewportFrame.
	cam.FieldOfView=S.screenFov
	-- In third person Tool Viewmodel changes Grip; first person uses the shared hands/tool ViewportFrame.
	local viewmodelActive=S.toolViewmodel and myChar~=nil and not isFirstPersonCamera()
	local equipped={}
	if myChar then
		for _,tool in ipairs(myChar:GetChildren()) do
			if tool:IsA("Tool") then
				equipped[tool]=true
				if viewmodelActive then
					if toolViewOriginals[tool]==nil then toolViewOriginals[tool]=tool.Grip end
					tool.Grip=toolViewOriginals[tool]*CFrame.new(S.viewmodelX,-S.viewmodelY,S.viewmodelZ)
				elseif toolViewOriginals[tool] then tool.Grip=toolViewOriginals[tool] toolViewOriginals[tool]=nil end
			end
		end
	end
	for tool,grip in pairs(toolViewOriginals) do
		if not equipped[tool] then if tool and tool.Parent then pcall(function() tool.Grip=grip end) end toolViewOriginals[tool]=nil end
	end
	if S.visibleHands or S.toolViewmodel or sg:FindFirstChild("KamidereFirstPersonViewmodel") then updateFirstPersonViewmodel(myChar) end
	-- PLAYER TRANSPARENCY, including accessories and equipped tools.
	transparencyUpdateAccumulator=transparencyUpdateAccumulator+dt
	if transparencyUpdateAccumulator>=0.1 then
		transparencyUpdateAccumulator=0
		for _,player in ipairs(Players:GetPlayers()) do
			local char=player.Character
			if char then
				local alpha=player==plr and S.selfPlayerTransparency or S.playerTransparency
				local deathHidden=char:GetAttribute("KamidereDeathHidden")==true
				local localFirstPerson=player==plr and isFirstPersonCamera()
				for _,object in ipairs(char:GetDescendants()) do
					if object:IsA("BasePart") then
						if transparencyOriginals[object]==nil then transparencyOriginals[object]=object.LocalTransparencyModifier end
						local insideTool=object:FindFirstAncestorOfClass("Tool")~=nil
						if deathHidden then object.LocalTransparencyModifier=1
						elseif player==plr and insideTool and localFirstPerson and (S.toolViewmodel or S.visibleHands) then object.LocalTransparencyModifier=1
						elseif player==plr and insideTool then object.LocalTransparencyModifier=alpha
						elseif localFirstPerson then object.LocalTransparencyModifier=1
						else object.LocalTransparencyModifier=math.max(transparencyOriginals[object] or 0,alpha) end
					end
				end
			end
		end
	end
	-- VELOCITY INDICATOR
	local velocityLabel=sg:FindFirstChild("KamidereVelocity")
	if velocityLabel and S.velocityIndicator then
		local hrp=myChar and myChar:FindFirstChild("HumanoidRootPart")
		local velocity=hrp and hrp.AssemblyLinearVelocity or Vector3.zero
		local horizontalSpeed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
		velocityLabel.Text=tostring(math.floor(horizontalSpeed+0.5))
		velocityLabel.TextColor3=S.velocityColor
	end
	-- World-space snow volume follows the local player; only one emitter is used.
	local snow=workspace:FindFirstChild("KamidereWorldSnow_"..plr.UserId)
	if snow and S.snowParticles then
		local hrp=myChar and myChar:FindFirstChild("HumanoidRootPart")
		if hrp then snow.CFrame=CFrame.new(hrp.Position+Vector3.new(0,28,0)) end
		snow.Size=Vector3.new(S.snowRadius*2,1,S.snowRadius*2)
		local snowEmitter=snow:FindFirstChild("SnowEmitter")
		if snowEmitter then snowEmitter.Rate=S.snowAmount snowEmitter.Speed=NumberRange.new(S.snowSpeed*0.75,S.snowSpeed*1.25) end
	end
	updateCelestialSigil(dt,myChar)
	updateCelestialWings(dt,myChar)
	updateEtherealCubes(dt,myChar)
	-- CHINA HAT
	if S.chinaHat and myChar then
		if not myChar:FindFirstChild("ConeHat") then
			local head=myChar:FindFirstChild("Head")
			if head then
				local cone=Instance.new("Part",myChar) cone.Name="ConeHat"
				cone.Size=Vector3.new(1,1,1) cone.Color=S.chinaColor cone.Transparency=S.chinaTransparency
				cone.Anchored=false cone.CanCollide=false
				local mesh=Instance.new("SpecialMesh",cone)
				mesh.MeshType=Enum.MeshType.FileMesh mesh.MeshId="rbxassetid://1033714" mesh.Scale=Vector3.new(1.5,1.1,1.5)
				local weld=Instance.new("Weld",cone) weld.Part0=head weld.Part1=cone weld.C0=CFrame.new(0,0.7,0)
				local hl=Instance.new("Highlight",cone) hl.FillColor=S.chinaColor hl.FillTransparency=math.clamp(S.chinaTransparency+0.2,0,1)
				hl.OutlineColor=S.chinaColor hl.OutlineTransparency=S.chinaTransparency
			end
		else
			local cone=myChar.ConeHat cone.Color=S.chinaColor cone.Transparency=S.chinaTransparency
			local hl=cone:FindFirstChildOfClass("Highlight")
			if hl then hl.FillColor=S.chinaColor hl.OutlineColor=S.chinaColor hl.FillTransparency=math.clamp(S.chinaTransparency+0.2,0,1) hl.OutlineTransparency=S.chinaTransparency end
		end
	end
	-- AURA: independent floating glow orbits around the local character.
	if S.aura and myChar then
		local aura=workspace:FindFirstChild("KamidereAura_"..plr.UserId)
		if not aura then createAura(myChar) aura=workspace:FindFirstChild("KamidereAura_"..plr.UserId) end
		if aura then
			local t=os.clock()
			for _,orb in ipairs(aura:GetChildren()) do
				if orb:IsA("BasePart") then
					local weld=orb:FindFirstChildOfClass("Weld")
					if weld then
						local phase=orb:GetAttribute("Phase") or 0 local radius=orb:GetAttribute("Radius") or 2
						local speed=orb:GetAttribute("Speed") or 0.6 local height=orb:GetAttribute("Height") or 0
						local bob=orb:GetAttribute("Bob") or 0.3 local angle=phase+t*speed
						local y=height+math.sin(t*1.25+phase*1.7)*bob
						weld.C0=CFrame.new(math.cos(angle)*radius,y,math.sin(angle)*radius)
					end
					orb.Color=S.auraColor
					local glow=orb:FindFirstChild("Glow") if glow then glow.Color=orb.Color end
					local sparkle=orb:FindFirstChild("Sparkle") if sparkle then sparkle.Color=ColorSequence.new(S.auraColor) end
				end
			end
		end
	end
	-- TRAIL
	if S.motionTrail and myChar and not myChar:FindFirstChild("KamidereTrail",true) then createTrail(myChar) end
	-- MY CHAMS
	if myChar then
		local myHL=myChar:FindFirstChild("KamidereMyChams")
		if S.myChams then
			if not myHL then
				local hl=Instance.new("Highlight",myChar) hl.Name="KamidereMyChams"
				hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
				hl.FillColor=S.myChamsColor hl.OutlineColor=S.myChamsColor
				hl.FillTransparency=S.myChamsAlpha hl.OutlineTransparency=0
			else myHL.FillColor=S.myChamsColor myHL.OutlineColor=S.myChamsColor myHL.FillTransparency=S.myChamsAlpha end
		else if myHL then myHL:Destroy() end end
		-- Keep held tools separate from My Chams and give them their own Highlight when enabled.
		for _,tool in ipairs(myChar:GetChildren()) do
			if tool:IsA("Tool") then updateEquippedToolChams(tool,S.myChams) end
		end
	end
	-- FULLBRIGHT / WORLD COLOR
	if S.worldColor then
		local t = S.worldColorIntensity / 100
		local r = math.floor(S.worldColorVal.R * 255 * t)
		local g = math.floor(S.worldColorVal.G * 255 * t)
		local b = math.floor(S.worldColorVal.B * 255 * t)
		local col = Color3.fromRGB(r, g, b)
		Lighting.Ambient = col
		Lighting.ColorShift_Bottom = col
		Lighting.ColorShift_Top = col
	elseif S.fullbright then
		local v=S.fbAmt/100 local col=Color3.fromRGB(255*v,255*v,255*v)
		Lighting.Ambient=col Lighting.ColorShift_Bottom=col Lighting.ColorShift_Top=col
	end
	-- PLAYER ESP: feature-gated and capped at 30 updates per second.
	espUpdateAccumulator=espUpdateAccumulator+dt
	if espUpdateAccumulator>=1/30 then
		espUpdateAccumulator=0
		local espAny=S.nameESP or S.boxESP or S.toolESP or S.healthESP or S.chams or S.ffIndicator or S.hitlogs or S.toolChams
		if espAny then
			for _,p2 in ipairs(Players:GetPlayers()) do
				if p2~=plr and p2.Character then
					local char2=p2.Character
					local hum2=char2:FindFirstChild("Humanoid")
					local head2=char2:FindFirstChild("Head")
					if not hum2 or not head2 then
						cleanESP(p2) removeBoxLines(p2) removeHPBar(p2) continue
					end
					local d=getESP(p2)
					d.namebb.Adornee=head2
					d.ffbb.Adornee=head2
					-- Name ESP
					d.namebb.Enabled=S.nameESP
					if S.nameESP then d.nameLabel.Text=p2.Name d.nameLabel.TextColor3=S.nameColor end
					-- BOX ESP
					local minX,minY,maxX,maxY=getBBox(p2)
					if S.boxESP and minX then
						local lines=getBoxLines(p2)
						drawBox2D(p2,lines,minX,minY,maxX,maxY)
					else
						if boxLines[p2] then for _,f in ipairs(boxLines[p2]) do f.Visible=false end end
					end
					-- TOOL ESP — shown below box as screen-space label
					local toolLbl = getToolESPLabel(p2)
					if S.toolESP then
						local t2 = char2:FindFirstChildOfClass("Tool")
						if t2 and minX then
							toolLbl.Text = t2.Name
							toolLbl.TextColor3 = S.toolColor
							-- Position below box
							local boxW = maxX - minX
							toolLbl.Position = UDim2.new(0, minX, 0, maxY + 2)
							toolLbl.Size = UDim2.new(0, boxW, 0, 16)
							toolLbl.TextXAlignment = Enum.TextXAlignment.Center
							toolLbl.Visible = true
						else
							toolLbl.Visible = false
						end
					else
						toolLbl.Visible = false
					end
					-- HP bar
					if S.healthESP and minX then
						local hpd=getHPBar(p2)
						local boxH=maxY-minY
						local barW=4
						hpd.bg.Position=UDim2.new(0,minX-barW-2,0,minY)
						hpd.bg.Size=UDim2.new(0,barW,0,boxH)
						hpd.bg.Visible=true
						local hp=math.max(0,hum2.Health)
						local mhp=math.max(1,hum2.MaxHealth)
						local ratio=hp/mhp
						hpd.fill.Size=UDim2.new(1,0,ratio,0)
						local r=(1-ratio) local g=ratio
						hpd.fill.BackgroundColor3=Color3.fromRGB(r*255,g*255,30)
						hpd.num.Text=math.floor(hp)
						hpd.num.TextColor3=Color3.fromRGB(r*255,g*255,30)
					else
						if hpBars[p2] then hpBars[p2].bg.Visible=false end
					end
					-- CHAMS — update colors if highlight exists
					if S.chams then
						local hl=char2:FindFirstChild("KamidereChams")
						if not hl then
							applyChamsToChar(char2,p2)
						else
							hl.FillColor=S.chamsColor hl.OutlineColor=S.chamsColor hl.FillTransparency=S.chamsAlpha
							d.highlight=hl
						end
					else
						local hl=char2:FindFirstChild("KamidereChams")
						if hl then hl:Destroy() d.highlight=nil end
					end
					for _,tool in ipairs(char2:GetChildren()) do
						if tool:IsA("Tool") then updateEquippedToolChams(tool,S.chams) end
					end
					-- FORCEFIELD INDICATOR
					d.ffbb.Enabled=S.ffIndicator and (char2:FindFirstChildOfClass("ForceField")~=nil)
					-- HIT LOGS
					if S.hitlogs then
						local curHP=hum2.Health local prev=prevHP[p2]
						if prev and prev>curHP+0.5 then addHitLog("Hitting "..p2.Name.." = -"..math.floor(prev-curHP).." hp") end
						prevHP[p2]=curHP
					end
				else
					cleanESP(p2) removeBoxLines(p2) removeHPBar(p2) prevHP[p2]=nil
				end
			end
		elseif espRuntimeActive then
			for _,p2 in ipairs(Players:GetPlayers()) do if p2~=plr then cleanESP(p2) removeBoxLines(p2) removeHPBar(p2) prevHP[p2]=nil end end
		end
		espRuntimeActive=espAny
	end
	-- TARGET HUD
	local hud=sg:FindFirstChild("KamidereHUD")
	if hud and S.targetHUD then
		hud.BackgroundColor3=C("hudBg")
		local dn=hud:FindFirstChild("DisplayName")
		local un=hud:FindFirstChild("Username")
		local hp=hud:FindFirstChild("HP")
		local av=hud:FindFirstChild("Avatar")
		if dn then dn.TextColor3=C("hudText") end
		if un then un.TextColor3=C("hudDim") end
		if S.aimbotTarget and S.aimbotTarget.Character then
			local tgt=S.aimbotTarget local hum2=tgt.Character:FindFirstChild("Humanoid")
			if dn then dn.Text=tgt.DisplayName end
			if un then un.Text="@"..tgt.Name end
			if hp and hum2 then
				local h=math.floor(hum2.Health) local mh=math.floor(hum2.MaxHealth)
				hp.Text=h.." / "..mh.." HP"
				local ratio=h/math.max(mh,1) hp.TextColor3=Color3.fromRGB((1-ratio)*255,ratio*255,30)
			end
			if av and av:GetAttribute("lastTarget")~=tgt.UserId then
				av:SetAttribute("lastTarget",tgt.UserId) av.Image=""
				task.spawn(function()
					local ok,img=pcall(function() return Players:GetUserThumbnailAsync(tgt.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
					if ok and img and av.Parent then av.Image=img end
				end)
			end
		else
			if dn then dn.Text="No target" end
			if un then un.Text="" end
			if hp then hp.Text="" end
			if av then av.Image="" av:SetAttribute("lastTarget",nil) end
		end
	end
	-- WASD: poll physical keys every frame and animate only when state changes.
	local wi=sg:FindFirstChild("KamidereWASD")
	if wi and S.wasdInd then
		local wasdMap={W=Enum.KeyCode.W,A=Enum.KeyCode.A,S=Enum.KeyCode.S,D=Enum.KeyCode.D}
		for name,keyCode in pairs(wasdMap) do
			local label=wi:FindFirstChild("K_"..name)
			if label then
				local pressed=UIS:IsKeyDown(keyCode)
				label:SetAttribute("pressed",pressed)
				if label:GetAttribute("lastPressed")~=pressed then
					label:SetAttribute("lastPressed",pressed)
					TS:Create(label,TweenInfo.new(0.12,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						TextColor3=pressed and C("on") or C("hudText"),TextTransparency=0,TextSize=pressed and 21 or 18
					}):Play()
				end
			end
		end
	end
	-- HOTKEYS: immediate, non-overlapping active function rows.
	local ki=sg:FindFirstChild("KamidereKB")
	if ki and S.keybindInd then
		local holder=ki:FindFirstChild("KBRows")
		if holder then
			local wanted={
				Aimbot=S.aimbotOn and S.aimbotKeyActive and S.aimbotKey~=nil,
				Trigger=S.trigOn and S.trigKeyActive and S.trigKey~=nil,
				PixelSurf=S.pixelSurf and S.pixelSurfKeyActive and S.pixelSurfKey~=nil,
				EdgeBug=S.edgeBug and S.edgeBugKeyActive and S.edgeBugKey~=nil,
				EdgeJump=S.edgeJump and S.edgeJumpKeyActive and S.edgeJumpKey~=nil,
				JumpBug=S.jumpBug and S.jumpBugKeyActive and S.jumpBugKey~=nil,
			}
			local order={"Aimbot","Trigger","PixelSurf","EdgeBug","EdgeJump","JumpBug"}
			local visibleCount=0
			for _,name in ipairs(order) do
				local active=wanted[name]
				local row=holder:FindFirstChild(name)
				if active then
					visibleCount=visibleCount+1
					local targetY=(visibleCount-1)*25
					if not row then
						row=Instance.new("Frame",holder) row.Name=name
						row.Size=UDim2.new(1,0,0,22) row.Position=UDim2.new(0,0,0,targetY)
						row.BackgroundColor3=C("hudBg") row.BackgroundTransparency=0.04 row.BorderSizePixel=0 row.ZIndex=203
						Instance.new("UICorner",row).CornerRadius=UDim.new(0,3)
						local rowStroke=Instance.new("UIStroke",row) rowStroke.Name="RowStroke" rowStroke.Color=C("border") rowStroke.Transparency=0.22
						local action=Instance.new("TextLabel",row) action.Name="Action"
						action.Size=UDim2.new(1,-40,1,0) action.Position=UDim2.new(0,6,0,0)
						action.BackgroundTransparency=1 action.Text=name action.TextColor3=C("hudText")
						action.TextTransparency=1 action.TextSize=10 action.Font=Enum.Font.GothamMedium action.TextXAlignment=Enum.TextXAlignment.Left action.ZIndex=204
						local state=Instance.new("Frame",row) state.Name="State"
						state.Size=UDim2.new(0,22,0,12) state.Position=UDim2.new(1,-29,0.5,-6)
						state.BackgroundColor3=C("off") state.BackgroundTransparency=0.05 state.BorderSizePixel=0 state.ZIndex=204
						Instance.new("UICorner",state).CornerRadius=UDim.new(1,0)
						local dot=Instance.new("Frame",state) dot.Name="Dot"
						dot.Size=UDim2.new(0,8,0,8) dot.Position=UDim2.new(1,-10,0.5,-4)
						dot.BackgroundColor3=C("on") dot.BackgroundTransparency=0 dot.BorderSizePixel=0 dot.ZIndex=205
						Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
						TS:Create(action,TweenInfo.new(0.07),{TextTransparency=0}):Play()
					else
						row:SetAttribute("leaving",false)
						row.Position=UDim2.new(0,0,0,targetY)
					end
				elseif row and not row:GetAttribute("leaving") then
					row:SetAttribute("leaving",true)
					local action=row:FindFirstChild("Action")
					if action then TS:Create(action,TweenInfo.new(0.06),{TextTransparency=1}):Play() end
					TS:Create(row,TweenInfo.new(0.06),{BackgroundTransparency=1}):Play()
					task.delay(0.07,function() if row and row.Parent then row:Destroy() end end)
				end
			end
			ki.Size=UDim2.new(0,132,0,30+visibleCount*25)
		end
	end
end)
-- ============================================================
-- INPUT HANDLER — FIX: proper hold/toggle/always on per keybind
-- ============================================================
UIS.InputBegan:Connect(function(inp,gpe)
	if cheatDisabled or gpe or settingKey then return end
	-- Insert is handled by TenzodereUI.
	-- AIMBOT KEY
	if S.aimbotKey and inp.KeyCode==S.aimbotKey and S.aimbotOn then
		if S.aimbotKeyMode == "always on" then
			-- do nothing on keypress, handled in heartbeat
		elseif S.aimbotKeyMode == "toggle" then
			S.aimbotKeyActive = not S.aimbotKeyActive
			if S.aimbotKeyActive then
				aimbotRespawnTarget=nil requestAimbotTarget()
			else
				-- FIX: don't snap camera back, just clear target
				S.aimbotTarget = nil aimbotRespawnTarget=nil aimbotCachedTarget=nil aimbotCachedPoint=nil
			end
		else -- hold
			S.aimbotKeyActive = true
			aimbotRespawnTarget=nil requestAimbotTarget()
		end
	end
	-- JUMPBUG KEY
	if S.jumpBugKey and inp.KeyCode==S.jumpBugKey and S.jumpBug then
		if S.jumpBugKeyMode=="always on" then
		elseif S.jumpBugKeyMode=="toggle" then S.jumpBugKeyActive=not S.jumpBugKeyActive if S.jumpBugKeyActive then updateJumpBug() else restoreJumpBug() end
		else S.jumpBugKeyActive=true updateJumpBug() end
	end
	-- EDGEJUMP KEY
	if S.edgeJumpKey and inp.KeyCode==S.edgeJumpKey and S.edgeJump then
		if S.edgeJumpKeyMode=="always on" then
		elseif S.edgeJumpKeyMode=="toggle" then S.edgeJumpKeyActive=not S.edgeJumpKeyActive
		else S.edgeJumpKeyActive=true end
	end
	-- EDGEBUG KEY
	if S.edgeBugKey and inp.KeyCode==S.edgeBugKey and S.edgeBug then
		if S.edgeBugKeyMode=="always on" then
		elseif S.edgeBugKeyMode=="toggle" then S.edgeBugKeyActive=not S.edgeBugKeyActive
		else S.edgeBugKeyActive=true end
	end
	-- PIXEL SURF KEY
	if S.pixelSurfKey and inp.KeyCode==S.pixelSurfKey and S.pixelSurf then
		if S.pixelSurfKeyMode=="always on" then
		elseif S.pixelSurfKeyMode=="toggle" then S.pixelSurfKeyActive=not S.pixelSurfKeyActive if not S.pixelSurfKeyActive then stopPixelSurf(true) end
		else S.pixelSurfKeyActive=true end
	end
	-- TRIGGER KEY
	if S.trigKey and inp.KeyCode==S.trigKey and S.trigOn then
		if S.trigKeyMode == "always on" then
			-- handled in heartbeat
		elseif S.trigKeyMode == "toggle" then
			S.trigKeyActive = not S.trigKeyActive
		else -- hold
			S.trigKeyActive = true
		end
	end
end)
UIS.InputEnded:Connect(function(inp,gpe)
	if cheatDisabled or gpe then return end
	-- Only release if mode is "hold" — toggle and always on are not released here
	if S.aimbotKey and inp.KeyCode==S.aimbotKey and S.aimbotKeyMode=="hold" then
		S.aimbotKeyActive=false aimbotAcquireGeneration=aimbotAcquireGeneration+1
		-- FIX: don't snap camera, just stop locking
		S.aimbotTarget=nil aimbotCachedTarget=nil aimbotCachedPoint=nil aimbotRespawnTarget=nil
	end
	if S.trigKey and inp.KeyCode==S.trigKey and S.trigKeyMode=="hold" then
		S.trigKeyActive=false
	end
	if S.pixelSurfKey and inp.KeyCode==S.pixelSurfKey and S.pixelSurfKeyMode=="hold" then S.pixelSurfKeyActive=false stopPixelSurf(true) end
	if S.edgeBugKey and inp.KeyCode==S.edgeBugKey and S.edgeBugKeyMode=="hold" then S.edgeBugKeyActive=false end
	if S.edgeJumpKey and inp.KeyCode==S.edgeJumpKey and S.edgeJumpKeyMode=="hold" then S.edgeJumpKeyActive=false end
	if S.jumpBugKey and inp.KeyCode==S.jumpBugKey and S.jumpBugKeyMode=="hold" then S.jumpBugKeyActive=false restoreJumpBug() end
end)
-- Always on watcher
RS.Heartbeat:Connect(function()
	if cheatDisabled then return end
	if S.aimbotOn and S.aimbotKeyMode=="always on" then S.aimbotKeyActive=true end
	if S.aimbotOn and S.aimbotKeyActive then
		local target=S.aimbotTarget
		local character=target and target.Character local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if target and (not character or not humanoid or humanoid.Health<=0) then markAimbotTargetForRespawn() target=nil end
		if not S.aimbotTarget then
			local preferred=aimbotRespawnTarget local preferredCharacter=preferred and preferred.Character local preferredHumanoid=preferredCharacter and preferredCharacter:FindFirstChildOfClass("Humanoid")
			if preferred and preferredCharacter and preferredHumanoid and preferredHumanoid.Health>0 and isPlayerAllowed(preferred) and not isInSafeZone(preferredCharacter) then
				S.aimbotTarget=preferred aimbotRespawnTarget=nil aimbotCachedTarget=nil aimbotCachedPoint=nil aimbotPointNext=0
			elseif not preferred then requestAimbotTarget() end
		end
	end
	if S.trigOn and S.trigKeyMode=="always on" then S.trigKeyActive=true end
	if S.pixelSurf and S.pixelSurfKeyMode=="always on" then S.pixelSurfKeyActive=true end
	if S.edgeBug and S.edgeBugKeyMode=="always on" then S.edgeBugKeyActive=true end
	if S.edgeJump and S.edgeJumpKeyMode=="always on" then S.edgeJumpKeyActive=true end
	if S.jumpBug and S.jumpBugKeyMode=="always on" then S.jumpBugKeyActive=true end
end)
-- ============================================================
-- CHARACTER EVENTS
-- ============================================================
plr.CharacterAdded:Connect(function(char)
	if cheatDisabled then return end
	stopPixelSurf(false) restoreCounterStrikeMovement() restoreJumpBug()
	destroyFirstPersonViewmodel()
	S.aimbotTarget=nil S.aimbotKeyActive=false S.trigKeyActive=false S.edgeBugKeyActive=false S.edgeJumpKeyActive=false S.jumpBugKeyActive=false edgeJumpCooldown=0 edgeBugCooldown=0
	task.wait(0.5)
	if S.aura then createAura(char) end
	if S.motionTrail then createTrail(char) end
end)
Players.PlayerRemoving:Connect(function(p2)
	local bundle=deathWatchConnections[p2]
	if bundle then for _,connection in ipairs(bundle) do connection:Disconnect() end deathWatchConnections[p2]=nil end
	cleanESP(p2) removeBoxLines(p2) removeHPBar(p2) prevHP[p2]=nil removeToolESPLabel(p2)
	if S.aimbotTarget==p2 then S.aimbotTarget=nil aimbotCachedTarget=nil aimbotCachedPoint=nil end
	if aimbotRespawnTarget==p2 then aimbotRespawnTarget=nil end
end)
print("[KAMIDERE] loaded | INSERT to toggle")
