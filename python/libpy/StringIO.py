EINVAL = 22

__all__ = ["StringIO"]

def _complain_ifclosed(closed):
    if closed:
        raise ValueError, "I/O operation on closed file"

class StringIO:
    buf="static"
    def __init__(self, buf = ''):
        # Force self.buf to be a string or unicode
        buf = str(buf).s
        self.buf = buf
        self.len = len(buf)
        self.buflist = list()
        self.buflist.append("")
        self.pos = 0
        self.closed = False
        self.softspace = 0
    def __repr__(self):
        return "<StringIO buf="+self.buf+">"
    def __iter__(self):
        return self

    def next(self):
        _complain_ifclosed(self.closed)
        r = self.read(1)
        if not r:
            error(StopIteration)
        return r

    def close(self):
        if not self.closed:
            self.closed = True
            self.buf=None
            self.pos=None

    def isatty(self):
        _complain_ifclosed(self.closed)
        return False

    def seek(self, pos, mode = 0):
        _complain_ifclosed(self.closed)
        if self.buflist:
            self.buf = str(self.buf+table.concat(self.buflist.toTable(), '')).s
            self.buflist = list()
            self.buflist.append("")
        if mode == 1:
            pos += self.pos
        elif mode == 2:
            pos += self.len
        self.pos = math.max(0, pos)

    def tell(self):
        _complain_ifclosed(self.closed)
        return self.pos

    def read(self, n = -1):
        _complain_ifclosed(self.closed)
        if self.buflist:
            self.buf = str(self.buf+table.concat(self.buflist.toTable(), '')).s
            self.buflist = list()
            self.buflist.append("")
        if n is None or n < 0:
            newpos = len(self.buf)
        else:
            newpos = math.min(self.pos+n, self.len)
        r = string.sub(self.buf, self.pos+1, newpos)
        self.pos = newpos
        return r

    def readline(self, length=None):
        _complain_ifclosed(self.closed)
        if self.buflist:
            self.buf = str(self.buf+table.concat(self.buflist.toTable(), '')).s
            self.buflist = list()
            self.buflist.append("")
        i = self.buf.find('\n', self.pos)
        if i == None or i < 0:
            newpos = self.len
        else:
            newpos = i+1
        if length is not None and length >= 0:
            if self.pos + length < newpos:
                newpos = self.pos + length
        r = string.sub(self.buf, self.pos, newpos)
        self.pos = newpos
        return r

    def readlines(self, sizehint = 0):
        total = 0
        lines = list()
        lines.append("")
        lines.pop(0)
        line = self.readline()
        while line:
            lines.append(line)
            total += len(line)
            if 0 < sizehint <= total:
                break
            line = self.readline()
        return lines

    def truncate(self, size=None):
        _complain_ifclosed(self.closed)
        if size is None:
            size = self.pos
        elif size < 0:
            raise IOError(EINVAL, "Negative size not allowed")
        elif size < self.pos:
            self.pos = size
        self.buf = string.sub(self.buf.sub, 0, size)
        self.len = size

    def write(self, s):
        _complain_ifclosed(self.closed)
        if not s: return
        # Force s to be a string or unicode
        s = str(s)
        spos = self.pos
        slen = self.len
        if spos == slen:
            self.buflist.append(s.s)
            self.len = self.pos = spos + len(s.s)
            return
        if spos > slen:
            self.buflist.append('\0'*(spos - slen))
            slen = spos
        newpos = spos + len(s)
        if spos < slen:
            if self.buflist:
                self.buf += str('').join(self.buflist)
            self.buflist = list()
            self.buflist.append("")
            self.buflist.append(self.buf.sub(0, spos))
            self.buflist.append(s.s)
            self.buflist.append(self.buf.sub(newpos))
            self.buf = ''
            if newpos > slen:
                slen = newpos
        else:
            self.buflist.append(s.s)
            slen = newpos
        self.len = slen
        self.pos = newpos

    def writelines(self, iterable):
        write = self.write
        for line in iterable:
            write(line)


    def getvalue(self):
        _complain_ifclosed(self.closed)
        if self.buflist:
            self.buf = str(self.buf+table.concat(self.buflist.toTable(), '')).s
            self.buflist = list()
            self.buflist.append("")
        return self.buf


