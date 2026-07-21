--!strict
-- Lightweight self-contained Lucide renderer for Roblox UI.
-- Icons are drawn as vector-like line segments; no asset IDs are required.
local Lucide = {}

local ICONS = {
 Target = {circles={{.5,.5,.38},{.5,.5,.16}}, lines={{.5,.03,.5,.22},{.5,.78,.5,.97},{.03,.5,.22,.5},{.78,.5,.97,.5}}},
 Eye = {lines={{.05,.5,.18,.35},{.18,.35,.35,.25},{.35,.25,.5,.22},{.5,.22,.65,.25},{.65,.25,.82,.35},{.82,.35,.95,.5},{.95,.5,.82,.65},{.82,.65,.65,.75},{.65,.75,.5,.78},{.5,.78,.35,.75},{.35,.75,.18,.65},{.18,.65,.05,.5}},circles={{.5,.5,.13}}},
 Settings = {circles={{.5,.5,.16}},lines={{.5,.05,.5,.2},{.5,.8,.5,.95},{.05,.5,.2,.5},{.8,.5,.95,.5},{.18,.18,.29,.29},{.71,.71,.82,.82},{.82,.18,.71,.29},{.29,.71,.18,.82}}},
 Plus = {lines={{.5,.15,.5,.85},{.15,.5,.85,.5}}},
 RefreshCw = {lines={{.2,.3,.32,.15},{.32,.15,.48,.2},{.48,.2,.62,.22},{.62,.22,.75,.34},{.75,.34,.82,.48},{.82,.48,.82,.62},{.82,.62,.7,.78},{.7,.78,.52,.83},{.52,.83,.36,.78},{.36,.78,.25,.67},{.25,.67,.18,.54},{.18,.54,.18,.38},{.18,.38,.2,.3},{.2,.3,.38,.3}},},
 SlidersHorizontal = {lines={{.08,.27,.42,.27},{.58,.27,.92,.27},{.08,.72,.62,.72},{.78,.72,.92,.72}},circles={{.5,.27,.08},{.7,.72,.08}}},
 ChevronDown = {lines={{.18,.36,.5,.68},{.5,.68,.82,.36}}},
 X = {lines={{.2,.2,.8,.8},{.8,.2,.2,.8}}},
 Save = {lines={{.15,.08,.72,.08},{.72,.08,.9,.25},{.9,.25,.9,.92},{.9,.92,.1,.92},{.1,.92,.1,.08},{.25,.08,.25,.38},{.25,.38,.7,.38},{.7,.38,.7,.08},{.28,.92,.28,.58},{.28,.58,.72,.58},{.72,.58,.72,.92}}},
 Trash2 = {lines={{.18,.25,.82,.25},{.35,.25,.35,.12},{.35,.12,.65,.12},{.65,.12,.65,.25},{.27,.25,.32,.9},{.32,.9,.68,.9},{.68,.9,.73,.25},{.43,.4,.43,.75},{.57,.4,.57,.75}}},
 Check = {lines={{.16,.52,.4,.76},{.4,.76,.84,.25}}},
 User = {circles={{.5,.3,.18}},lines={{.18,.88,.22,.68},{.22,.68,.35,.58},{.35,.58,.65,.58},{.65,.58,.78,.68},{.78,.68,.82,.88}}},
}

local function line(parent, x1,y1,x2,y2,color,thickness,z)
 local dx,dy=x2-x1,y2-y1
 local len=math.sqrt(dx*dx+dy*dy)
 local f=Instance.new("Frame")
 f.Name="LucideStroke"; f.AnchorPoint=Vector2.new(0,.5)
 f.Position=UDim2.fromScale(x1,y1); f.Size=UDim2.new(len,0,0,thickness)
 f.Rotation=math.deg(math.atan2(dy,dx)); f.BackgroundColor3=color; f.BorderSizePixel=0; f.ZIndex=z
 local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=f; f.Parent=parent
end

function Lucide.create(name:string, size:number?, color:Color3?)
 local holder=Instance.new("Frame")
 holder.Name="Lucide_"..name; holder.BackgroundTransparency=1
 holder.Size=UDim2.fromOffset(size or 18,size or 18)
 local data=ICONS[name] or ICONS.Settings
 local c=color or Color3.fromRGB(150,150,150)
 for _,v in ipairs(data.lines or {}) do line(holder,v[1],v[2],v[3],v[4],c,1.5,2) end
 for _,v in ipairs(data.circles or {}) do
  local steps=16
  for i=0,steps-1 do
   local a,b=(i/steps)*math.pi*2,((i+1)/steps)*math.pi*2
   line(holder,v[1]+math.cos(a)*v[3],v[2]+math.sin(a)*v[3],v[1]+math.cos(b)*v[3],v[2]+math.sin(b)*v[3],c,1.5,2)
  end
 end
 return holder
end
return Lucide
