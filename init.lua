--!nocheck
-- TenzodereUI — dark Roblox/Luau UI library
-- Replace YOUR_NAME below after uploading this folder to GitHub.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local Http=game:GetService("HttpService")

local LUCIDE_URL="https://raw.githubusercontent.com/YOUR_NAME/TenzodereUI/main/Lucide.lua"
local ok,Lucide=pcall(function() return loadstring(game:HttpGet(LUCIDE_URL))() end)
if not ok then
 Lucide={create=function(name,size,color)local f=Instance.new("TextLabel");f.BackgroundTransparency=1;f.Size=UDim2.fromOffset(size or 18,size or 18);f.Text="•";f.TextColor3=color or Color3.fromRGB(145,145,145);f.TextSize=size or 18;return f end}
 warn("TenzodereUI: Lucide.lua was not loaded. Update LUCIDE_URL.")
end

local Library={Version="1.0.0",Windows={}}
local C={bg=Color3.fromRGB(17,17,17),side=Color3.fromRGB(24,24,24),card=Color3.fromRGB(27,27,27),input=Color3.fromRGB(20,20,20),border=Color3.fromRGB(58,58,58),text=Color3.fromRGB(177,177,177),bright=Color3.fromRGB(242,242,242),muted=Color3.fromRGB(126,126,126)}
local function new(class,props,parent)local o=Instance.new(class);for k,v in pairs(props or {})do o[k]=v end;o.Parent=parent;return o end
local function corner(o,r)new("UICorner",{CornerRadius=UDim.new(0,r or 8)},o)end
local function stroke(o,color,t)new("UIStroke",{Color=color or C.border,Thickness=t or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},o)end
local function tween(o,t,p)return TS:Create(o,TweenInfo.new(t or .2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p)end
local function label(parent,text,size,pos,align)local x=new("TextLabel",{BackgroundTransparency=1,Text=text or "",TextColor3=C.text,TextSize=size or 14,Font=Enum.Font.Code,TextXAlignment=align or Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,26),Position=pos or UDim2.new()},parent);return x end
local function click(parent)local b=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=20,AutoButtonColor=false},parent);return b end
local function addIcon(parent,name,pos,size,color)local i=Lucide.create(name,size or 17,color or C.muted);i.Position=pos or UDim2.new();i.Parent=parent;return i end
local function drag(gui,handle)
 local dragging,start,origin
 handle.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;start=i.Position;origin=gui.Position end end)
 UIS.InputChanged:Connect(function(i)if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-start;gui.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)end end)
 UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
end
local function round(v)return math.floor(v+.5)end

