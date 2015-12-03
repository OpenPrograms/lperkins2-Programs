import socket, sys, os, pexpect, marshal
scratchdir=sys.argv[1]
os.chdir(scratchdir)
s=socket.socket(2,1)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('',12346))
s.listen(5)
while True:
	a=s.accept()[0]
	print 'reading'
	txt=''
	while True:
		txt+=a.recv(10240)
		if txt.endswith('\n.\n'):
			break
	name,txt=txt.split('\n',1)
	assert '/' not in name
	assert '..' not in name
	if name=='repl':
		try:
			ret=marshal.dumps(compile(txt.split('\n.\n')[0], name, 'single'))
			print 21, `ret`
			a.send(ret)
			continue
		except Exception:
			import traceback
			a.send(traceback.format_exc())
			continue
	f=open(name, 'w')
	f.write(txt.split('\n.\n')[0])
	f.close()
	success=pexpect.run('python -m compileall %s'%name)
	print success
	if os.path.exists(name+'c'):
		f=open(name+'c')
		d=f.read()
		print 26, d
		a.send(d)
		f.close()
	else:
		a.send('failed: '+success)
