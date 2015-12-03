local term=require("term")
local computer=require("computer")
local shell=require("shell")
local filesystem=require("filesystem")
local keyboard=require("keyboard")
local unicode=require("unicode")
local gfxbuffer=require("gfxbuffer")
local process = require("process")
local event=require('event')
local lastClickTime, lastClickPos, lastClickButton, dragButton, dragging
local draggingObj
local firstFocusable, prevFocusable
local getComponentAt
local tickTime
local target
local doubleClickThreshold=.25
local cleanup
local len = unicode.len
local cb = {}

local function restoreFrame(renderTarget,x,y,prevState)

  local curx,cury,pcb,pfg,pbg, behind=table.unpack(prevState)

  for ly=1,#behind do
    local lx=x
    for i=1,#behind[ly] do
      local str,fg,bg=table.unpack(behind[ly][i])
      renderTarget.setForeground(fg)
      renderTarget.setBackground(bg)
      renderTarget.set(lx,ly+y-1,str)
      lx=lx+len(str)
    end
  end


  term.setCursor(curx,cury)
  renderTarget.setForeground(pfg)
  renderTarget.setBackground(pbg)
  renderTarget.flush()

  term.setCursorBlink(pcb)

end

local function doneIterating(gui)
  gui.running=false

  cleanup(gui)

  if gui.onExit then
    gui.onExit()
  end
end

