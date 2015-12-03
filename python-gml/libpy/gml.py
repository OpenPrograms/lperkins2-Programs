gml=require('gml')
gmlr=require('gmlReactor')
keyboard=require('keyboard')
null_event=list()
null_event.append("gui_tick")

class GML(object):
    instance=False
    def __repr__(self):
        if self.instance==False:
            return "<class gml.GML>"
        return "<gml.GML instance>"
    def __init__(self, x, y, w, h):
        self.instance=True
        self.x=x
        self.y=y
        self.w=w
        self.h=h
        self.gui=gml.create(x,y,w,h)
    def redraw(self):
        #self.gui.redrawRect(self.gui, self.x, self.y, self.w, self.h)
        self.gui.draw(self.gui)
        #self.gui.renderTarget.flush(self.gui.renderTarget)
    def addLabel(self, x, y, width, txt):
        return Label(self, x, y, width, txt)
    def addButton(self, x, y, w, h, t, c):
        return Button(self, x, y, w, h, t, c)
    def addTextField(self, x, y, w, t=""):
        return TextField(self,x,y,w,t)
    def addListBox(self, x, y, w, h, l):
        return ListBox(self, x, y, w, h, l)
    def addTextArea(self, x, y, w, h, text, vheight, expandable):
        return TextArea(self,x,y,w,h,text, vheight, expandable)
    def addDiv(self):
        return Div(self)
    def setupIteration(self):
        gmlr.setupIteration(self.gui)
    def doIteration(self):
        gmlr.doIteration(self.gui, null_event.toTable())
    def processEvent(self, e):
        if hasattr(e, 0):
            e=e.toTable()
        gmlr.doIteration(self.gui, e)
    def doneIterating(self):
        gmlr.doneIterating(self.gui)
    def run(self):
        event=require(event)
        self.setupIteration()
        while self.gui.running:
            self.processEvent(event.pull())
        self.doneIterating()
    def changeFocusTo(self, ele):
        self.gui.changeFocusTo(self.gui, ele.bc)


class BaseComponent(object):
    hidden=False
    def __repr__(self):
        return "<abstract class gml.BaseComponent>"
    def isHidden(self):
        if self.parent!=None:
            if self.parent.isHidden():
                return True
        return self.bc.isHidden(self.bc)
    def getScreenPosition(self):
        return self.bc.getScreenPosition(self.bc)
    def hide(self):
        self.bc.hide(self.bc)
    def show(self):
        if self.parent!=None:
            if self.parent.isHidden():
                return
        if self.hidden:
            return
        self.bc.show(self.bc)
    def contains(self, x, y):
        return self.bc.contains(self.bc, x, y)
    def setParent(self, parent):
        self.parent=parent
    
class Label(BaseComponent):
    instance=False
    parent=None
    hidden=False
    def __repr__(self):
        if self.instance==False:
            return "<class gml.Label>"
        return "<gml.Label instance>"
    def __init__(self, gui, x, y, w, t):
        self.setParent=BaseComponent.setParent
        self.hide=BaseComponent.hide
        self.show=BaseComponent.show
        self.isHidden=BaseComponent.isHidden
        self.contains=BaseComponent.contains
        self.getScreenPosition=BaseComponent.getScreenPosition
        self.instance=True
        self.gui=gui
        self.bc=self.label=gui.gui.addLabel(gui.gui, x,y,w,t)
    def setText(self, txt):
        self.label.text=txt
        if self.gui.running:
            self.gui.doIteration()


class Button(BaseComponent):
    instance=False
    parent=None
    hidden=False
    def __repr__(self):
        if self.instance==False:
            return "<class gml.Button>"
        return "<gml.Button instance>"
    def __init__(self, gui, x, y, w, h, t, c):
        self.setParent=BaseComponent.setParent
        self.hide=BaseComponent.hide
        self.show=BaseComponent.show
        self.isHidden=BaseComponent.isHidden
        self.contains=BaseComponent.contains
        self.getScreenPosition=BaseComponent.getScreenPosition
        self.instance=True
        self.gui=gui
        self.callback=c
        self.bc=self.button=gui.gui.addButton(gui.gui, x, y, w, h, t, self.onClick)
        self.bc.pyval=self
    def onClick(oself, button, x, y, key):
        if (hasattr(oself, 'pyval')):
            self=oself.pyval
            x,y,key=button,x,y
            button=oself
        else:
            self=oself
        if hasattr(self, 'callback'):
           self.callback(x, y, key)

