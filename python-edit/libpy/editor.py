computer=require('computer')
print "Free memory:",computer.freeMemory()
if computer.freeMemory()<600000:
    computer.shutdown(True)
component=require('component')
filesystem=require('filesystem')
sw,sh=callAndPack(component.gpu.getResolution)
import gml
gui=gml.GML(0,0,sw,sh)
event=require('event')
os=require('os')
compileServer=os.getenv("COMPILER")
serialization=require('serialization')
if serialization.serialize(compileServer, 1000)=="{}":
    compileServer=None
keyboard=require('keyboard')

filepath=None
def newClicked(button, x, y, key):
    global filepath, fileName
    filepath=fileName=None
    editArea.setText("")
    fileMenu.hide()
    editArea.redraw()
    gui.doIteration()

def saveClicked(button, x, y, key):
    fileMenu.hide()
    gui.doIteration()
    if filepath==None:
        queryUser("Save File", doSave, "")
    else:
        doSave(str(filepath).s)


fileName=None

def compileClicked(button, x, y, key):
    buildMenu.hide()
    editArea.redraw()
    gui.doIteration()
    if fileName is None:
        queryUser("File Name?", setupCompile, "")
    else:
        setupCompile(fileName)
    
def setupCompile(fn):
    global fileName
    fileName=fn
    if compileServer is None:
        queryUser("Compile Server Address?", doCompile, "")
    else:
        doCompile(compileServer)

def doCompile(cs):
    global compileServer
    compileServer=cs
    os.setenv('COMPILER', cs)
    serverport=str(cs).split(':')
    server=serverport[0].s
    port=serverport[1].s
    port=tonumber(port)
    internet=component.internet
    c=component.internet.connect(server, port)
    c.finishConnect(c)
    c.write(fileName+'\n'+editArea.getText()+'\n.\n')
    reply=c.read(102400)
    while reply=="":
        reply=c.read(102400)
    
    if filepath!=None:
        status.bc.text="Saved to "+str(filepath).s+"c"
        status.bc.draw(status.bc)
        gui.doIteration()
        f=open(str(filepath).s+'c','w')
        print >> f, reply
        f.close(f)
    f=open('/tmp/'+fileName+'c','w')
    print >> f, reply
    f.close(f)

def doSave(path):
    global filepath
    filepath=path
    f=open(path,'w')
    print >> f, editArea.getText()
    f.close(f)
    status.bc.text="Saved to "+path
    status.bc.draw(status.bc)
    gui.doIteration()
    
    
    
def exitClicked(button, x, y, key):
    global keepRunning
    keepRunning=False
    fileMenu.hide()
    gui.doIteration()
    

def openClicked(button, x, y, kc):
    fileMenu.hide()
    gui.doIteration()
    if filepath == None:
        queryUser("Open File", openFile, "")
    else:
        queryUser("Open File", openFile, serialization.serialize(filepath, 1000))
    
def cutClicked(button, x, y, kc):
    if hasattr(gui.gui.focusElement, 'doCut'):
        gml.gmlr.clipboard.clipboard=gui.gui.focusElement.doCut(gui.gui.focusElement)
    editMenu.hide()
    editArea.redraw()
        

def copyClicked(button, x, y, kc):
    if hasattr(gui.gui.focusElement, 'doCopy'):
        gml.gmlr.clipboard.clipboard=gui.gui.focusElement.doCopy(gui.gui.focusElement)
    editMenu.hide()
    editArea.redraw()

def pasteClicked(button, x, y, kc):
    if hasattr(gui.gui.focusElement, 'doPaste'):
        gui.gui.focusElement.doPaste(gui.gui.focusElement, gml.gmlr.clipboard.clipboard)
    editMenu.hide()
    editArea.redraw()
        

def deleteClicked(button, x, y, kc):
    if hasattr(gui.gui.focusElement, 'doCut'):
        gui.gui.focusElement.doCut(gui.gui.focusElement)
    editMenu.hide()
    editArea.redraw()
        
    
    
