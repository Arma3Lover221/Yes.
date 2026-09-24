loadstring(game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua"))()
local Lib = (function() local e = getfenv() if e and e.INSUI then return e.INSUI end if _G.INSUI then return _G.INSUI end return nil end)()
assert(Lib and Lib.CreateWindow, "INS failed to load")
_G.CWGen = (_G.CWGen or 0) + 1
local myGen = _G.CWGen
pcall(function() local r = getfenv().Rem if r then r:Destroy() end end)
if _G.CWREM and _G.CWREM.hot then pcall(function() _G.CWREM.hot:Disconnect() end) end
if _G.CWINS and _G.CWINS.win then pcall(function() _G.CWINS.win:Destroy() end) end
if _G.CWESP and _G.CWESP.conn then pcall(function() _G.CWESP.conn:Disconnect() end) end
if _G.CWESP and _G.CWESP.pool then pcall(function() for _, e in ipairs(_G.CWESP.pool) do e.box:Remove() e.tag:Remove() e.line:Remove() end end) end
if _G.CWPESP and _G.CWPESP.conn then pcall(function() _G.CWPESP.conn:Disconnect() end) end
if _G.CWAIM and _G.CWAIM.conn then pcall(function() _G.CWAIM.conn:Disconnect() end) end
if _G.CWAIM and _G.CWAIM.circle then pcall(function() _G.CWAIM.circle:Remove() end) end
if _G.CWPPOOL then pcall(function() for _, d in pairs(_G.CWPPOOL) do d:Remove() end end) _G.CWPPOOL = nil end
if _G.CWSNAP and _G.CWSNAP.conn then pcall(function() _G.CWSNAP.conn:Disconnect() end) end
if _G.CWCHAMS then pcall(function() for _, h in ipairs(_G.CWCHAMS) do h:Remove() end end) _G.CWCHAMS = nil end
if _G.CWCRS and _G.CWCRS.conn then pcall(function() _G.CWCRS.conn:Disconnect() end) end
if _G.CWCRS and _G.CWCRS.lines then pcall(function() for _, l in ipairs(_G.CWCRS.lines) do l:Remove() end end) end
local CWPlayers = game:GetService("Players")
local CWRun = game:GetService("RunService")
local CWlp = CWPlayers.LocalPlayer
local CW_MULT = 0.28
local CW_TEAMCHECK = true
local CW_TEXTSIZE = 11
local CW_SNAP_FRAMES = 3
local CW_SNAP_MIN = 12
local CW_SNAP_MAX = 80
local CW_SPAWN_GRACE = 1.5
local noRecoil, vehESP, noSpread, playerESP, noSupp, fastADS, sprintAim, smoothSnap, sprintBoost, flatline, fatTracer, maxPen, crossTog = false, false, false, false, false, false, false, false, false, false, false, false, false
local adsTarget, boostTarget = 1, 1.1
local crsSize, crsGap, crsThick = 8, 4, 1
local spreadSave, flatSave, tracerSave, penSave = nil, nil, nil, nil
local lastVehCount = -1
local vehTargets = {}
local snapChar, snapLast, snapLeft, snapFrom, snapTo, snapGrace = nil, nil, 0, nil, nil, 0
local CWmsg, CWstance = "ready", "-"
local function gcApply(anchor, filter, writes)
local ok, res = pcall(function() return findgc(anchor, filter) end)
if not ok or not res or #res == 0 then return nil, 0 end
local save = { cache = res, items = {} }
for _, e in ipairs(res) do if writes[e.key] ~= nil and type(e.value) == "number" and e.addr then save.items[#save.items + 1] = { addr = e.addr, val = e.value, key = e.key } end end
if #save.items == 0 then return nil, 0 end
for k, v in pairs(writes) do pcall(function() applygc(res, k, v) end) end
return save, #res
end
local function gcRestore(save)
if not save then return 0, 0 end
local rd = 0
for _, s in ipairs(save.items) do if pcall(function() memory_write("double", s.addr, s.val) end) then rd = rd + 1 end end
return rd, #save.items
end
local function applyNoRecoil(on)
local ok, applied = pcall(function()
local ps = CWlp:FindFirstChild("PlayerScripts")
local bc = ps and ps:FindFirstChild("BallisticsClient")
local flag = bc and bc:FindFirstChild("DebugShotsGui")
if not flag then return false end
flag.Value = on
return flag.Value == on
end)
return ok and applied
end
local function median(ns)
if #ns == 0 then return nil end
table.sort(ns)
return ns[math.floor((#ns + 1) / 2)]
end
local win = Lib:CreateWindow({ title = "Cold War", size = Vector2.new(700, 520), menuKey = "p" })
win:AddSettingsTab("gear")
Lib:SetTheme({ bg = Color3.fromRGB(16, 11, 24), accentA = Color3.fromRGB(190, 160, 255), accentB = Color3.fromRGB(130, 80, 220) })
Lib:Category("COMBAT")
local combat = win:Tab("Combat", "sword")
local weapon = combat:Section("Weapon", "Left", "recoil + spread + flat")
local recoilT = weapon:Toggle("No-Recoil", false, function(v)
if applyNoRecoil(v) then noRecoil = v
else noRecoil = false pcall(function() recoilT:Set(false) end) end
end)
local spreadT = weapon:Toggle("No-Spread", false, function(v)
if v then
local save, n = gcApply("Damage", { Spread = "number", ShotAmount = "number", MuzzleVelocity = "number", Penetration = "number" }, { Spread = 0 })
if save then spreadSave = save noSpread = true
else pcall(function() spreadT:Set(false) end) end
else
gcRestore(spreadSave)
noSpread = false
end
end)
local flatT = weapon:Toggle("Flatline", false, function(v)
if v then
local ok, res = pcall(function() return findgc("Damage", { Spread = "number", ShotAmount = "number", MuzzleVelocity = "number", Penetration = "number" }) end)
if ok and res and #res > 0 then
local vs = {}
for _, e in ipairs(res) do if e.key == "MuzzleVelocity" and type(e.value) == "number" then vs[#vs + 1] = e.value end end
local mv = median(vs)
if mv and mv > 0 then
local nv = mv * 2.2
pcall(function() applygc(res, "MuzzleVelocity", nv) end)
flatSave = { cache = res, orig = mv } flatline = true
else pcall(function() flatT:Set(false) end) end
else pcall(function() flatT:Set(false) end) end
else
if flatSave then pcall(function() applygc(flatSave.cache, "MuzzleVelocity", flatSave.orig) end) end
flatline = false
end
end)
local penT = weapon:Toggle("Max Pen", false, function(v)
if v then
local save, n = gcApply("Damage", { Spread = "number", ShotAmount = "number", MuzzleVelocity = "number", Penetration = "number" }, { Penetration = 5 })
if save then penSave = save maxPen = true
else pcall(function() penT:Set(false) end) end
else
gcRestore(penSave)
maxPen = false
end
end)
local tracerT = weapon:Toggle("Fat Tracers", false, function(v)
if v then
local save, n = gcApply("MinStudWidth", { MinPixelWidth = "number" }, { MinPixelWidth = 6 })
if save then tracerSave = save fatTracer = true
else pcall(function() tracerT:Set(false) end) end
else
gcRestore(tracerSave)
fatTracer = false
end
end)
local steady = combat:Section("Steady", "Right", "suppression + aim move")
steady:Label(function() return "Stance: " .. CWstance end)
local suppT = steady:Toggle("No-Suppression", false, function(v)
noSupp = v
end)
local adsT = steady:Toggle("Fast ADS", false, function(v)
fastADS = v
end)
pcall(function() steady:Slider("ADS speed", 100, 5, 75, 100, "%", function(v) adsTarget = math.clamp((tonumber(v) or 100) / 100, 0.75, 1) end) end)
local sprintT = steady:Toggle("Sprint Aim", false, function(v)
sprintAim = v
end)
local boostT = steady:Toggle("Sprint Boost", false, function(v)
sprintBoost = v
end)
pcall(function() steady:Slider("Boost %", 110, 5, 100, 120, "%", function(v) boostTarget = math.clamp((tonumber(v) or 110) / 100, 1, 1.2) end) end)
local snapT = steady:Toggle("Smooth Snap", false, function(v)
smoothSnap = v
if not v then snapChar, snapLast, snapLeft, snapFrom, snapTo, snapGrace = nil, nil, 0, nil, nil, 0 end
end)
steady:Button("Reset all", function()
recoilT:Set(false) spreadT:Set(false) flatT:Set(false) penT:Set(false) tracerT:Set(false)
suppT:Set(false) adsT:Set(false) sprintT:Set(false) boostT:Set(false) snapT:Set(false)
if crsT then crsT:Set(false) end
if vehT then vehT:Set(false) end
if plrT then plrT:Set(false) end
end)
task.spawn(function()
while _G.CWGen == myGen do
if noSupp or fastADS or sprintAim or sprintBoost then
pcall(function()
local char = CWlp.Character
local cv = char and char:FindFirstChild("CharacterValues")
if cv then
local st = cv:FindFirstChild("Stance")
CWstance = (st and st.Value) or "-"
if noSupp then
local s = cv:FindFirstChild("Suppression")
if s and s.Value ~= 0 then s.Value = 0 end
local k = cv:FindFirstChild("Shock")
if k and k.Value ~= 0 then k.Value = 0 end
end
if fastADS then
local m = cv:FindFirstChild("SpeedMultiplier")
if m and m.Value < adsTarget then m.Value = adsTarget end
end
if sprintBoost then
local m2 = cv:FindFirstChild("SpeedMultiplier")
if m2 and m2.Value < boostTarget then m2.Value = boostTarget end
end
if sprintAim then
if st and (st.Value == "Run" or st.Value == "Sprint") then st.Value = "Walk" end
end
else CWstance = "-" end
end)
else
pcall(function()
local char = CWlp.Character
local cv = char and char:FindFirstChild("CharacterValues")
local st = cv and cv:FindFirstChild("Stance")
CWstance = (st and st.Value) or "-"
end)
end
task.wait(0.15)
end
end)
local snapConn
snapConn = CWRun.Heartbeat:Connect(function()
if _G.CWGen ~= myGen or not smoothSnap then return end
local char = CWlp.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local hum = char and char:FindFirstChildOfClass("Humanoid")
if not root or not hum or hum.Health <= 0 then
snapChar, snapLast, snapLeft, snapFrom, snapTo, snapGrace = nil, nil, 0, nil, nil, 0
return
end
if char ~= snapChar then
snapChar = char
snapLast, snapLeft, snapFrom, snapTo = nil, 0, nil, nil
snapGrace = os.clock() + CW_SPAWN_GRACE
return
end
if os.clock() < snapGrace then snapLast = root.Position return end
if snapLeft > 0 and snapFrom and snapTo then
root.CFrame = snapFrom:Lerp(snapTo, 1 - (snapLeft / CW_SNAP_FRAMES))
snapLeft = snapLeft - 1
if snapLeft <= 0 then snapFrom, snapTo = nil, nil end
snapLast = root.Position
return
end
if snapLast then
local d = (root.Position - snapLast).Magnitude
if d > CW_SNAP_MIN and d <= CW_SNAP_MAX then
snapFrom = CFrame.new(snapLast.X, snapLast.Y, snapLast.Z) * (root.CFrame - root.CFrame.Position)
snapTo = root.CFrame
snapLeft = CW_SNAP_FRAMES
end
end
snapLast = root.Position
end)
_G.CWSNAP = { conn = snapConn }
Lib:Category("VISUALS")
local visuals = win:Tab("Visuals", "eye")
local esp = visuals:Section("ESP", "Left", "boxes, tracers, distance")
local vehT = esp:Toggle("Vehicle ESP", false, function(v)
vehESP = v
end)
local plrT = esp:Toggle("Player distance ESP", false, function(v)
playerESP = v
end)
_G.CWPPOOL = {}
local cwPool, cwCache = _G.CWPPOOL, {}
local function cwGetText(pName)
if not cwPool[pName] then
local d = Drawing.new("Text")
d.Visible = false
d.Center = true
d.Outline = true
d.Color = Color3.fromRGB(255, 255, 255)
d.Size = CW_TEXTSIZE
cwPool[pName] = d
end
return cwPool[pName]
end
local function cwTeammate(plr)
if not CW_TEAMCHECK then return false end
local a = CWlp.Team and CWlp.Team.Name or nil
local b = plr.Team and plr.Team.Name or nil
return a ~= nil and a == b
end
local function cwProject(worldPos, camera)
local vs = camera.ViewportSize
if not vs or vs.X <= 0 or vs.Y <= 0 then return Vector2.new(0, 0), false end
local fovRad = math.rad(camera.FieldOfView or 70)
local cf = camera.CFrame
if not cf then return Vector2.new(0, 0), false end
local rel = worldPos - cf.Position
local z = rel:Dot(cf.LookVector)
if z <= 0.1 then return Vector2.new(0, 0), false end
local x = rel:Dot(cf.RightVector)
local y = rel:Dot(cf.UpVector)
local h = z * math.tan(fovRad / 2)
local w = h * (vs.X / vs.Y)
if w == 0 or h == 0 then return Vector2.new(0, 0), false end
return Vector2.new((vs.X / 2) + (x / w) * (vs.X / 2), (vs.Y / 2) - (y / h) * (vs.Y / 2)), true
end
task.spawn(function()
while _G.CWGen == myGen do
if playerESP then
task.wait(0.3)
pcall(function()
local current = {}
for _, plr in ipairs(CWPlayers:GetPlayers()) do
if plr ~= CWlp then
local pName = plr.Name
current[pName] = true
if cwTeammate(plr) then
cwCache[pName] = nil
if cwPool[pName] then cwPool[pName].Visible = false end
else
local char = plr.Character
if char then
local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")
cwCache[pName] = (head and hum) and { head = head, humanoid = hum } or nil
else cwCache[pName] = nil end
end
end
end
for pName in pairs(cwCache) do
if not current[pName] then
cwCache[pName] = nil
if cwPool[pName] then cwPool[pName].Visible = false cwPool[pName]:Remove() cwPool[pName] = nil end
end
end
end)
else
for _, d in pairs(cwPool) do d.Visible = false end
task.wait(0.5)
end
end
end)
local pconn
pconn = CWRun.RenderStepped:Connect(function()
if _G.CWGen ~= myGen or not playerESP then return end
local camera = workspace.CurrentCamera
local myChar = CWlp and CWlp.Character
local myHead = myChar and (myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart"))
if not camera or not myHead or not myHead.Parent then
for _, d in pairs(cwPool) do d.Visible = false end
return
end
local myPos = myHead.Position
for pName, data in pairs(cwCache) do
local d = cwGetText(pName)
local ok = pcall(function()
if data and data.head and data.head.Parent and data.humanoid and data.humanoid.Health > 0 then
local tp = data.head.Position + Vector3.new(0, 1.2, 0)
if (myPos - tp).Magnitude > 1 then
local sp, vis = cwProject(tp, camera)
if vis then
local txt = string.format("[%dm]", math.floor((myPos - tp).Magnitude * CW_MULT))
if d.Text ~= txt then d.Text = txt end
d.Position = Vector2.new(sp.X, sp.Y)
d.Visible = true
return
end
end
end
d.Visible = false
end)
if not ok then d.Visible = false end
end
end)
_G.CWPESP = { conn = pconn }
local VPOOL = 16
local vpool = {}
for i = 1, VPOOL do
local b = Drawing.new("Square")
b.Thickness = 1 b.Filled = false
b.Color = Color3.fromRGB(255, 255, 255) b.Visible = false
local t = Drawing.new("Text")
t.Size = 13 t.Center = true t.Outline = true t.Visible = false
local l = Drawing.new("Line")
l.Thickness = 1 l.Visible = false
vpool[i] = { box = b, tag = t, line = l }
end
task.spawn(function()
while _G.CWGen == myGen do
if vehESP then
local out = {}
local myChar = CWlp.Character
local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
local myPos = myRoot and myRoot.Position or nil
local myTeam = CWlp.Team and CWlp.Team.Name or nil
local vf = nil
pcall(function() vf = workspace:FindFirstChild("Vehicles") end)
local kids = (vf and vf:GetChildren()) or {}
for _, m in ipairs(kids) do
if #out >= VPOOL then break end
if m.ClassName == "Model" then
local part = nil
pcall(function() part = m:FindFirstChild("RootPart") or m:FindFirstChild("Body") end)
if part and part.Parent then
local dist = 0
if myPos then dist = math.floor((part.Position - myPos).Magnitude + 0.5) end
local col = Color3.fromRGB(200, 200, 200)
local own = nil
pcall(function() own = m:GetAttribute("Owner") end)
if own and myTeam then
local ownerTeam = nil
for _, p in ipairs(CWPlayers:GetPlayers()) do
if p.Name == own then ownerTeam = p.Team and p.Team.Name or nil break end
end
if ownerTeam == myTeam then col = Color3.fromRGB(90, 255, 130)
elseif ownerTeam then col = Color3.fromRGB(255, 90, 90) end
end
local label = m.Name .. " " .. dist .. "m"
if own then label = label .. " [" .. own .. "]" end
out[#out + 1] = { tag = label, part = part, col = col }
end
end
end
vehTargets = out
else
vehTargets = {}
end
task.wait(0.5)
end
end)
local vconn
vconn = CWRun.RenderStepped:Connect(function()
local list = vehESP and vehTargets or nil
local n = 0
if list then
local cam = workspace.CurrentCamera
local vs = cam and cam.ViewportSize or nil
for i = 1, #list do
if n >= VPOOL then break end
local t = list[i]
local part = t.part
if part and part.Parent then
local top, visT = WorldToScreen(part.Position + Vector3.new(0, 2.5, 0))
if visT then
local bot, visB = WorldToScreen(part.Position - Vector3.new(0, 1.5, 0))
if visB then
local h = bot.Y - top.Y
if h > 4 then
n = n + 1
local e = vpool[n]
local w = h * 0.6
e.box.Position = Vector2.new(top.X - w * 0.5, top.Y)
e.box.Size = Vector2.new(w, h)
e.box.Color = t.col
e.box.Visible = true
e.tag.Text = t.tag
e.tag.Position = Vector2.new(top.X, top.Y - 16)
e.tag.Visible = true
if vs then
e.line.From = Vector2.new(vs.X * 0.5, vs.Y)
e.line.To = Vector2.new(bot.X, bot.Y)
e.line.Color = t.col
e.line.Visible = true
end
end
end
end
end
end
end
for i = n + 1, VPOOL do
vpool[i].box.Visible = false
vpool[i].tag.Visible = false
vpool[i].line.Visible = false
end
end)
_G.CWESP = { conn = vconn, pool = vpool }
local cross = win:Tab("Crosshairs", "crosshair")
local crs = cross:Section("Crosshair", "Left", "center overlay")
local crsT = crs:Toggle("Crosshair", false, function(v)
crossTog = v
end)
pcall(function() crs:Slider("Size", 8, 1, 4, 30, "px", function(v) crsSize = math.clamp(math.floor((tonumber(v) or 8) + 0.5), 4, 30) end) end)
pcall(function() crs:Slider("Gap", 4, 1, 1, 15, "px", function(v) crsGap = math.clamp(math.floor((tonumber(v) or 4) + 0.5), 1, 15) end) end)
pcall(function() crs:Slider("Thickness", 1, 1, 1, 4, "px", function(v) crsThick = math.clamp(math.floor((tonumber(v) or 1) + 0.5), 1, 4) end) end)
local crsLines = {}
for i = 1, 4 do
local l = Drawing.new("Line")
l.Thickness = 1
l.Color = Color3.fromRGB(255, 255, 255)
l.Visible = false
crsLines[i] = l
end
local cconn
cconn = CWRun.RenderStepped:Connect(function()
if _G.CWGen ~= myGen or not crossTog then
for i = 1, 4 do crsLines[i].Visible = false end
return
end
local cam = workspace.CurrentCamera
if not cam then return end
local vs = cam.ViewportSize
local cx, cy = vs.X * 0.5, vs.Y * 0.5
local t, u, v, w = crsLines[1], crsLines[2], crsLines[3], crsLines[4]
t.From = Vector2.new(cx, cy - crsGap - crsSize)
t.To = Vector2.new(cx, cy - crsGap)
u.From = Vector2.new(cx, cy + crsGap)
u.To = Vector2.new(cx, cy + crsGap + crsSize)
v.From = Vector2.new(cx - crsGap - crsSize, cy)
v.To = Vector2.new(cx - crsGap, cy)
w.From = Vector2.new(cx + crsGap, cy)
w.To = Vector2.new(cx + crsGap + crsSize, cy)
for i = 1, 4 do crsLines[i].Thickness = crsThick crsLines[i].Visible = true end
end)
_G.CWCRS = { conn = cconn, lines = crsLines }
_G.CWINS = { win = win }
Lib:Notify("Cold War", "v7.8.1 ready", 4, "success")
print("Cold War x INS v7.8.1 ready.")