class TextField(BaseComponent):
    instance=False
    parent=None
    hidden=False
    def __repr__(self):
        if self.instance==False:
            return "<class gml.TextField>"
        return "<gml.TextField instance>"
    def __init__(self, gui, x, y, w, t):
        self.setParent=BaseComponent.setParent
        self.hide=BaseComponent.hide
        self.show=BaseComponent.show
        self.isHidden=BaseComponent.isHidden
        self.contains=BaseComponent.contains
        self.getScreenPosition=BaseComponent.getScreenPosition
        self.instance=True
        self.gui=gui
        self.bc=self.textfield=gui.gui.addTextField(gui.gui, x, y, w, t)
    def setText(self, txt):
        self.bc.text=txt
        if self.isHidden():
            return
        self.bc.draw(self.bc)
        if self.gui.running:
            self.gui.doIteration()


class ListBox(BaseComponent):
    instance=False
    parent=None
    hidden=False
    def __repr__(self):
        if self.instance==False:
            return "<class gml.ListBox>"
        return "<gmlListBox instance>"
    def __init__(self, gui, x, y, w, h, l):
        self.setParent=BaseComponent.setParent
        self.hide=BaseComponent.hide
        self.show=BaseComponent.show
        self.isHidden=BaseComponent.isHidden
        self.contains=BaseComponent.contains
        self.getScreenPosition=BaseComponent.getScreenPosition
        self.instance=True
        self.gui=gui
        self.bc=self.listbox=gui.gui.addListBox(gui.gui, x,y,w,h,l)
    def select(self, idx):
        self.listbox.select(self.listbox, idx)