def openFile(path):
    global filepath
    filepath=path
    editArea.setText("")
    f=io.open(path,'r')
    if hasattr(f, 'read'):
        editArea.setText(f.read(f, "*all"))
        f.close(f)
    
        
    
    


def fileClicked(button, x, y, key):
    if fileMenu.isHidden():
        fileMenu.show()
    else:
        fileMenu.hide()
        editArea.redraw()

def buildClicked(button, x, y, key):
    if buildMenu.isHidden():
        buildMenu.show()
    else:
        buildMenu.hide()
        editArea.redraw()

    
def editClicked(button, x, y, key):
    if editMenu.isHidden():
        editMenu.show()
    else:
        editMenu.hide()
        editArea.redraw()


def okClicked(button, x, y, key):
    gui.gui.changeFocusTo(gui.gui, cfocus)
    promptMsg.hide()
    promptOK.hide()
    prompt.hide()
    editArea.show()
    processPrompt(prompt.bc.text)


def queryUser(p, cb, default):
    global cfocus
    cfocus = gui.gui.focusElement
    global processPrompt
    processPrompt=cb
    editArea.hide()
    gui.redraw()
    if default==None:
        default=""
    
    promptMsg.bc.text=str(p).s
    promptMsg.bc.draw(promptMsg.bc)
    
    prompt.bc.text=str(default).s
    
    
    promptMsg.hide()
    promptOK.hide()
    promptMsg.show()
    promptOK.show()
    
    promptOK.bc.draw(promptOK.bc) 
    promptMsg.bc.draw(promptMsg.bc)
    prompt.show()
    
    gui.doIteration()
    gui.gui.changeFocusTo(gui.gui, prompt.bc)
    
    

promptMsg=gui.addLabel("center", sh//2-4, 30, "")
promptOK=gui.addButton("center", sh//2-1, 4, 1, "ok", okClicked)
prompt=gui.addTextField("center", 'center', 30, "")
promptMsg.hide()
promptOK.hide()
prompt.hide()

def okKey(ele, char, code):
    if code==keyboard.keys.enter:
        okClicked()
    else:
        ele.okeyHandler(ele, char, code)

prompt.bc.okeyHandler=prompt.bc.keyHandler
prompt.bc.keyHandler=okKey


fileMenu=gui.addDiv()
fileMenu.addButton(0,3,4,1,"NEW", newClicked)
fileMenu.addButton(0,4,4,1,"OPEN", openClicked)
fileMenu.addButton(0,5,4,1,"SAVE", saveClicked)
fileMenu.addButton(0,6,4,1,"EXIT", exitClicked)
fileMenu.hide()



editMenu=gui.addDiv()
editMenu.addButton(8, 3, 7, 1, "CUT", cutClicked)
editMenu.addButton(8, 4, 7, 1, "COPY", copyClicked)
editMenu.addButton(8, 5, 7, 1, "PASTE", pasteClicked)
editMenu.addButton(8, 6, 7, 1, "DELETE", deleteClicked)
editMenu.hide()

buildMenu=gui.addDiv()
buildMenu.addButton(17, 3, 9, 1, "COMPILE", compileClicked)
buildMenu.hide()

editArea = gui.addTextArea(1,3,sw-2,sh-5,"""This is a 
test editor""", sh-4, True)

status=gui.addLabel(1, sh-1, sw-2, "")

gui.addButton(0,0,6,1,"FILE", fileClicked)
gui.addButton(8,0,8,1,"EDIT", editClicked)
gui.addButton(8+7+2, 0, 9, 1, "BUILD", buildClicked)

print "Free memory:",computer.freeMemory()
gui.setupIteration()
gui.doIteration()
keepRunning=True

while keepRunning:
    gui.processEvent(event.pull())
print 32
gui.doneIterating()
print "Free memory:",computer.freeMemory()
