gml=require('gml')
gmlr=require('gmlReactor')

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
        self.gui=gml.create(x,y,w,h)
    def addLabel(self, x, y, width, txt):
        return Label(self, x, y, width, txt)
    def addButton(self, x, y, w, h, t, c):
        return Button(self, x, y, w, h, t, c)
    def addTextField(self, x, y, w, t=""):
        return TextField(self,x,y,w,t)
    def addListBox(self, x, y, w, h, l):
        return ListBox(self, x, y, w, h, l)
    def addTextArea(self, x, y, w, h, t=""):
        return TextArea(self,x,y,w,h,t)
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
    def __repr__(self):
        if self.instance==False:
            return "<class gml.TextArea>"
        return "<gml.TextArea instance>"
    def __init__(self, gui, x, y, w, h, t):
        self.setParent=BaseComponent.setParent
        self.hide=BaseComponent.hide
        self.show=BaseComponent.show
        self.isHidden=BaseComponent.isHidden
        self.contains=BaseComponent.contains
        self.getScreenPosition=BaseComponent.getScreenPosition
        self.instance=True
        self.gui=gui
        self.bc=self.textarea=gui.gui.addTextArea(gui.gui, x, y, w, t)
    def setText(self, txt):
        self.bc.text=txt
        if self.isHidden():
            return
        self.bc.draw(self.bc)
        if self.gui.running:
            self.gui.doIteration()

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
        self.elements.push(l)
    def addButton(self, x, y, w, h, t, c):
        l = self.gui.addButton(x, y, w, h, t, c)
        l.setParent(self)
        self.elements.push(l)
    def addTextField(self, x, y, w, t=""):
        l = self.gui.addTextField(x, y, w, t)
        l.setParent(self)
        self.elements.push(l)
    def addListBox(self, x, y, w, h, l):
        l = self.gui.addListBox(x, y, w, h, l)
        l.setParent(self)
        self.elements.push(l)
    def addTextArea(self, x, y, w, h, t=""):
        l = self.gui.addTextArea(x, y, w, h, t)
        l.setParent(self)
        self.elements.push(l)
    def addDiv(self):
        d=self.gui.addDiv()
        d.setParent(self)
        self.elements.push(d)
    def hide(self):
        self.hidden=True
        for child in self.children:
            child.hide()
    def show(self):
        self.hidden=False
        for child in self.children:
            child.show()
    def isHidden(self):
        return self.hidden