local function extractProperties(element,styles,...)
  local props={...}

  --nodes is now a list of all terminal branches that could possibly apply to me
  local vals={}
  for i=1,#props do
    vals[#vals+1]=extractProperty(element,styles,props[i])
    if #vals~=i then
      for k,v in pairs(styles[1]) do print('"'..k..'"',v,k==props[i] and "<-----!!!" or "") end
      error("Could not locate value for style property "..props[i].."!")
    end
  end
  return table.unpack(vals)
end

local function loadHandlers(gui)
  local handlers=gui.handlers
  for i=1,#handlers do
    event.listen(handlers[i][1],handlers[i][2])
  end
end

local function unloadHandlers(gui)
  local handlers=gui.handlers
  for i=1,#handlers do
    event.ignore(handlers[i][1],handlers[i][2])
  end
end

local function drawBorder(element,styles)
  local screenX,screenY=element:getScreenPosition()

  local borderFG, borderBG,
        border,borderLeft,borderRight,borderTop,borderBottom,
        borderChL,borderChR,borderChT,borderChB,
        borderChTL,borderChTR,borderChBL,borderChBR =
      extractProperties(element,styles,
        "border-color-fg","border-color-bg",
        "border","border-left","border-right","border-top","border-bottom",
        "border-ch-left","border-ch-right","border-ch-top","border-ch-bottom",
        "border-ch-topleft","border-ch-topright","border-ch-bottomleft","border-ch-bottomright")

  local width,height=element.width,element.height

  local bodyX,bodyY=screenX,screenY
  local bodyW,bodyH=width,height

  local gpu=element.renderTarget

  if border then
    gpu.setBackground(borderBG)
    gpu.setForeground(borderFG)

    --as needed, leave off top and bottom borders if height doesn't permit them
    if borderTop and bodyW>1 then
      bodyY=bodyY+1
      bodyH=bodyH-1
      --do the top bits
      local str=(borderLeft and borderChTL or borderChT)..borderChT:rep(bodyW-2)..(borderRight and borderChTR or borderChB)
      gpu.set(screenX,screenY,str)
    end
    if borderBottom and bodyW>1 then
      bodyH=bodyH-1
      --do the top bits
      local str=(borderLeft and borderChBL or borderChB)..borderChB:rep(bodyW-2)..(borderRight and borderChBR or borderChB)
      gpu.set(screenX,screenY+height-1,str)
    end
    if borderLeft then
      bodyX=bodyX+1
      bodyW=bodyW-1
      for y=bodyY,bodyY+bodyH-1 do
        gpu.set(screenX,y,borderChL)
      end
    end
    if borderRight then
      bodyW=bodyW-1
      for y=bodyY,bodyY+bodyH-1 do
        gpu.set(screenX+width-1,y,borderChR)
      end
    end
  end

  return bodyX,bodyY,bodyW,bodyH
end

local function frameAndSave(element)
  local t={}
  local x,y,width,height=element.posX,element.posY,element.width,element.height

  local pcb=term.getCursorBlink()
  local curx,cury=term.getCursor()
  local pfg,pbg=element.renderTarget.getForeground(),element.renderTarget.getBackground()
  local rtg=element.renderTarget.get
  --preserve background
  for ly=1,height do
    t[ly]={}
    local str, cfg, cbg=rtg(x,y+ly-1)
    for lx=2,width do
      local ch, fg, bg=rtg(x+lx-1,y+ly-1)
      if fg==cfg and bg==cbg then
        str=str..ch
      else
        t[ly][#t[ly]+1]={str,cfg,cbg}
        str,cfg,cbg=ch,fg,bg
      end
    end
    t[ly][#t[ly]+1]={str,cfg,cbg}
  end
  local styles=getAppliedStyles(element)

  local bodyX,bodyY,bodyW,bodyH=drawBorder(element,styles)

  local fillCh,fillFG,fillBG=extractProperties(element,styles,"fill-ch","fill-color-fg","fill-color-bg")

  local blankRow=fillCh:rep(bodyW)

  element.renderTarget.setForeground(fillFG)
  element.renderTarget.setBackground(fillBG)
  term.setCursorBlink(false)

  element.renderTarget.fill(bodyX,bodyY,bodyW,bodyH,fillCh)

  return {curx,cury,pcb,pfg,pbg, t}

end

cleanup = function (gui)
  --remove handlers
  unloadHandlers(gui)

  --hide gui, redraw beneath?
  if gui.prevTermState then
    restoreFrame(gui.renderTarget,gui.posX,gui.posY,gui.prevTermState)
    gui.prevTermState=nil
  end
end

function setupIteration(gui)
  gui.running=true
  --draw gui background, preserving underlying screen
  gui.prevTermState=frameAndSave(gui)
  gui.hidden=false
 
  
  for i=1,#gui.components do
    if not gui.components[i].hidden then
      if gui.components[i].focusable and not gui.components[i].hidden then
        if firstFocusable==nil then
          firstFocusable=gui.components[i]
        else
          gui.components[i].tabPrev=prevFocusable
          prevFocusable.tabNext=gui.components[i]
        end
        prevFocusable=gui.components[i]
      end
      gui.components[i]:draw()
    end
  end
  if firstFocusable then
    firstFocusable.tabPrev=prevFocusable
    prevFocusable.tabNext=firstFocusable
    if not gui.focusElement and not gui.components[i].hidden then
      gui.focusElement=gui.components[i]
      gui.focusElement.state="focus"
    end
  end
  if gui.focusElement and gui.focusElement.gotFocus then
    gui.focusElement.gotFocus()
  end

  loadHandlers(gui)

  --run the gui's onRun, if any
  if gui.onRun then
    gui:onRun()
  end

  local function gca(tx,ty)
    for i=1,#gui.components do
      local c=gui.components[i]
      if not c:isHidden() and c:contains(tx,ty) then
        return c
      end
    end
  end
  getComponentAt=gca
  lastClickTime, lastClickPos, lastClickButton, dragButton, dragging=0,{0,0},nil,nil,false
  draggingObj=nil
end

function doIteration(gui, e)
  

  --drawing components
  
  
  
  if e[1]=="gui_close" then
    doneIterating(gui)
    return false
  elseif e[1]=="touch" then
    --figure out what was touched!
    local tx, ty, button=e[3],e[4],e[5]
    if gui:contains(tx,ty) then
      tx=tx-gui.bodyX+1
      ty=ty-gui.bodyY+1
      lastClickPos={tx,ty}
      tickTime=computer.uptime()
      dragButton=button
      target=getComponentAt(tx,ty)
      clickedOn=target
      if target then
        if target.focusable and target~=gui.focusElement then
          gui:changeFocusTo(clickedOn)
        end
        if lastClickPos[1]==tx and lastClickPos[2]==ty and lastClickButton==button and
            tickTime - lastClickTime<doubleClickThreshold then
          if target.onDoubleClick then
            target:onDoubleClick(tx-target.posX+1,ty-target.posY+1,button)
          end
        elseif target.onClick then
          target:onClick(tx-target.posX+1,ty-target.posY+1,button)
        end
      end
      lastClickTime=tickTime
      lastClickButton=button
    end
  elseif e[1]=="drag" then
    --if we didn't click /on/ something to start this drag, we do nada
    if clickedOn then
      local tx,ty=e[3],e[4]
      tx=tx-gui.bodyX+1
      ty=ty-gui.bodyY+1
      --is this is the beginning of a drag?
      if not dragging then
        if clickedOn.onBeginDrag then
          draggingObj=clickedOn:onBeginDrag(lastClickPos[1]-clickedOn.posX+1,lastClickPos[2]-clickedOn.posY+1,dragButton)
          dragging=true
        end
      end
      --now do the actual drag bit
      --draggingObj is for drag proxies, which are for drag and drop operations like moving files
      if draggingObj and draggingObj.onDrag then
        draggingObj:onDrag(tx,ty)
      end
      --
      if clickedOn and clickedOn.onDrag then
        tx,ty=tx-clickedOn.posX+1,ty-clickedOn.posY+1
        clickedOn:onDrag(tx,ty)
      end
    end
  elseif e[1]=="drop" then
    local tx,ty=e[3],e[4]
    tx=tx-gui.bodyX+1
    ty=ty-gui.bodyY+1
    if draggingObj and draggingObj.onDrop then
      local dropOver=getComponentAt(tx,ty)
      draggingObj:onDrop(tx,ty,dropOver)
    end
    if clickedOn and clickedOn.onDrop then
      tx,ty=tx-clickedOn.posX+1,ty-clickedOn.posY+1
      clickedOn:onDrop(tx,ty,dropOver)
    end
    draggingObj=nil
    dragging=false
  elseif e[1]=="key_down" then
    local char,code=e[3],e[4]
    --tab
    if code==15 and gui.focusElement then
      local newFocus=gui.focusElement
      if keyboard.isShiftDown() then
        repeat
          newFocus=newFocus.tabPrev
        until newFocus.hidden==false
      else
        repeat
          newFocus=newFocus.tabNext
        until newFocus.hidden==false
      end
      if newFocus~=gui.focusElement then
        gui:changeFocusTo(newFocus)
      end
    elseif char==3 then
      --copy!
      if gui.focusElement and gui.focusElement.doCopy then
        cb.clipboard=gui.focusElement:doCopy() or cb.clipboard
      end
    elseif char==22 then
      --paste!
      if gui.focusElement.doPaste and type(cb.clipboard)=="string" then
        gui.focusElement:doPaste(cb.clipboard)
      end
    elseif char==24 then
      --cut!
      if gui.focusElement.doCut then
        cb.clipboard=gui.focusElement:doCut() or cb.clipboard
      end
    elseif gui.focusElement and gui.focusElement.keyHandler then
      gui.focusElement:keyHandler(char,code)
    end
    if gui.focusElement and gui.focusElement.onKey then
      gui.focusElement.onKey(char,code)
    end
  end
  gui.renderTarget:flush()
  return true
end



return {setupIteration=setupIteration, doIteration=doIteration, doneIterating=doneIterating, clipboard=cb}
