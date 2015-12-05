class SimpleDB(object):
    path=None
    def __init__(self, path=None):
        if path==None or path=="":
            path='/tmp/db'
        self.path=path
        self.nodes={}
    def __repr__(self):
        if self.path==None:
            return "<class SimpleDB.SimpleDB>"
        return "<SimpleDB.SimpleDB instance (path='"+self.path+"')>"
    def initialize(self):
        f=open(self.path+'/index.json','w')
        print >> f, '{"classes": {}}'
        f.close(f)
        filesystem.makeDirectory(self.path+'/keys')
    def open(self):
        if filesystem.exists(self.path) and not filesystem.isDirectory(self.path):
            error("DB path must be a directory")
        if not filesystem.exists(self.path):
            filesystem.makeDirectory(self.path)
        if not filesystem.exists(self.path+'/index.json'):
            self.initialize()
        return self
    def __getitem__(self, item):
        if not hasattr(self.nodes, item):
            self.nodes[item]=Leaf(self,self,item)
        return self.nodes[item].get()
    def __setitem__(self, item, value):
        if not hasattr(self.nodes, item):
            self.nodes[item]=Leaf(self,self,item)
        return self.nodes[item].set(value)
    def set(self, key, val):
        self[key]=val
    def get(self, key):
        return self[key]
    def unset(self, key):
        if hasattr(self.nodes, item):
            l=self.nodes[item]
            l.unset()
            del self.nodes[item]
    def save(self):
        for c in self.nodes:
            c.save()
        

class Leaf(object):
    undefined=object()
    undefined.__repr__=lambda self: "<Singleton undefined>"
    def __init__(self, db, parent, path):
        self.db=db
        self.parent=parent
        self.path=path
        self.abspath=db.path+'/keys/'+path
        self.dirty=False
        self.value=self.undefined
    def __repr__(self):
        if hasattr(self, 'dirty'):
            return "<SimpleDB.Leaf "+self.path + " dirty="+tostring(self.dirty)+">"
        return "<class SimpleDB.Leaf>"
    def get(self):
        if self.value==self.undefined:
            if not filesystem.exists(self.abspath):
                return self.value
            f=open(self.abspath,'r')
            r=Reader(f)
            self.value=unmarshal(r)
        return self.value
    def set(self, value):
        self.value=value
        self.dirty=True
    def save(self):
        if self.dirty and self.value!=self.undefined:
            segments=str(self.abspath).split('/')
            fn=segments.pop(segments.length-1)
            segments=[i.s for i in segments]
            directory=table.concat(segments.toTable(),'/')
            if not filesystem.exists(directory):
                filesystem.makeDirectory(directory)
            f=open(self.abspath,'w')
            m=marshal(self.value)
            f.write(f, m)
            f.close(f)
    def unset(self):
        segments=str(self.abspath).split('/')
        fn=segments.pop(segments.length-1)
        segments=[i.s for i in segments]
        directory=table.concat(segments.toTable(),'/')
        if not filesystem.exists(directory):
            return
        if filesystem.exists(self.abspath):
            filesystem.remove(self.abspath)
        self.value=self.undefined
        self.dirty=False
        
