--!nocheck
-- TenzodereUI v2 — stable, low-overhead Luau UI library
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local Http=game:GetService("HttpService")
local LUCIDE_URL="https://raw.githubusercontent.com/tenzarek/TenzodereUI/main/Lucide.lua"
local ok,Lucide=pcall(function()return loadstring(game:HttpGet(LUCIDE_URL))()end)
if not ok then Lucide={create=function(_,s,c)local x=Instance.new("Frame");x.BackgroundTransparency=1;x.Size=UDim2.fromOffset(s or 18,s or 18);return x end}end

local Library={Version="2.0.0"}
local Theme={BG=Color3.fromRGB(15,15,15),Sidebar=Color3.fromRGB(24,24,24),Card=Color3.fromRGB(27,27,27),Field=Color3.fromRGB(20,20,20),Hover=Color3.fromRGB(34,34,34),Border=Color3.fromRGB(60,60,60),Text=Color3.fromRGB(174,174,174),Bright=Color3.fromRGB(242,242,242),Muted=Color3.fromRGB(122,122,122)}
local function N(class,p,parent)local x=Instance.new(class);for k,v in pairs(p or {})do x[k]=v end;x.Parent=parent;return x end
local function Corner(x,r)N("UICorner",{CornerRadius=UDim.new(0,r or 8)},x)end
local function Stroke(x,c,t)N("UIStroke",{Color=c or Theme.Border,Thickness=t or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},x)end
local function Tween(x,t,p)local tw=TS:Create(x,TweenInfo.new(t or .18,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p);tw:Play();return tw end
local function Label(parent,text,size,pos)
 return N("TextLabel",{BackgroundTransparency=1,Text=text or "",TextColor3=Theme.Text,TextSize=size or 13,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,Size=UDim2.new(1,0,0,28),Position=pos or UDim2.new()},parent)
end
local function Hit(parent,z)return N("TextButton",{Text="",BackgroundTransparency=1,AutoButtonColor=false,Size=UDim2.fromScale(1,1),ZIndex=z or 20},parent)end
local function Icon(parent,name,pos,size,color)local i=Lucide.create(name,size or 17,color or Theme.Muted);i.Position=pos or UDim2.new();i.Parent=parent;return i end
local function Round(v,step)local s=step or 1;return tonumber(string.format("%.4f",math.floor(v/s+.5)*s))end

function Library:CreateWindow(opt)
 opt=opt or {};local accent=opt.Accent or Color3.fromRGB(245,170,239)
 local host=(gethui and gethui()) or game:GetService("CoreGui")
 local gui=N("ScreenGui",{Name="TenzodereUI",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=100000,ZIndexBehavior=Enum.ZIndexBehavior.Global},host)
 local group=N("CanvasGroup",{Name="Window",Size=UDim2.fromOffset(848,680),Position=UDim2.new(.5,-424,.5,-340),BackgroundColor3=Theme.BG,BorderSizePixel=0,GroupTransparency=0,ClipsDescendants=false},gui);Corner(group,14)
 local scale=N("UIScale",{Scale=1},group);local fit=1
 local function resize()local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080);fit=math.min(1,(vp.X-30)/848,(vp.Y-30)/680);scale.Scale=fit end
 resize();if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)end
 local top=N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,38),ZIndex=2},group)
 local brand=Label(top,opt.Name or "TENZODERE",12,UDim2.new(1,-170,0,1));brand.Size=UDim2.fromOffset(150,24);brand.TextXAlignment=Enum.TextXAlignment.Right;brand.TextColor3=Color3.fromRGB(82,82,82)
 local sidebar=N("Frame",{Size=UDim2.new(0,156,1,0),BackgroundColor3=Theme.Sidebar,BorderSizePixel=0,ClipsDescendants=true},group);Corner(sidebar,14)
 N("Frame",{Position=UDim2.new(1,-14,0,0),Size=UDim2.new(0,14,1,0),BackgroundColor3=Theme.Sidebar,BorderSizePixel=0},sidebar)
 local nav=N("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,38),Size=UDim2.new(1,0,1,-38)},sidebar)
 N("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},nav)
 local pages=N("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(156,38),Size=UDim2.new(1,-156,1,-38),ClipsDescendants=true},group)
 local overlay=N("Frame",{Name="Overlay",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=1000},gui)
 local window={Gui=gui,Main=group,Accent=accent,Tabs={},Values={},_state={},Visible=true,_popup=nil,_activeDrag=nil,_capture=nil}
 -- one input pipeline for the whole window
 UIS.InputChanged:Connect(function(i)
  local d=window._activeDrag
  if d and i.UserInputType==Enum.UserInputType.MouseMovement then d.move(i.Position)end
 end)
 UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then window._activeDrag=nil end end)
 UIS.InputBegan:Connect(function(i,gp)
  if window._capture and i.UserInputType==Enum.UserInputType.Keyboard then local c=window._capture;window._capture=nil;c(i.KeyCode);return end
  if not gp and i.KeyCode==(opt.Keybind or Enum.KeyCode.Insert)then window:SetVisible(not window.Visible)end
 end)
 local dragging,dragStart,startPos=false,nil,nil
 top.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;dragStart=i.Position;startPos=group.Position;window._activeDrag={move=function(pos)local d=pos-dragStart;group.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)end}end end)
 function window:ClosePopup()if self._popup then self._popup:Destroy();self._popup=nil end end
 function window:SetVisible(v)
  if self._animating or self.Visible==v then return end;self._animating=true;self.Visible=v;self:ClosePopup()
  if v then group.Visible=true;group.GroupTransparency=1;scale.Scale=fit*.97;Tween(group,.24,{GroupTransparency=0});Tween(scale,.24,{Scale=fit});task.delay(.25,function()self._animating=false end)
  else local tw=Tween(group,.2,{GroupTransparency=1});task.delay(.21,function()group.Visible=false;self._animating=false end)end
 end
 function window:Destroy()gui:Destroy();overlay:Destroy()end
 function window:SelectTab(tab)self:ClosePopup();for _,t in ipairs(self.Tabs)do local a=t==tab;t.Page.Visible=a;t.Text.TextColor3=a and Theme.Bright or Theme.Text;t.Mark.Visible=a end end
 local function popupFrame(anchor,w,h)
  window:ClosePopup();local ap=anchor.AbsolutePosition;local as=anchor.AbsoluteSize
  local p=N("Frame",{Position=UDim2.fromOffset(ap.X,ap.Y+as.Y+4),Size=UDim2.fromOffset(w,h),BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,ZIndex=1001},overlay);Corner(p,5);Stroke(p,Color3.fromRGB(45,45,45));window._popup=p;return p
 end
 function window:CreateTab(name,icon)
  local b=N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,40)},nav);Icon(b,icon or "Settings",UDim2.fromOffset(26,11),17,Theme.Muted)
  local tx=Label(b,name,14,UDim2.fromOffset(54,5));tx.Size=UDim2.new(1,-60,0,30)
  local mark=N("Frame",{Visible=false,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(3,18),BackgroundColor3=accent,BorderSizePixel=0},b);Corner(mark,3)
  local page=N("Frame",{Visible=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},pages)
  local left=N("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(20,0),Size=UDim2.new(.5,-25,1,0),ScrollBarThickness=2,ScrollBarImageColor3=accent,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},page)
  local right=N("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(.5,5,0,0),Size=UDim2.new(.5,-25,1,0),ScrollBarThickness=2,ScrollBarImageColor3=accent,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},page)
  for _,col in ipairs({left,right})do N("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,24)},col);N("UIListLayout",{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},col)end
  local tab={Page=page,Text=tx,Mark=mark,Left=left,Right=right,Window=window,_next=0}
  table.insert(self.Tabs,tab);Hit(b).MouseButton1Click:Connect(function()window:SelectTab(tab)end)
  function tab:CreateSection(title)
   self._next+=1;local col=(self._next%2==1)and self.Left or self.Right
   local wrap=N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y},col)
   local head=Label(wrap,title or "Section",14,UDim2.fromOffset(0,0));head.Size=UDim2.new(1,0,0,32);head.TextXAlignment=Enum.TextXAlignment.Center;head.TextColor3=accent
   local card=N("Frame",{Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Theme.Card,BorderSizePixel=0},wrap);Corner(card,11)
   N("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7)},card)
   N("UIListLayout",{Padding=UDim.new(0,1),SortOrder=Enum.SortOrder.LayoutOrder},card)
   local sec={Container=card,Window=window}
   local function row(name,h)
    local r=N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h or 41)},card)
    local l=Label(r,name,13,UDim2.fromOffset(0,6));l.Size=UDim2.new(.52,-8,0,29);return r,l
   end
   local function state(cfg,set)window._state[cfg.Flag or cfg.Name]=set end
   function sec:CreateButton(cfg)
    cfg=cfg or {};local r,l=row(cfg.Name or "Button");local b=N("TextButton",{Text=cfg.ButtonText or "Add",TextColor3=Theme.Text,TextSize=11,Font=Enum.Font.Code,AutoButtonColor=false,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(70,23),BackgroundColor3=Theme.Field,BorderSizePixel=0},r);Corner(b,4);Stroke(b)
    b.MouseEnter:Connect(function()Tween(b,.12,{BackgroundColor3=Theme.Hover})end);b.MouseLeave:Connect(function()Tween(b,.12,{BackgroundColor3=Theme.Field})end);b.MouseButton1Click:Connect(function()if cfg.Callback then task.spawn(cfg.Callback)end end);return b
   end
   function sec:CreateToggle(cfg)
    cfg=cfg or {};local value=cfg.Default==true;local r=row(cfg.Name or "Toggle");local box=N("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(18,18),BackgroundColor3=value and accent or Theme.Field,BorderSizePixel=0},r);Corner(box,4);Stroke(box,value and accent or Theme.Border)
    local check=Icon(box,"Check",UDim2.fromOffset(3,3),12,Theme.BG);check.Visible=value
    local function set(v,silent)value=v==true;box.BackgroundColor3=value and accent or Theme.Field;check.Visible=value;window.Values[cfg.Flag or cfg.Name]=value;if not silent and cfg.Callback then task.spawn(cfg.Callback,value)end end
    Hit(r).MouseButton1Click:Connect(function()set(not value)end);state(cfg,set);set(value,true);return{Set=set,Get=function()return value end,Root=r}
   end
   function sec:CreateSlider(cfg)
    cfg=cfg or {};local min,max,step=cfg.Min or 0,cfg.Max or 100,cfg.Increment or cfg.Step or 1;local value=math.clamp(cfg.Default or min,min,max);local r=row(cfg.Name or "Slider")
    local val=Label(r,tostring(value),13,UDim2.new(1,-35,0,6));val.Size=UDim2.fromOffset(35,29);val.TextXAlignment=Enum.TextXAlignment.Right
    local bar=N("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-49,.5,0),Size=UDim2.fromOffset(92,3),BackgroundColor3=Color3.fromRGB(79,79,79),BorderSizePixel=0},r)
    local fill=N("Frame",{Size=UDim2.fromScale((value-min)/(max-min),1),BackgroundColor3=accent,BorderSizePixel=0},bar);local knob=N("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(12,12),BackgroundColor3=accent,BorderSizePixel=0},fill);Corner(knob,12)
    local function set(v,silent)value=math.clamp(Round(tonumber(v)or min,step),min,max);fill.Size=UDim2.fromScale((value-min)/(max-min),1);val.Text=tostring(value);window.Values[cfg.Flag or cfg.Name]=value;if not silent and cfg.Callback then task.spawn(cfg.Callback,value)end end
    local function move(pos)set(min+(max-min)*math.clamp((pos.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1))end
    Hit(bar).InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then move(i.Position);window._activeDrag={move=move}end end);state(cfg,set);set(value,true);return{Set=set,Get=function()return value end,Root=r}
   end
   function sec:CreateDropdown(cfg)
    cfg=cfg or {};local opts=cfg.Options or {};local value=cfg.Default or opts[1] or "none";local r=row(cfg.Name or "Dropdown");local f=N("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(128,27),BackgroundColor3=Theme.Field,BorderSizePixel=0},r);N("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,2),BackgroundColor3=accent,BorderSizePixel=0},f)
    local text=Label(f,tostring(value),11,UDim2.fromOffset(5,0));text.Size=UDim2.new(1,-23,1,-2);Icon(f,"ChevronDown",UDim2.new(1,-17,.5,-5),10,Theme.Muted)
    local function set(v,silent)value=v;text.Text=tostring(v);window:ClosePopup();window.Values[cfg.Flag or cfg.Name]=v;if not silent and cfg.Callback then task.spawn(cfg.Callback,v)end end
    Hit(f).MouseButton1Click:Connect(function()local p=popupFrame(f,128,math.min(#opts*26+6,188));local sc=N("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=accent,ZIndex=1002},p);N("UIPadding",{PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,3)},sc);N("UIListLayout",{},sc);for _,v in ipairs(opts)do local b=N("TextButton",{Text=tostring(v),TextColor3=v==value and accent or Theme.Text,TextSize=11,Font=Enum.Font.Code,BackgroundTransparency=1,Size=UDim2.new(1,-4,0,26),ZIndex=1003},sc);b.MouseButton1Click:Connect(function()set(v)end)end end)
    state(cfg,set);set(value,true);return{Set=set,Get=function()return value end,Root=r}
   end
   function sec:CreateMultiDropdown(cfg)
    cfg=cfg or {};local opts=cfg.Options or {};local selected={};for _,v in ipairs(cfg.Default or {})do selected[v]=true end;local r=row(cfg.Name or "Select");local f=N("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(128,27),BackgroundColor3=Theme.Field,BorderSizePixel=0},r);N("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,2),BackgroundColor3=accent,BorderSizePixel=0},f);local text=Label(f,"",11,UDim2.fromOffset(5,0));text.Size=UDim2.new(1,-23,1,-2);Icon(f,"ChevronDown",UDim2.new(1,-17,.5,-5),10,Theme.Muted)
    local function get()local out={}for _,v in ipairs(opts)do if selected[v]then table.insert(out,v)end end;return out end
    local function redraw()local out=get();text.Text=#out==0 and "none" or (#out==1 and tostring(out[1]) or (#out.." selected"))end
    local function emit(silent)local out=get();window.Values[cfg.Flag or cfg.Name]=out;redraw();if not silent and cfg.Callback then task.spawn(cfg.Callback,out)end end
    local function set(values,silent)selected={};for _,v in ipairs(type(values)=="table" and values or {})do selected[v]=true end;emit(silent)end
    Hit(f).MouseButton1Click:Connect(function()local p=popupFrame(f,170,math.min(#opts*29+8,220));local sc=N("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=accent,ZIndex=1002},p);N("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)},sc);N("UIListLayout",{},sc);for _,v in ipairs(opts)do local b=N("TextButton",{Text=(selected[v] and "✓  " or "□  ")..tostring(v),TextColor3=selected[v] and accent or Theme.Text,TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Size=UDim2.new(1,-8,0,29),ZIndex=1003},sc);N("UIPadding",{PaddingLeft=UDim.new(0,8)},b);b.MouseButton1Click:Connect(function()selected[v]=not selected[v];b.Text=(selected[v]and"✓  "or"□  ")..tostring(v);b.TextColor3=selected[v]and accent or Theme.Text;emit(false)end)end end)
    state(cfg,set);set(cfg.Default or {},true);return{Set=set,Get=get,Root=r}
   end
   function sec:CreateKeybind(cfg)
    cfg=cfg or {};local key=cfg.Default or Enum.KeyCode.None;local mode=cfg.ModeDefault or "hold";local modes=cfg.Modes or {"hold","toggle","always on"};local r=row(cfg.Name or "Bind")
    local kb=N("TextButton",{Text=key.Name,TextColor3=Theme.Text,TextSize=10,Font=Enum.Font.Code,AutoButtonColor=false,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(65,23),BackgroundColor3=Theme.Field,BorderSizePixel=0},r);Corner(kb,4);Stroke(kb)
    local mb=N("TextButton",{Text=mode,TextColor3=Theme.Text,TextSize=10,Font=Enum.Font.Code,AutoButtonColor=false,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-71,.5,0),Size=UDim2.fromOffset(62,23),BackgroundColor3=Theme.Field,BorderSizePixel=0},r);Corner(mb,4)
    local function setKey(v,silent)key=v or Enum.KeyCode.None;kb.Text=key.Name;window.Values[cfg.Flag or cfg.Name]={key=key.Name,mode=mode};if not silent and cfg.Callback then task.spawn(cfg.Callback,key)end end
    local function setMode(v,silent)mode=v or "hold";mb.Text=mode;window.Values[cfg.Flag or cfg.Name]={key=key.Name,mode=mode};if not silent and cfg.ModeCallback then task.spawn(cfg.ModeCallback,mode)end end
    kb.MouseButton1Click:Connect(function()kb.Text="...";window._capture=function(k)setKey(k)end end)
    mb.MouseButton1Click:Connect(function()local p=popupFrame(mb,100,#modes*26+6);N("UIPadding",{PaddingTop=UDim.new(0,3)},p);N("UIListLayout",{},p);for _,v in ipairs(modes)do local b=N("TextButton",{Text=v,TextColor3=v==mode and accent or Theme.Text,TextSize=10,Font=Enum.Font.Code,BackgroundTransparency=1,Size=UDim2.new(1,0,0,26),ZIndex=1003},p);b.MouseButton1Click:Connect(function()setMode(v);window:ClosePopup()end)end end)
    local function set(data,silent)if type(data)=="table"then setMode(data.mode or mode,true);setKey(Enum.KeyCode[data.key or "None"]or Enum.KeyCode.None,silent)elseif typeof(data)=="EnumItem"then setKey(data,silent)end end
    state(cfg,set);setKey(key,true);return{Set=setKey,Get=function()return key end,SetMode=setMode,GetMode=function()return mode end,Root=r}
   end
   function sec:CreateInput(cfg)
    cfg=cfg or {};local value=tostring(cfg.Default or "");local r=row(cfg.Name or "Input");local box=N("TextBox",{Text=value,PlaceholderText=cfg.Placeholder or "",ClearTextOnFocus=false,TextColor3=Theme.Text,PlaceholderColor3=Theme.Muted,TextSize=11,Font=Enum.Font.Code,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(128,27),BackgroundColor3=Theme.Field,BorderSizePixel=0},r);Corner(box,4)
    local function set(v,silent)value=tostring(v or "");box.Text=value;window.Values[cfg.Flag or cfg.Name]=value;if not silent and cfg.Callback then task.spawn(cfg.Callback,value)end end;box.FocusLost:Connect(function()set(box.Text)end);state(cfg,set);set(value,true);return{Set=set,Get=function()return value end,Root=r}
   end
   function sec:CreateColorPicker(cfg)
    cfg=cfg or {};local value=cfg.Default or Color3.fromRGB(128,133,255);local r=row(cfg.Name or "Color");local sw=N("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(18,18),BackgroundColor3=value,BorderSizePixel=0},r);Corner(sw,4);Stroke(sw)
    local h,s,v=value:ToHSV();local function set(c,silent)value=c;h,s,v=c:ToHSV();sw.BackgroundColor3=c;window.Values[cfg.Flag or cfg.Name]={math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)};if not silent and cfg.Callback then task.spawn(cfg.Callback,c)end end
    Hit(sw).MouseButton1Click:Connect(function()local p=popupFrame(sw,285,215);local title=Label(p,"Color",13,UDim2.fromOffset(14,6));title.ZIndex=1002;local sv=N("ImageLabel",{Position=UDim2.fromOffset(14,38),Size=UDim2.fromOffset(175,145),BackgroundColor3=Color3.fromHSV(h,1,1),BorderSizePixel=0,Image="rbxassetid://4155801252",ZIndex=1002},p);local hue=N("Frame",{Position=UDim2.fromOffset(197,38),Size=UDim2.fromOffset(18,145),BorderSizePixel=0,ZIndex=1002},p);N("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(.17,Color3.fromHSV(.17,1,1)),ColorSequenceKeypoint.new(.33,Color3.fromHSV(.33,1,1)),ColorSequenceKeypoint.new(.5,Color3.fromHSV(.5,1,1)),ColorSequenceKeypoint.new(.67,Color3.fromHSV(.67,1,1)),ColorSequenceKeypoint.new(.83,Color3.fromHSV(.83,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1))})},hue);local current=N("Frame",{Position=UDim2.fromOffset(229,74),Size=UDim2.fromOffset(40,40),BackgroundColor3=value,BorderSizePixel=0,ZIndex=1002},p);Corner(current,4)
     local active=nil;local function move(pos)if active=="h"then h=math.clamp((pos.Y-hue.AbsolutePosition.Y)/hue.AbsoluteSize.Y,0,1)else s=math.clamp((pos.X-sv.AbsolutePosition.X)/sv.AbsoluteSize.X,0,1);v=1-math.clamp((pos.Y-sv.AbsolutePosition.Y)/sv.AbsoluteSize.Y,0,1)end;sv.BackgroundColor3=Color3.fromHSV(h,1,1);current.BackgroundColor3=Color3.fromHSV(h,s,v);set(current.BackgroundColor3)end
     sv.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then active="sv";move(i.Position);window._activeDrag={move=move}end end);hue.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then active="h";move(i.Position);window._activeDrag={move=move}end end)
    end)
    local function stateSet(x,silent)if typeof(x)=="Color3"then set(x,silent)elseif type(x)=="table"then set(Color3.fromRGB(x[1],x[2],x[3]),silent)end end;state(cfg,stateSet);set(value,true);return{Set=set,Get=function()return value end,Root=r}
   end
   return sec
  end
  if #self.Tabs==1 then self:SelectTab(tab)end;return tab
 end
 return window
end
return Library