class TextArea(BaseComponent):
    instance=False
    parent=None
    hidden=False
    def __repr__(self):
        if self.instance==False:
            return "<class gml.TextArea>"
        return "<gml.TextArea instance>"
    def hide(self):
        for line in self.lines:
            line.hide()
    def show(self):
        for line in self.lines:
            line.show()
    def __init__(self, gui, x, y, w, h, t, vheight, expandable):
        if vheight<h:
            vheight=h
        self.setParent=BaseComponent.setParent
        self.isHidden=BaseComponent.isHidden
        self.contains=BaseComponent.contains
        self.getScreenPosition=BaseComponent.getScreenPosition
        self.instance=True
        self.gui=gui
        self.height=h
        self.vheight=vheight
        self.expandable=expandable
        self.lines=list()
        self.text = str(t).split('\n')
        self.vpos=0
        idx=0
        while idx < h:
            line=gui.addTextField(x,y+idx,w,"")
            line.bc.okeyHandler = line.bc.keyHandler
            line.bc.keyHandler=self.handleKey
            line.bc.ta=self
            line.bc.idx=idx
            self.lines.append(line)
            idx=idx+1
        self.redraw()
    def handleKey(line, char, code):
        self=line.ta
        if code==keyboard.keys.left:
            if line.cursorIndex==0:
                if line.idx==0:
                    self.vpos=self.vpos-1
                    if self.vpos<0:
                        self.vpos=0
                    self.redraw()
                    line.cursorIndex=len(line.text)
                else:
                    self.gui.gui.changeFocusTo(self.gui.gui, self.lines[line.idx-1].bc)
                    self.lines[line.idx-1].cursorIndex=len(self.lines[line.idx+1].text)
                return
        elif code==keyboard.keys.right:
            if line.cursorIndex==len(line.text):
                if line.idx<self.height-1:
                    self.gui.gui.changeFocusTo(self.gui.gui, self.lines[line.idx+1].bc)
                    self.lines[line.idx+1].cursorIndex=0
                else:
                    self.vpos=self.vpos+1
                    self.redraw()
                    line.cursorIndex=0
                return
                
        elif code==keyboard.keys.up:
            if line.idx==0:
                self.vpos=self.vpos-1
                if self.vpos<0:
                    self.vpos=0
                self.redraw()
            else:
                self.gui.gui.changeFocusTo(self.gui.gui, self.lines[line.idx-1].bc)
                self.lines[line.idx-1].cursorIndex=line.cursorIndex
            return
        elif code==keyboard.keys.down:
            if line.idx==self.height-1:
                self.vpos=self.vpos+1
                self.redraw()
            else:
                self.gui.gui.changeFocusTo(self.gui.gui, self.lines[line.idx+1].bc)
                self.lines[line.idx+1].cursorIndex=line.cursorIndex
            return
        elif code==keyboard.keys.enter:
            if line.idx==self.height-1:
                pass
            else:
                self.gui.gui.changeFocusTo(self.gui.gui, self.lines[line.idx+1].bc)
                self.lines[line.idx+1].cursorIndex=1
            while line.idx>=self.text.length:
                self.text.append("")
            txt=line.text
            line.text=string.sub(txt, 0,line.cursorIndex-1)
            newline = string.sub(txt, line.cursorIndex)
            self.shift(line.idx+1,1)
            self.text[line.idx]=line.text
            self.text[line.idx+1]=newline
            self.lines[line.idx+1].cursorIndex=1
            self.redraw()
            return
        elif code==keyboard.keys.back:
            if line.cursorIndex==1:
                if line.idx>0:
                    txt = self.text.pop(line.idx)
                    self.text[line.idx-1]=self.text[line.idx-1]+txt
                    self.redraw()
                return
        line.okeyHandler(line, char, code)
        while self.text.length < line.idx+self.vpos+1:
            self.text.append('')
        self.text[line.idx+self.vpos]=line.text
    def shift(self, sl, dy):
        if dy < 0:
            error("Not supported yet")
        if dy==0:
            return
        while dy > 1:
            self.shift(sl, 1)
            dy=dy-1
        nl=""
        while sl < self.text.length-1:
            l=self.text[sl]
            self.text[sl]=nl
            nl=l
            sl=sl+1
        self.text.append(nl)
    def redraw(self):
        for line in self.lines:
            line.text=""
        idx=0
        if self.vpos<0:
            self.vpos=0
        while idx < self.height:
            ln = idx+self.vpos
            line=self.lines[idx]
            if hasattr(self.text, ln):
                txt=self.text[ln]
                line.bc.text=str(txt).s
                line.bc.draw(line.bc)
            else:
                break
            idx=idx+1
    def setText(self, txt):
        self.text=str(txt).split('\n')
        self.redraw()
    def getText(self):
        text=list()
        for line in self.text:
            text.append(str(line).s)
        return table.concat(text.toTable(), '\n')
            
        

class Div(object):
    instance=False
    parent=None
    hidden=False
    def __repr__(self):
        if self.instance==False:
            return "<class gml.Div>"
        return "<gml.Div instance>"
    def __init__(self, gui):
        self.setParent=BaseComponent.setParent
        self.gui=gui
        self.elements=list()
        self.elements.append(5)
        self.elements.pop(0)
    def addLabel(self, x, y, width, txt):
        l = self.gui.addLabel(x, y, width, txt)
        l.setParent(self)
        self.elements.append(l)
    def addButton(self, x, y, w, h, t, c):
        l = self.gui.addButton(x, y, w, h, t, c)
        l.setParent(self)
        self.elements.append(l)
    def addTextField(self, x, y, w, t=""):
        l = self.gui.addTextField(x, y, w, t)
        l.setParent(self)
        self.elements.append(l)
    def addListBox(self, x, y, w, h, l):
        l = self.gui.addListBox(x, y, w, h, l)
        l.setParent(self)
        self.elements.append(l)
    def addTextArea(self, x, y, w, h, t=""):
        l = self.gui.addTextArea(x, y, w, h, t)
        l.setParent(self)
        self.elements.append(l)
    def addDiv(self):
        d=self.gui.addDiv()
        d.setParent(self)
        self.elements.append(d)
    def hide(self):
        self.hidden=True
        for child in self.elements:
            child.hide()
    def show(self):
        self.hidden=False
        for child in self.elements:
            child.show()
    def isHidden(self):
        return self.hidden