function Library:CreateWindow(opt)
 opt=opt or {};local accent=opt.Accent or Color3.fromRGB(245,170,239)
 local parent=(gethui and gethui()) or game:GetService("CoreGui")
 local gui=new("ScreenGui",{Name="TenzodereUI",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Global},parent)
 local main=new("Frame",{Name="Window",Size=UDim2.fromOffset(638,508),Position=UDim2.new(.5,-319,.5,-254),BackgroundColor3=C.bg,BorderSizePixel=0},gui);corner(main,16)
 local scaler=new("UIScale",{},main)
 local top=new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,34)},main);drag(main,top)
 label(top,opt.Name or "TENZODERE",12,UDim2.new(1,-150,0,3),Enum.TextXAlignment.Right).TextColor3=Color3.fromRGB(84,84,84)
 local side=new("Frame",{Size=UDim2.new(0,139,1,0),BackgroundColor3=C.side,BorderSizePixel=0},main)
 local sideRound=new("UICorner",{CornerRadius=UDim.new(0,16)},side)
 new("Frame",{Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),BackgroundColor3=C.side,BorderSizePixel=0},side)
 local nav=new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,34),Size=UDim2.new(1,0,1,-34)},side)
 new("UIListLayout",{Padding=UDim.new(0,1),SortOrder=Enum.SortOrder.LayoutOrder},nav)
 local pages=new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(139,28),Size=UDim2.new(1,-139,1,-28),ClipsDescendants=true},main)
 local window={Gui=gui,Main=main,Tabs={},Accent=accent,Visible=true,Values={},_state={}}
 table.insert(self.Windows,window)
 function window:SetVisible(value)
  if self._animating then return end;self._animating=true;self.Visible=value
  if value then main.Visible=true;scaler.Scale=.97
   for _,d in ipairs(main:GetDescendants())do if d:IsA("GuiObject") and d:GetAttribute("TenzAlpha")~=nil then d.BackgroundTransparency=1 end;if d:IsA("TextLabel") or d:IsA("TextButton") then d.TextTransparency=1 end;if d:IsA("ImageLabel") then d.ImageTransparency=1 end end
   tween(scaler,.28,{Scale=1}):Play()
   for _,d in ipairs(main:GetDescendants())do local a=d:GetAttribute("TenzAlpha");if a~=nil then tween(d,.24,{BackgroundTransparency=a}):Play()end;local ta=d:GetAttribute("TenzTextAlpha");if ta~=nil then tween(d,.24,{TextTransparency=ta}):Play()end end
   task.delay(.29,function()self._animating=false end)
  else
   tween(scaler,.22,{Scale=.97}):Play()
   for _,d in ipairs(main:GetDescendants())do if d:IsA("GuiObject") then if d:GetAttribute("TenzAlpha")==nil then d:SetAttribute("TenzAlpha",d.BackgroundTransparency)end;tween(d,.2,{BackgroundTransparency=1}):Play()end;if d:IsA("TextLabel") or d:IsA("TextButton") then if d:GetAttribute("TenzTextAlpha")==nil then d:SetAttribute("TenzTextAlpha",d.TextTransparency)end;tween(d,.18,{TextTransparency=1}):Play()end end
   task.delay(.22,function()main.Visible=false;self._animating=false end)
  end
 end
 UIS.InputBegan:Connect(function(i,gp)if not gp and i.KeyCode==(opt.Keybind or Enum.KeyCode.Insert)then window:SetVisible(not window.Visible)end end)
 function window:Destroy()gui:Destroy()end
 function window:SelectTab(tab)
  for _,t in ipairs(self.Tabs)do local active=t==tab;t.Page.Visible=active;t.Label.TextColor3=active and C.bright or C.text;t.Line.Visible=active end
 end
 function window:CreateTab(name,icon)
  local item=new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,36)},nav)
  addIcon(item,icon or "Settings",UDim2.fromOffset(20,9),17,C.muted)
  local tx=label(item,name,14,UDim2.fromOffset(49,5));tx.Size=UDim2.new(1,-55,0,26)
  local line=new("Frame",{Visible=false,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(3,17),BackgroundColor3=accent,BorderSizePixel=0},item);corner(line,3)
  local page=new("ScrollingFrame",{Visible=false,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=accent,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Size=UDim2.fromScale(1,1)},pages)
  local pad=new("UIPadding",{PaddingLeft=UDim.new(0,18),PaddingRight=UDim.new(0,18),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,20)},page)
  local grid=new("UIGridLayout",{CellSize=UDim2.new(.5,-5,0,0),CellPadding=UDim2.fromOffset(10,10),SortOrder=Enum.SortOrder.LayoutOrder,FillDirectionMaxCells=2},page)
  grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()grid.CellSize=UDim2.new(.5,-5,0,math.max(80,grid.AbsoluteContentSize.Y))end)
  local tab={Page=page,Button=item,Label=tx,Line=line,Window=window,_sections={}}
  table.insert(window.Tabs,tab);click(item).MouseButton1Click:Connect(function()window:SelectTab(tab)end)
  function tab:CreateSection(titleText)
   local wrap=new("Frame",{BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,0,0,0)},page)
   label(wrap,titleText or "Section",14,UDim2.fromOffset(0,0),Enum.TextXAlignment.Center).TextColor3=accent
   local card=new("Frame",{Position=UDim2.fromOffset(0,42),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.card,BorderSizePixel=0},wrap);corner(card,12)
   new("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,8)},card)
   new("UIListLayout",{Padding=UDim.new(0,1),SortOrder=Enum.SortOrder.LayoutOrder},card)
   local sec={Container=card,Tab=tab}
   local function row(n,h)local r=new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h or 40)},card);local l=label(r,n,14,UDim2.fromOffset(0,7));l.Size=UDim2.new(.5,0,0,26);return r,l end
   local function bindState(cfg,setter)local key=cfg.Flag or cfg.Name;if key then window._state[key]=setter end end
   function sec:CreateButton(cfg)
    cfg=cfg or {};local r,l=row(cfg.Name or "Button",40);local b=new("TextButton",{Text=cfg.ButtonText or "Add",TextColor3=C.text,TextSize=12,Font=Enum.Font.Code,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(68,22),BackgroundColor3=C.input,AutoButtonColor=false},r);corner(b,4);stroke(b)
    b.MouseEnter:Connect(function()tween(b,.15,{BackgroundColor3=Color3.fromRGB(35,35,35)}):Play()end);b.MouseLeave:Connect(function()tween(b,.15,{BackgroundColor3=C.input}):Play()end);b.MouseButton1Click:Connect(function()if cfg.Callback then task.spawn(cfg.Callback)end end);return b
   end
   function sec:CreateToggle(cfg)
    cfg=cfg or {};local value=cfg.Default==true;local r=row(cfg.Name or "Toggle",40);local box=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(17,17),BackgroundColor3=value and accent or C.input,BorderSizePixel=0},r);corner(box,4);stroke(box,value and accent or C.border)
    local check=addIcon(box,"Check",UDim2.fromOffset(3,3),11,C.bg);check.Visible=value
    local function set(v,silent)value=not not v;box.BackgroundColor3=value and accent or C.input;check.Visible=value;window.Values[cfg.Flag or cfg.Name]=value;if not silent and cfg.Callback then task.spawn(cfg.Callback,value)end end
    click(r).MouseButton1Click:Connect(function()set(not value)end);bindState(cfg,set);set(value,true);return{Set=set,Get=function()return value end}
   end
   function sec:CreateSlider(cfg)
    cfg=cfg or {};local min,max=cfg.Min or 0,cfg.Max or 100;local step=cfg.Increment or cfg.Step or 1;local value=math.clamp(cfg.Default or min,min,max);local r=row(cfg.Name or "Slider",41)
    local val=label(r,tostring(value),14,UDim2.new(1,-34,0,7),Enum.TextXAlignment.Right);val.Size=UDim2.fromOffset(34,26)
    local bar=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-49,.5,0),Size=UDim2.fromOffset(91,3),BackgroundColor3=Color3.fromRGB(79,79,79),BorderSizePixel=0},r)
    local fill=new("Frame",{Size=UDim2.fromScale((value-min)/(max-min),1),BackgroundColor3=accent,BorderSizePixel=0},bar)
    local knob=new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(12,12),BackgroundColor3=accent,BorderSizePixel=0},fill);corner(knob,12)
    local down=false
    local function set(v,silent)local raw=tonumber(v) or min;value=math.clamp(math.floor(raw/step+.5)*step,min,max);value=tonumber(string.format("%.4f",value));fill.Size=UDim2.fromScale((value-min)/(max-min),1);val.Text=tostring(value);window.Values[cfg.Flag or cfg.Name]=value;if not silent and cfg.Callback then task.spawn(cfg.Callback,value)end end
    local function move(x)set(min+(max-min)*math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1))end
    click(bar).InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then down=true;move(i.Position.X)end end);UIS.InputChanged:Connect(function(i)if down and i.UserInputType==Enum.UserInputType.MouseMovement then move(i.Position.X)end end);UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then down=false end end)
    bindState(cfg,set);set(value,true);return{Set=set,Get=function()return value end}
   end
   function sec:CreateDropdown(cfg)
    cfg=cfg or {};local options=cfg.Options or {};local value=cfg.Default or options[1] or "none";local r=row(cfg.Name or "Dropdown",41)
    local field=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(128,27),BackgroundColor3=C.input,BorderSizePixel=0},r);local under=new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,2),BackgroundColor3=accent,BorderSizePixel=0},field)
    local txt=label(field,tostring(value),11,UDim2.fromOffset(5,1));txt.Size=UDim2.new(1,-25,1,-2);addIcon(field,"ChevronDown",UDim2.new(1,-17,.5,-5),10,C.muted)
    local list=new("Frame",{Visible=false,Position=UDim2.new(0,0,1,3),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.input,BorderSizePixel=0,ZIndex=50},field);corner(list,4);stroke(list)
    new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},list)
    local function set(v,silent)value=v;txt.Text=tostring(v);list.Visible=false;window.Values[cfg.Flag or cfg.Name]=value;if not silent and cfg.Callback then task.spawn(cfg.Callback,value)end end
    for _,v in ipairs(options)do local o=new("TextButton",{Text=tostring(v),TextColor3=C.text,TextSize=11,Font=Enum.Font.Code,Size=UDim2.new(1,0,0,25),BackgroundTransparency=1,ZIndex=51},list);o.MouseButton1Click:Connect(function()set(v)end)end
    click(field).MouseButton1Click:Connect(function()list.Visible=not list.Visible end);bindState(cfg,set);set(value,true);return{Set=set,Get=function()return value end,Refresh=function(items)options=items end}
   end
   function sec:CreateKeybind(cfg)
    cfg=cfg or {};local value=cfg.Default or Enum.KeyCode.None;local r=row(cfg.Name or "Bind",40);local b=new("TextButton",{Text=value.Name,TextColor3=C.text,TextSize=11,Font=Enum.Font.Code,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(62,22),BackgroundColor3=C.input,AutoButtonColor=false},r);corner(b,4);stroke(b)
    local waiting=false;local function set(v,silent)value=v;b.Text=v.Name;window.Values[cfg.Flag or cfg.Name]=v.Name;if not silent and cfg.Callback then task.spawn(cfg.Callback,v)end end
    b.MouseButton1Click:Connect(function()waiting=true;b.Text="..."end);UIS.InputBegan:Connect(function(i,gp)if waiting then waiting=false;set(i.KeyCode)elseif not gp and i.KeyCode==value and cfg.Callback then task.spawn(cfg.Callback,value)end end);bindState(cfg,function(v)set(Enum.KeyCode[v] or Enum.KeyCode.None)end);set(value,true);return{Set=set,Get=function()return value end}
   end
   function sec:CreateColorPicker(cfg)
    cfg=cfg or {};local value=cfg.Default or Color3.fromRGB(128,133,255);local r=row(cfg.Name or "Color",41)
    local swatch=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(18,18),BackgroundColor3=value,BorderSizePixel=0},r);corner(swatch,4);stroke(swatch)
    local pop=new("Frame",{Visible=false,Position=UDim2.new(1,-275,1,4),Size=UDim2.fromOffset(270,190),BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,ZIndex=60},r);stroke(pop,Color3.fromRGB(0,0,0));label(pop,"Color",13,UDim2.fromOffset(14,8)).ZIndex=61
    local sv=new("ImageLabel",{Position=UDim2.fromOffset(14,42),Size=UDim2.fromOffset(160,125),BackgroundColor3=Color3.fromHSV(0,1,1),BorderSizePixel=0,Image="rbxassetid://4155801252",ZIndex=61},pop)
    local hue=new("Frame",{Position=UDim2.fromOffset(180,42),Size=UDim2.fromOffset(18,125),BorderSizePixel=0,ZIndex=61},pop);local grad=new("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(.17,Color3.fromHSV(.17,1,1)),ColorSequenceKeypoint.new(.33,Color3.fromHSV(.33,1,1)),ColorSequenceKeypoint.new(.5,Color3.fromHSV(.5,1,1)),ColorSequenceKeypoint.new(.67,Color3.fromHSV(.67,1,1)),ColorSequenceKeypoint.new(.83,Color3.fromHSV(.83,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1))})},hue)
    local h,s,v=value:ToHSV();local active=nil
    local function setColor(c,silent)value=c;swatch.BackgroundColor3=c;h,s,v=c:ToHSV();sv.BackgroundColor3=Color3.fromHSV(h,1,1);window.Values[cfg.Flag or cfg.Name]={round(c.R*255),round(c.G*255),round(c.B*255)};if not silent and cfg.Callback then task.spawn(cfg.Callback,c)end end
    local function update(pos)if active=="h"then h=math.clamp((pos.Y-hue.AbsolutePosition.Y)/hue.AbsoluteSize.Y,0,1)else s=math.clamp((pos.X-sv.AbsolutePosition.X)/sv.AbsoluteSize.X,0,1);v=1-math.clamp((pos.Y-sv.AbsolutePosition.Y)/sv.AbsoluteSize.Y,0,1)end;setColor(Color3.fromHSV(h,s,v))end
    click(swatch).MouseButton1Click:Connect(function()pop.Visible=not pop.Visible end);sv.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then active="sv";update(i.Position)end end);hue.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then active="h";update(i.Position)end end);UIS.InputChanged:Connect(function(i)if active and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position)end end);UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then active=nil end end)
    bindState(cfg,function(t)if typeof(t)=="table"then setColor(Color3.fromRGB(t[1],t[2],t[3]))end end);setColor(value,true);return{Set=setColor,Get=function()return value end}
   end
   table.insert(tab._sections,sec);return sec
  end
  if #window.Tabs==1 then window:SelectTab(tab)end
  return tab
 end
 function window:CreateConfigManager(cfg)
  cfg=cfg or {};local tab=self.Tabs[#self.Tabs] or self:CreateTab("Configs","Settings");local sec=tab:CreateSection("Config name");local name=cfg.DefaultName or "default.cfg";local folder=cfg.Folder or "TenzodereUI"
  local box=new("TextBox",{Text=name,PlaceholderText="Config name",TextColor3=C.text,PlaceholderColor3=C.muted,TextSize=13,Font=Enum.Font.Code,ClearTextOnFocus=false,Size=UDim2.new(1,0,0,31),BackgroundColor3=C.input,BorderSizePixel=0},sec.Container);corner(box,5)
  sec:CreateButton({Name="Load config",ButtonText="Load",Callback=function()if isfile and readfile and isfile(folder.."/"..box.Text)then local data=Http:JSONDecode(readfile(folder.."/"..box.Text));for k,v in pairs(data)do if self._state[k]then self._state[k](v)end end end end})
  sec:CreateButton({Name="Save config",ButtonText="Save",Callback=function()if makefolder and writefile then pcall(makefolder,folder);writefile(folder.."/"..box.Text,Http:JSONEncode(self.Values))end end})
  sec:CreateButton({Name="Remove config",ButtonText="Remove",Callback=function()if delfile and isfile and isfile(folder.."/"..box.Text)then delfile(folder.."/"..box.Text)end end})
  return sec
 end
 return window
end
return Library
