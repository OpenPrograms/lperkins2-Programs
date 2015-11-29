import socket, marshal, time
s=socket.socket(2,1)
s.bind(('',54321))
s.listen(5)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

d = ''
while True:
    a=s.accept()[0]
    print 8,a
    while True:
        try:
            while '\x00' not in d:
                dta=a.recv(102400)
                if dta=="":
                    break
                d+=dta
            dta,d = d.split('\0')
            print 11,dta
            try:
                b=marshal.dumps(compile(dta,"<repl>","exec"))
            except Exception as e:
                b=str(e)
                print e
            
            print 17, b
            a.send(" "*8+b)
        except:
            break
