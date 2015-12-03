os=require('os')
CSERVER=str(os.getenv('COMPILER')).split(':')
CSADDR=CSERVER[0]
CSPORT=tonumber(CSERVER[1].s)
component=require('component')
internet=component.internet
import StringIO

print "using repl server",CSERVER

def raw_input(prompt):
    print prompt,
    s = input()
    return str(s)

def exit():
    Locals.run=0


#~ connection = connect


#connection.finishConnect(connection)

Locals = FRAMES.current.locals
#{'exit':exit}
Locals.run=True
while Locals.run:
    lines = list()
    c=True
    prompt = ">>>"
    while c:
        line=raw_input(prompt)
        if line.endswith(":"):
            lines.append(line)
            prompt = '...'
            continue
        if line.startswith('#'):
            lines.append(line)
            prompt = '...'
            continue
        if line.startswith(' '):
            lines.append(line)
            prompt = '...'
            continue
        lines.append(line)
        c=internet.connect(CSADDR.s, CSPORT)
        c.finishConnect(c)
        c.write('repl\n')
        while lines.length>0:
            line=lines.pop(0)
            c.write(line.s)
            c.write("\n")
        c.write("\n.\n")
        break
    reply=c.read(102400)
    while reply=="":
        reply=c.read(102400)
    b=StringIO.StringIO()
    b.write(reply)
    b.seek(0)
    
    l=unmarshal(b)
    
    f=Frame.create(Frame, l)
    f.locals = Locals
    dotry(EXECUTE,f)

