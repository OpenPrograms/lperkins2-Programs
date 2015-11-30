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
    def __repr__(self):
        return "<abstract class gml.BaseComponent>"
    def isHidden(self):
        return self.bc.isHidden(self.bc)
    def getScreenPosition(self):
        return self.bc.getScreenPosition(self.bc)
    def hide(self):
        self.bc.hide(self.bc)
    def show(self):
        self.bc.show(self.bc)
    def contains(self, x, y):
        return self.bc.contains(self.bc, x, y)
    
class Label(BaseComponent):
    instance=False
    def __repr__(self):
        if self.instance==False:
            return "<class gml.Label>"
        return "<gml.Label instance>"
    def __init__(self, gui, x, y, w, t):
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
    def __repr__(self):
        if self.instance==False:
            return "<class gml.Button>"
        return "<gml.Button instance>"
    def __init__(self, gui, x, y, w, h, t, c):
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
    def __repr__(self):
        if self.instance==False:
            return "<class gml.TextField>"
        return "<gml.TextField instance>"
    def __init__(self, gui, x, y, w, t):
        self.hide=BaseComponent.hide
        self.show=BaseComponent.show
        self.isHidden=BaseComponent.isHidden
        self.contains=BaseComponent.contains
        self.getScreenPosition=BaseComponent.getScreenPosition
        self.instance=True
        self.gui=gui
        self.bc=self.textfield=gui.gui.addTextField(gui.gui, x, y, w, t)


class ListBox(BaseComponent):
    instance=False
    def __repr__(self):
        if self.instance==False:
            return "<class gml.ListBox>"
        return "<gmlListBox instance>"
    def __init__(self, gui, x, y, w, h, l):
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

