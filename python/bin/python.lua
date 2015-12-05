local formatInt
function typeof(a)
    t=type(a)
    if t=="function" or t=="number" or t=="string" then return t end
    return a.__class__
end

function printFramePos(frame)
    print("in ",frame)
--    print(frame)
    if frame.lnotab~=nil then
        local i=0
        local ctr = 0
        local ln = 1
        while ctr<frame.idx-5 do
            i = i + 1
            if frame.lnotab:byte(i)==nil then
            ln = ln+1
            break
            end
            ctr = ctr + frame.lnotab:byte(i)
            i = i + 1
            ln =  ln + frame.lnotab:byte(i)
        end
        print("line number: "..ln)
    end
end

dotry=function(func,frame)
    local sd = STACK:getn()
    local fd = FRAMES:getn()
--    local s,e = xpcall(func,debug.traceback, frame)
    local s,e = pcall(func, frame)
    if not s then 
        print(e) 
        if FRAMES.current~=0 then
            printFramePos(FRAMES.current)
        end
        while STACK:getn() > sd do
            STACK:pop()
        end
        while FRAMES:getn() > fd do
            FRAMES.current = FRAMES:pop()
            if FRAMES.current~=0 then
                printFramePos(FRAMES.current)
            end
        end
        return true 
    end
    return e
end

local IEEE754 = require('python/IEEE754')
require('python/stack')
primitives=require('python/primitives')
StopIteration = primitives.StopIteration
local builtins = setmetatable(require('python/builtins'), {__index=_G})
builtins.dotry=dotry
local PYTHONPATH={"/usr/lib/python2"}
local path

function table.contains(t, val, lim)
    local i,v
    for i,v in pairs(t) do
        if i>lim then break end
        if v==val then return true end
    end
    return false
end

if unpack==nil then
    unpack=table.unpack
end

if io.popen==nil then
    filesystem=require('filesystem')
end

--cmp_op = {'<', '<=', '==', '!=', '>', '>=', 'in', 'not in', 'is', 'is not', 'exception match', 'BAD'}
cmp_op = {function(a,b) return b<a end, function(a,b) return b<=a end, 
function(a,b)
    if hasattr(b,'__eq__') then
        return b.__eq__(a)
    end
    return b==a 
end, function(a,b) return b~=a end, function(a,b) return b>a end, function(a,b) return b>=a end, function(a,b) return b[a]~=nil end, function(a,b) return not b[a]~=nil end, function(a,b) return b==a end, function(a,b) return b~=a end, 'exception match', 'BAD'}

ninstructions = 0
MethodProxy={__class__=Type, __bases__={object}}
function MethodProxy:__call(...)
    if self.self~=nil then
        return self.method(self.self, ...)
    end
    return self.method(self.func_self, ...)
end

function MethodProxy:__tostring()
    local s,v = pcall(tostring,self.method)
    return "<MethodProxy for "..v..">"
end

function MethodProxy:__index(key)
    local v = rawget(self, key)
    if v~=nil then return v end
    if type(self.method)~="function" then
        v=self.method[key]
        return v
    else
        return self.method
    end
end

function MethodProxy:New(obj, method)
    local o = {__class__=MethodProxy}
    setmetatable(o, MethodProxy)
    local idx,v
    local mt = getmetatable(method)
    if type(method)=="function" then
        o.self=obj
        o.method=method
        return o
    end
    if  (mt~=nil and mt.__call~=nil) then
        o.self=obj
        o.method=function(...)
            local args = {...}
            table.remove(args,1)
            return method(table.unpack(args))
        end
    end
    for idx,v in pairs(method) do
        o[idx]=v
    end
    o.func_self = obj
    return o
end

function getattr(obj, attr)
    return obj[attr]~=nil
end

function hasattr(obj, attr)
    success, success1=pcall(getattr, obj, attr)
    return success and success1
end

builtins.hasattr=hasattr

for path in (os.getenv("PYTHONPATH") or ""):gmatch('([^:]+)') do
    table.insert(PYTHONPATH, 1, path)
end

print(list:fromTable(PYTHONPATH))

function pathIsDirectory(path)
    if (io.popen~=nil) then
        local p = io.popen("find '"..path.."' -maxdepth 0 -type d")
        return not not p:read()
    end
    return filesystem.isDirectory(path)
end

function pathIsFile(path)
    if (io.popen~=nil) then
        local p = io.popen("find '"..path.."' -maxdepth 0 -type f")
        return not not p:read()
    end
    return filesystem.exists(path) and not filesystem.isDirectory(path)
end

function pathInDirectory(path, searchpath)
    if (io.popen~=nil) then
        local p = io.popen("find '"..searchpath.."'  -maxdepth 1")
        local f
        while true do
            f = p:read()
            if f==nil then break end
            if f==searchpath.."/"..path then return true end
        end
        return false
    end
    return filesystem.exists(searchpath.."/"..path)
end


function searchPath(modname, searchpath)
    local idx,path
    if searchpath == nil then
        for idx,path in pairs(PYTHONPATH) do
            if pathIsDirectory(path) then
                if pathInDirectory(modname,path) then
                    if pathIsDirectory(path.."/"..modname) then
                        if pathInDirectory("__init__.pyc",path.."/"..modname) then
                            return path.."/"..modname.."/".."__init__.pyc", path.."/"..modname
                        end
                    end
                end
                if pathInDirectory(modname..".pyc",path) then
                    return path.."/"..modname..".pyc" , path
                end
            end
        end
    else
        path=searchpath
        if pathIsDirectory(path) then
            if pathInDirectory(modname,path) then
                if pathIsDirectory(path.."/"..modname) then
                    if pathInDirectory("__init__.pyc",path.."/"..modname) then
                        return path.."/"..modname.."/".."__init__.pyc", path.."/"..modname
                    end
                end
            end
            if pathInDirectory(modname..".pyc",path) then
                return path.."/"..modname..".pyc" , path
            end
        end
    end
end


local function marshal(obj)
    if hasattr(obj, '__class__') then
        if obj.__class__==str then
            obj=obj.s
        elseif obj.__class__==list then
            obj=obj:toTable()
        else
            print("marshalling of other python type: "..tostring(obj.__class__).."unsupported")
            error()
        end
    else
    end
    if type(obj)=="string" then
        return "s"..formatInt(#obj, 4)..obj
    elseif type(obj)=='number' then
        return "g"..IEEE754.encodeDP(obj)
    elseif type(obj)=='table' then
        local o=""
        if #obj~=0 then
            for i,v in pairs(obj) do
                o=o..marshal(v)
            end
            return '('..formatInt(#obj,4)..o
        end
        for i,v in pairs(obj) do
            o=o..marshal(i)..marshal(v)
        end
        o=o..'0'
        return '{'..o
    else
        error("Unmarshallable type: "..type(obj))
    end
end

local TYPES={}
local function unmarshal(reader)
    local action = reader:next()
    if TYPES[action]==nil then
        if hasattr(reader, 'idx') then
            print("reader pos: ", reader.idx)
        elseif hasattr(reader, 'pos') then
            print("reader pos: ", reader.pos)
        end
        error("unmarshalling encountered unsupported type: "..action:byte())
    end
    local ret = TYPES[action](reader)
    return ret
end

local function copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function copy1(orig, n)
--todo support indices < 0 and type(orig)!=table
    local copy
    local idx = 0
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            idx = idx + 1
            if idx == n then
                return copy
            end
            copy[orig_key] = orig_value
        end
        return copy
    end
end




local object = {
    __class__=Type,
    __init__=function() end
}

ModuleType = {
    __class__=Type,
}
function ModuleType:__tostring()
    return "<module "..self.__file__..">"
end

function object:__tostring()
    if self['__str__']~=nil then
        return self.__str__()
    end
    return "<object>"
end

function object:__repr__()
    return self.__str__()
end

function object:__str__()
    if (self==nil) then return "an object" end
    if self.__class__==Type then
        return "<class "..self.__module__.."."..self.__name__..">"
    end
end

setmetatable(object,object)



local False = false
local True = true
builtins["object"]=object
builtins['None']=None
builtins['False']=False
builtins['True']=True
builtins['StopIteration']=StopIteration
builtins['__name__']='__main__'
builtins['type']=Type
builtins.bool=__test_if_true__
builtins.marshal=marshal

local Ellipsis = {}

local function readInt(reader, nbytes)
    local val = 0
    local tval = 0
    for i=1,nbytes,1 do
        tval = reader:next():byte()
        val = val + tval * 2 ^ (8*(i-1))
    end
    return val
end

function formatInt(length, nbytes)
    local s = ""
    for i=1,nbytes,1 do
        s=s..string.char(length%256)
        length=math.floor(length/256)
    end
    return s
end

local string_table_holder = {}
local TYPE_NULL = function(reader) return TYPE_NULL end
local TYPE_NONE = function(reader) return None end
local TYPE_FALSE = function(reader) return False end
local TYPE_TRUE = function(reader) return True end
local TYPE_STOPITER = function(reader) return StopIteration end
local TYPE_ELLIPSIS = function(reader) return Ellipsis end
local TYPE_INT = function(reader) return readInt(reader,4) end
local TYPE_INT64 = function(reader) return readInt(reader, 8) end
local TYPE_BINARY_FLOAT = function(reader) return IEEE754.decodeDP(reader:read(8)) end
local TYPE_LONG = function(reader) return readInt(reader, 8) end
local TYPE_STRING = function(reader) 
    local len = readInt(reader,4)
    return reader:read(len)
end
local TYPE_INTERNED = function(reader)
    local s = TYPE_STRING(reader)
    table.insert(string_table_holder.string_table, s)
    return s
end

local TYPE_STRINGREF = function(reader)
    local idx = readInt(reader, 4)
    return string_table_holder.string_table[idx+1]
end

local TYPE_UNICODE = TYPE_STRING

local TYPE_TUPLE = function(reader)
    local ret = {}
    local len = readInt(reader, 4)
    local idx
    for idx=1,len,1 do
        table.insert(ret, unmarshal(reader))
    end
    return ret
end

local TYPE_LIST = TYPE_TUPLE 

local TYPE_DICT = function(reader)
    local ret = {}
    --local len = readInt(reader, 4)
    local idx
    local key = unmarshal(reader)
    while key ~= TYPE_NULL and key~=nil do
        ret[key] = unmarshal(reader)
        key = unmarshal(reader)
    end
    return ret
end

local TYPE_FROZENSET = TYPE_TUPLE 

local TYPE_CODE = function(reader)
    os.sleep(0)
    local argcount  = readInt(reader, 4)
    local nlocals   = readInt(reader, 4)
    local stacksize = readInt(reader, 4)
    local flags     = readInt(reader, 4)
    local code      = unmarshal(reader)
    local consts    = unmarshal(reader)
    local names     = unmarshal(reader)
    local varnames  = unmarshal(reader)
    local freevars  = unmarshal(reader)
    local cellvars  = unmarshal(reader)
    local filename  = unmarshal(reader)
    local name      = unmarshal(reader)
    local firstlineno = readInt(reader, 4)
    local lnotab = unmarshal(reader)
    
    return {argcount, nlocals, stacksize, flags, code, consts, names, varnames, freevars, cellvars, filename, name, firstlineno, lnotab}
end


local function unmarshalModule(reader)
    string_table_holder.string_table = {}
    local magic=readInt(reader,4)
    local crc = readInt(reader,4)
    local code = unmarshal(reader)
    return code
end

local Reader = function(flo)
    return {
        idx=0, 
        f=flo, 
        buffer = '',
        read=function(self, l) 
            self.idx=self.idx+l
            local r = self.f:read(l)
            return r end,
        next=function(self) 
            self.idx = self.idx+1
            local r = self.f:read(1)
            return r end
    }
end


STACK = Stack:Create()
function NOP() end
function POP_TOP() STACK:pop() end
function ROT_TWO() 
    local a,b
    a,b = STACK:pop(2)
    STACK:push(b)
    STACK:push(a)
end

function ROT_THREE()
    local a,b,c
    a,b,c=STACK:pop(3)
    STACK:push(c)
    STACK:push(a)
    STACK:push(b)
end

function ROT_FOUR()
    local a,b,c,d
    a,b,c,d = STACK:pop(4)
    STACK:push(d)
    STACK:push(a)
    STACK:push(b)
    STACK:push(c)
end

function BUILD_MAP(nsize)
    STACK:push({})
end

function DUP_TOP()
    local a
    a = STACK:pop()
    STACK:push(a)
    STACK:push(a)
end

function UNARY_POSITIVE() end
function UNARY_NEGATIVE() 
    local a=STACK:pop()
    STACK:push(-a)
end

function UNARY_NOT()
    local a=STACK:pop()
    STACK:push(not __test_if_true__(a))
end

function UNARY_CONVERT()
    local a=STACK:pop()
    if hasattr(a, '__class__') then
        STACK:push(a:__repr__())
    else
        STACK:push(tostring(a))
    end
end
function UNARY_INVERT()
    local a=STACK:pop()
    STACK:push(bit.bnot(a))
end

function GET_ITER()
    local a = STACK:pop()
    STACK:push(iter(a))
end

function BINARY_POWER()
    local a,b = STACK:pop(2)
    STACK:push(b^a)
end

function BINARY_MULTIPLY()
    local a,b = STACK:pop(2)
    if type(b)=="string" then
        local idx
        local out = {}
        for idx=1,a,1 do
            table.insert(out,b)
        end
        STACK:push(table.concat(out,""))
    elseif typeof(typeof(b))==Type then
        STACK:push(b:__mul__(a))
    else
        STACK:push(b*a)
    end
    
    
end

function BINARY_DIVIDE()
    local a,b = STACK:pop(2)
    STACK:push(math.floor(b/a))
end

function BINARY_FLOOR_DIVIDE()
    local a,b = STACK:pop(2)
    STACK:push(math.floor(b/a))
end

function BINARY_TRUE_DIVIDE()
    local a,b = STACK:pop(2)
    STACK:push(b/a)
end

function BINARY_MODULO()
    local a,b = STACK:pop(2)
    STACK:push(b%a)
end

function BINARY_ADD()
    local a,b = STACK:pop(2)
    if type(b)=="string" then
        STACK:push(b..a)
    elseif type(b)=="table" and hasattr(b,'__class__') and hasattr(b.__class__, '__class__') and b.__class__.__class__==Type then
        STACK:push(b:__add__(a))
    else
        STACK:push(b+a)
    end
    
end

function BINARY_SUBTRACT()
    local a,b = STACK:pop(2)
    STACK:push(b-a)
end

function BINARY_SUBSCR()
    local a,b = STACK:pop(2)
    if b.__class__ and b.__getitem__ then
        STACK:push(b:__getitem__(a))
        return
    end
    
    if (b[a]==nil) then print(525,b,a) end
    STACK:push(b[a])
end

function BINARY_LSHIFT()
    local a,b = STACK:pop(2)
    STACK:push(b*2^a)
end

function BINARY_RSHIFT()
    local a,b = STACK:pop(2)
    STACK:push(math.floor(b/2^a))
end

function BINARY_AND()
    local a,b = STACK:pop(2)
    STACK:push(bit.band(a,b))
end

function BINARY_XOR()
    local a,b = STACK:pop(2)
    STACK:push(bit.bxor(a,b))
end

function BINARY_OR()
    local a,b = STACK:pop(2)
    STACK:push(bit.bor(a,b))
end

INPLACE_POWER = BINARY_POWER
INPLACE_MULTIPLY = BINARY_MULTIPLY
INPLACE_DIVIDE = BINARY_DIVIDE
INPLACE_FLOOR_DIVIDE = BINARY_FLOOR_DIVIDE
INPLACE_TRUE_DIVIDE = BINARY_TRUE_DIVIDE
INPLACE_MODULO = BINARY_MODULO
INPLACE_ADD = BINARY_ADD
INPLACE_SUBTRACT = BINARY_SUBTRACT
INPLACE_LSHIFT = BINARY_LSHIFT
INPLACE_RSHIFT = BINARY_RSHIFT
INPLACE_AND = BINARY_AND
INPLACE_XOR = BINARY_XOR
INPLACE_OR = BINARY_OR

function SLICE0()
    STACK:push(copy(STACK:pop()))
end

function SLICE1()
    local a,b = STACK:pop(2)
    STACK:push(copy(b,a))
end

function STORE_SUBSCR()
    local a,b,c = STACK:pop(3)
    if hasattr(b, '__setitem__') then
        b:__setitem__(a,c)
    elseif hasattr(b, "__class__") then
        error("TypeError: '"..b.__class__.."' object does not support item assignment")
    else
        b[a]=c
    end
end

function PRINT_EXPR()
    print(STACK:pop())
end

function PRINT_ITEM()
    local a = STACK:pop()
    if hasattr(a, '__class__') and hasattr(a, "__repr__") then
        a = a:__repr__()
    end
    io.write(tostring(tostring(a).." "))
end

function PRINT_ITEM_TO()
    local a = STACK:pop()
    local b = STACK:pop()
    if hasattr(a, '__class__') and hasattr(a, "__repr__") then
        a = a:__repr__()
    end
    b:write(tostring(tostring(a).." "))
end

function PRINT_NEWLINE()
    io.write("\n")
end

function PRINT_NEWLINE_TO()
    STACK:pop():write("\n")
end

function RETURN_VALUE()
    return STACK:pop()
end

function LOAD_CONST(cidx)
    cidx=cidx[1]+cidx[2]*256+1
    STACK:push(FRAMES.current.constants[cidx])
end

function LOAD_GLOBAL(nidx)
    nidx=nidx[1]+nidx[2]*256+1
    local n = FRAMES.current.names[nidx]
    if FRAMES.current.globals[n]~=nil then
        STACK:push(FRAMES.current.globals[n])
    elseif builtins[n]~=nil then        
        STACK:push(builtins[n])
    else
        error("NameError: "..n)
    end
end

function STORE_GLOBAL(nidx)
    nidx=nidx[1]+nidx[2]*256+1
    local n = FRAMES.current.names[nidx]
    FRAMES.current.globals[n] = STACK:pop()
end

function STORE_NAME(nidx)
    nidx=nidx[1]+nidx[2]*256+1
    local n = FRAMES.current.names[nidx]
    FRAMES.current.locals[n]=STACK:pop()
end

function LOAD_NAME(nidx)
    nidx=nidx[1]+nidx[2]*256+1
    local n = FRAMES.current.names[nidx]
    if FRAMES.current.locals[n]==nil then
        if FRAMES.current.globals[n]~=nil then
            STACK:push(FRAMES.current.globals[n])
        else
            if builtins[n]==nil then
                error("NameError: "..n.." is not defined")
            end
            STACK:push(builtins[n])
        end
    else
        STACK:push(FRAMES.current.locals[n])
    end
end

function IMPORT_NAME(nidx)
    nidx=nidx[1]+nidx[2]*256+1
    local n = FRAMES.current.names[nidx]
    local fromlist = STACK:pop()
    local level = STACK:pop()
    if modules[n]~=nil then
        if (#fromlist) then
            STACK:push(modules[n])
        else
            for segment in n:gmatch('([^.]+)') do
                STACK:push(modules[segment])
                return
            end
        end
        return
    end
    local segment
    local path
    local searchpath = nil
    local m
    local segments = {}
    local pathSoFar=""
    
    local firstsegment = nil
    local parent
    for segment in n:gmatch('([^.]+)') do
        if firstsegment==nil then firstsegment=segment end
        path, searchpath = searchPath(segment, searchpath)
        if path==nil then
            error("ImportError: No module named "..segment)
        end
        if #segments>0 then
            pathSoFar = table.concat(segments,".").."."..segment
        else
            pathSoFar=segment
        end
        if modules[pathSoFar]==nil then
            local f=io.open(path,'rb')
            m = Frame:create(unmarshalModule(Reader(f)))
            m.locals.__file__=path
            m.locals.__class__=ModuleType
            setmetatable(m.locals, ModuleType)
            modules[pathSoFar]=m.locals
            EXECUTE(m)
            
            
            if parent~=nil then
                parent[segment]=m.locals
            end
        else
            parent=modules[pathSoFar]
        end
        
        
        
        table.insert(segments,segment)
        
        
    end
    if (#fromlist>0) then
        STACK:push(modules[n])
    else
        STACK:push(modules[firstsegment])
    end
    --STACK:push(m.locals)
    
    
    
end

function STORE_ATTR(nidx)
    nidx=nidx[1]+nidx[2]*256+1
    local n = FRAMES.current.names[nidx]
    local obj = STACK:pop()
    local val = STACK:pop()
    obj[n]=val
end

function LOAD_ATTR(nidx)
    nidx=nidx[1]+nidx[2]*256+1
    local n = FRAMES.current.names[nidx]
    local obj = STACK:pop()
    local ret
    if hasattr(obj, '__getattribute__') then
        ret = obj.__getattribute__(n)
    else
        ret = obj[n]
    end
    if hasattr(ret, "__ismethod") or (getmetatable(ret)=="userdata") or hasattr(getmetatable(ret), '__call') or (hasattr(obj, '__class__') and obj.__class__ and obj.__class__~=Type and type(ret)=="function") then
        if (not hasattr(obj,'__class__') or obj.__class__~=ModuleType) and (not hasattr(ret, "__class__") or ret.__class__==Function) then
            ret = MethodProxy:New(obj,ret)
        end
    end
    if (ret==nil) then
        print(728, obj.__class__==list)
        print(700, n)
    end
    STACK:push(ret)
    
end

function IMPORT_FROM(nidx)
    nidx=nidx[1]+nidx[2]*256+1
    local n = FRAMES.current.names[nidx]
    local obj = STACK:pop()
    STACK:push(obj)
    if (obj[n]==nil) then
        print(740, obj, n)
    end
    STACK:push(obj[n])
end

function MAKE_FUNCTION(argc)
    local code = STACK:pop()
    argc=argc[1]+argc[2]*256
    local f = Function:Create(argc,code)
    STACK:push(f)
end

function CALL_FUNCTION_VAR(argc)
    error("unsupported opcode")
    local tos = STACK:pop()
    local i,v
    if isinstance(tos, list) then
        tos=tos.items
    end
    local positional = {}
    local kw = {}
    for i,v in pairs(tos) do
        STACK:push(v)
    end
    CALL_FUNCTION(argc)
end

function CALL_FUNCTION(argc)
    local npos = argc[1]
    local nkw = argc[2]
    local f = Frame:empty()
    local c = nil
    f.parent = FRAMES.current
    local idx
    local args = {}
    local kw = {}
    local startidx = 0
    local key
    for idx=1,nkw,1 do
        table.insert(kw, {STACK:pop(),STACK:pop()})
    end
    for idx=1,npos,1 do
        table.insert(args, 1,STACK:pop())
    end
    local func = STACK:pop()
    if type(func)=="function" then --native lua function
        local ret = {func(unpack(args))}
        if #ret==1 then
            ret = ret[1]
        end
        if ret==nil then ret = None end
        STACK:push(ret)
        return
    end
    
    if func.__class__ == MethodProxy then
        local m = func.method
        local r = m(func.self, unpack(args))
        if r==nil then r = None end
        STACK:push(r)
        return
    end
    
    if hasattr(func, 'func_self') then
        startidx = 1
        f.locals['self']=func.func_self
    end
    if func.__class__==Type then
        c = func
        func = Type.__new__
    end
    
    
    local val
    
    
    if c~=nil then
        if func==Type.__new__ then
            local o, initted = Type.__new__(c, unpack(args), kw)
            if initted then
                STACK:push(o)
                return
            end
            if hasattr(o, "__init__") then
                func = o.__init__ 
            else 
                func = object.__init__
            end
            f.locals['self']=o
            startidx=1
            if type(func)=="function" then 
                func(o)
                STACK:push(o)
                return
            end
            
            local varargs = bit32.band(func.flags, 0x04)/0x04
            local kwargs  = bit32.band(func.flags, 0x08)/0x08
            local argcount = func.argcount
            idx = 1
            while idx <= npos and idx <= func.argcount do
                f.locals[func.varnames[idx+startidx]]=args[idx]
                idx = idx + 1
            end
            
            
            if varargs>0 then
                local va = {}
                while idx <= npos do
                    table.insert(va, args[idx-1])
                    idx = idx + 1
                end
                f.locals[func.varnames[func.argcount+1]]=va
            end
            
            for idx,val in pairs(kw) do
                key=val[2]
                val=val[1]
                if table.contains(func.varnames, key, func.argcount) then
                    f.locals[key]=val
                    table.remove(kw,idx)
                end
            end
            if (kwargs > 0) then
                local k = {}
                for idx,val in pairs(kw) do
                    k[val[2]]=val[1]
                end
                f.locals[func.varnames[func.argcount+1+varargs]] = k
            else
                for idx,val in pairs(kw) do
                    error("TypeError: "..func.." got unexpected keyword argument '"..val[2].."'")
                end
            end
            
            
            
            for idx,val in pairs(func.func_defaults) do
                if f.locals[func.varnames[func.argcount+1 - idx]]==nil then
                    f.locals[func.varnames[func.argcount+1 - idx]] = val
                end
            end
            f.varnames=func.varnames
            f.names=func.names
            f.constants=func.constants
            f.filename=func.filename
            f.func=func
            f.globals=c.__globals__
            --f.ops=func.ops
            f.code=func.code
            f.lnotab=func.lnotab
            f.locals['self']=o
            local r = EXECUTE(f)
            STACK:push(o)
            return
        else
            error("__new__ not yet implemented in python")
        end
    else
        local varargs = bit32.band(func.flags or 0, 0x04)/0x04
        local kwargs  = bit32.band(func.flags or 0, 0x08)/0x08
        local argcount = func.argcount
        idx = 1
        if func.varnames~=nil and func.varnames[1]~="self" then
            startidx = 0
        end
        
        while func.varnames~=nil and idx <= npos and (func.argcount==nil or idx <= func.argcount) do
            f.locals[func.varnames[idx+startidx]]=args[idx]
            idx = idx + 1
        end
        
        if varargs>0 then
            local va = {}
            while idx <= npos do
                table.insert(va, args[idx])
                idx = idx + 1
            end
            f.locals[func.varnames[func.argcount+1]]=va
        end
        
        for idx,val in pairs(kw) do
            key=val[2]
            val=val[1]
            if table.contains(func.varnames, key, func.argcount) then
                f.locals[key]=val
                table.remove(kw,idx)
            end
        end
        if (kwargs > 0) then
            local k = {}
            for idx,val in pairs(kw) do
                k[val[2]]=val[1]
            end
            f.locals[func.varnames[func.argcount+1+varargs]] = k
        else
            for idx,val in pairs(kw) do
                error("TypeError: "..tostring(func).." got unexpected keyword argument '"..val[2].."'")
            end
        end
        if hasattr(func, 'func_defaults') then
            for idx,val in pairs(func.func_defaults) do
                if f.locals[func.varnames[func.argcount+1 - idx]]==nil then
                    f.locals[func.varnames[func.argcount+1 - idx]] = val
                end
            end
        end
        f.code=func.code
        --f.ops=func.ops
        f.varnames=func.varnames
        f.names=func.names
        f.constants=func.constants
        f.filename=func.filename
        f.func=func
        f.globals=func.globals
        local r = EXECUTE(f)
        if r==nil then r = None end
        STACK:push(r)
    end
end

function LOAD_FAST(num)
    num=num[1]+num[2]*256+1
    local n = FRAMES.current.varnames[num]
    STACK:push(FRAMES.current.locals[n])
end

function BUILD_TUPLE(num)
    num=num[1]+num[2]*256
    local o = tuple.__new__()
    local idx
    for idx=1,num,1 do
        table.insert(o.items, 1, STACK:pop())
        o.length=num
    end
    STACK:push(o)
end

function BUILD_CLASS()
    local i,v
    local md = STACK:pop()
    local bc = STACK:pop()
    local cn = STACK:pop()
    local c = {__bases__=bc}
    setmetatable(c, Type)
    c.__name__=cn
    c.__module__=FRAMES.current
    c.__globals__=FRAMES.current.globals
    c.__class__=Type
    for i,v in pairs(md) do
        c[i]=v
        if hasattr(v, "__class__") and rawget(v, "__class__")==Function then
            v.__ismethod=true
        end
    end
    STACK:push(c)
    
end

function LOAD_LOCALS()
    STACK:push(FRAMES.current.locals)
end

function SETUP_LOOP(delta)
    delta=delta[1]+delta[2]*256
    local ops = {}
    local idx
    for idx=FRAMES.current.idx, FRAMES.current.idx+delta, 1 do
        ops[idx] = FRAMES.current.code[idx]
    end
    FRAMES.current.blocks:push({ops, FRAMES.current.idx+delta})
end

function FOR_ITER(delta)
    delta=delta[1]+delta[2]*256
    local itr, val
    if STACK:getn()==0 then 
        val=StopIteration
    else
        itr = STACK:pop()
        val = itr:next()
        if val==nil then
            val = StopIteration
        end
    end
    if (val~=StopIteration) then
        STACK:push(itr)
        STACK:push(val)
    else
        FRAMES.current.idx = FRAMES.current.idx + delta
    end
end
function JUMP_FORWARD(delta)
    delta=delta[1]+delta[2]*256
    FRAMES.current.idx = FRAMES.current.idx + delta 
end
function POP_JUMP_IF_FALSE(target)
    target=target[1]+target[2]*256+1
    local a = STACK:pop()
    if not __test_if_true__(a) then
        FRAMES.current.idx = target
    end
end

function JUMP_IF_TRUE_OR_POP(target)
    target=target[1]+target[2]*256+1
    local a = STACK:pop()
    if __test_if_true__(a) then
        STACK:push(a)
        FRAMES.current.idx = target
    end
end

function JUMP_IF_FALSE_OR_POP(target)
    target=target[1]+target[2]*256+1
    local a = STACK:pop()
    if not __test_if_true__(a) then
        STACK:push(a)
        FRAMES.current.idx = target
    end
end

function POP_JUMP_IF_TRUE(target)
    target=target[1]+target[2]*256+1
    local a = STACK:pop()
    if __test_if_true__(a) then
        FRAMES.current.idx = target
    end
end

function BREAK_LOOP()
    local block = FRAMES.current.blocks:pop()
    FRAMES.current.idx=block[2]
end

function JUMP_ABSOLUTE(target)
    target=target[1]+target[2]*256+1
    FRAMES.current.idx = target
end

function COMPARE_OP(opnum)
    opnum=opnum[1]+opnum[2]*256+1
    local a=STACK:pop()
    local b=STACK:pop()
    local c = cmp_op[opnum](a,b)
    STACK:push(c)
end

function POP_BLOCK()
    local block = FRAMES.current.blocks:pop()
    --FRAMES.current.idx=block[1]
end

function STORE_FAST(nidx)
    nidx=nidx[1]+nidx[2]*256+1
    FRAMES.current.locals[FRAMES.current.varnames[nidx]]=STACK:pop()
end

function STORE_MAP()
    local a,b,c
    a=STACK:pop()
    b=STACK:pop()
    c=STACK:pop()
    c[a]=b
    STACK:push(c)
end
function BUILD_LIST(num)
    num=num[1]+num[2]*256
    local o = list.__new__()
    local idx
    for idx=1,num,1 do
        table.insert(o.items, 1, STACK:pop())
        o.length=num
    end
    STACK:push(o)
end

function UNPACK_SEQUENCE(count)
    count=count[1]+count[2]*256
    local tos = STACK:pop()
    local idx
    for idx=1,count,1 do
        STACK:push(tos[count-idx+1])
    end
end

function LIST_APPEND(i)
    i=i[1]+i[2]*256
    local tos=STACK:pop()
    local array=STACK:peek(i-1)
    if hasattr(array, 'append') then
        array:append(tos)
    else
        table.insert(array, tos)
    end
end

function DELETE_SUBSCR()
    local tos=STACK:pop()
    local tos1=STACK:pop()
    if hasattr(tos1, '__class__') then
        if hasattr(tos1, '__delitem__') then
            tos1:__delitem__(tos)
        end
    else
        tos1[tos]=nil
    end
end

local opcode_sizes = {}

opcode_sizes[25]=0
opcode_sizes[94]=2
opcode_sizes[92]=2
opcode_sizes[82]=0
opcode_sizes[110]=2
opcode_sizes[105]=2
opcode_sizes[87]=0
opcode_sizes[93]=2
opcode_sizes[19]=0
opcode_sizes[83]=0
opcode_sizes[24]=0
opcode_sizes[100]=2
opcode_sizes[71]=0
opcode_sizes[72]=0
opcode_sizes[89]=0
opcode_sizes[90]=2
opcode_sizes[20]=0
opcode_sizes[101]=2
opcode_sizes[106]=2
opcode_sizes[115]=2
opcode_sizes[108]=2
opcode_sizes[109]=2
opcode_sizes[1]=0
opcode_sizes[13]=0
opcode_sizes[124]=2
opcode_sizes[132]=2
opcode_sizes[131]=2
opcode_sizes[102]=2
opcode_sizes[23]=0
opcode_sizes[116]=2
opcode_sizes[26]=0
opcode_sizes[22]=0
opcode_sizes[120]=2
opcode_sizes[68]=0
opcode_sizes[3]=0
opcode_sizes[28]=0
opcode_sizes[55]=0
opcode_sizes[56]=0
opcode_sizes[97]=2
opcode_sizes[113]=2
opcode_sizes[125]=2
opcode_sizes[107]=2
opcode_sizes[114]=2
opcode_sizes[80]=0
opcode_sizes[73]=0
opcode_sizes[74]=0
opcode_sizes[54]=0
opcode_sizes[61]=0
opcode_sizes[95]=2
opcode_sizes[103]=2
opcode_sizes[140]=2
opcode_sizes[60]=0
opcode_sizes[4]=0
opcode_sizes[2]=0
opcode_sizes[57]=0
opcode_sizes[12]=0
opcode_sizes[112]=2
opcode_sizes[111]=2
opcode_sizes[70]=0

opmap = {}
opmap[61]=DELETE_SUBSCR
opmap[94]=LIST_APPEND
opmap[70]=PRINT_EXPR
opmap[111]=JUMP_IF_FALSE_OR_POP
opmap[112]=JUMP_IF_TRUE_OR_POP
opmap[12]=UNARY_NOT
opmap[140]=CALL_FUNCTION_VAR
opmap[57]=INPLACE_MULTIPLY
opmap[28]=INPLACE_FLOOR_DIVIDE
opmap[25]=BINARY_SUBSCR
opmap[110]=JUMP_FORWARD
opmap[3]=ROT_THREE
opmap[4]=DUP_TOP
opmap[2]=ROT_TWO
opmap[13]=UNARY_CONVERT
opmap[26]=BINARY_FLOOR_DIVIDE
opmap[22]=BINARY_MODULO
opmap[54]=STORE_MAP
opmap[105]=BUILD_MAP
opmap[80]=BREAK_LOOP
opmap[87]=POP_BLOCK
opmap[113]=JUMP_ABSOLUTE
opmap[93]=FOR_ITER
opmap[68]=GET_ITER
opmap[116]=LOAD_GLOBAL
opmap[92]=UNPACK_SEQUENCE
opmap[97]=STORE_GLOBAL
opmap[19]=BINARY_POWER
opmap[82]=LOAD_LOCALS
opmap[83]=RETURN_VALUE
opmap[100]=LOAD_CONST
opmap[71]=PRINT_ITEM
opmap[72]=PRINT_NEWLINE
opmap[73]=PRINT_ITEM_TO
opmap[74]=PRINT_NEWLINE_TO
opmap[60]=STORE_SUBSCR
opmap[89]=BUILD_CLASS
opmap[90]=STORE_NAME
opmap[20]=BINARY_MULTIPLY
opmap[101]=LOAD_NAME
opmap[106]=LOAD_ATTR
opmap[108]=IMPORT_NAME
opmap[109]=IMPORT_FROM
opmap[1]=POP_TOP
opmap[132]=MAKE_FUNCTION
opmap[131]=CALL_FUNCTION
opmap[124]=LOAD_FAST
opmap[23]=BINARY_ADD
opmap[55]=BINARY_ADD
opmap[24]=BINARY_SUBTRACT
opmap[102]=BUILD_TUPLE
opmap[120]=SETUP_LOOP
opmap[125]=STORE_FAST
opmap[107]=COMPARE_OP
opmap[56]=INPLACE_SUBTRACT
opmap[114]=POP_JUMP_IF_FALSE
opmap[115]=POP_JUMP_IF_TRUE
opmap[103]=BUILD_LIST
opmap[95]=STORE_ATTR

Function = {}
function Function:__tostring()
    return "<function "..self.name..">"
end
function Function:__call(...)
    local f = Frame:empty()
    --f.ops=self.ops
    f.varnames=self.varnames
    f.names=self.names
    f.constants=self.constants
    f.filename=self.filename
    f.func=self
    f.globals=self.globals
    f.locals = {}
    f.lnotab = self.lnotab
    f.code=self.code
    local offset = 0
    local idx,v
    if self.func_self~=nil then
        f.locals['self']=self.func_self
        offset = 1
    end
    for idx,v in pairs({...}) do
        f.locals[self.varnames[idx+offset]]=v
    end
    return EXECUTE(f)
    
end

function Function:Create(argc, t)
    local f = {__class__=Function}
    f.varnames = t[8]
    f.names = t[7]
    f.constants = t[6]
    --f.ops = {}
    local offset = 1
    f.op_offsets = {}
    local code = t[5]
    f.globals = FRAMES.current.globals
    f.code={}
    while true do
        local i = code:sub(1,1):byte()
        code=code:sub(2)
        table.insert(f.code,i)
        if code=="" then
            break
        end
    end
    
    local idx
    f.func_defaults={}
    for idx=1,argc,1 do
        table.insert(f.func_defaults, 1, STACK:pop())
    end
    f.argcount = t[1]
    f.nlocals = t[2]
    f.flags = t[4]
    f.name = t[12]
    f.filename = t[11]
    f.lnotab = t[14]
    setmetatable(f,Function)
    --return {argcount, nlocals, stacksize, flags, code, consts, names, varnames, freevars, cellvars, filename, name, firstlineno, lnotab}
    return f
end

Frame = {}
function Frame:__tostring()
    if self.parent~=nil then
        return "<frame for "..self.func.name.." in "..tostring(self.parent)..">"
    end
    return "<frame for "..self.filename..">"
end

function Frame:empty()
    local f = {}
    setmetatable(f, Frame)
    f.locals = {}
    return f
end

function Frame:create(t)
    local f = {}
    f.locals = {}
    f.names = t[7]
    f.constants = t[6]
    --f.ops = {}
    f.op_offsets = {}
    local offset = 1
    f.filename=t[11]
    f.globals=f.locals
    f.func_defaults = {}
    local code = t[5]
    f.code={}
    f.lnotab = t[14]
    while true do
        os.sleep(0)
        local i = code:sub(1,1):byte()
        code=code:sub(2)
        table.insert(f.code,i)
        if code=="" then
            break
        end
    end
   
    setmetatable(f,Frame)
    return f
    
end




modules={}
FRAMES=Stack:Create()
FRAMES.current=0
function EXECUTE(...)
    local arg = {...}
    local f = arg[1]
    FRAMES:push(FRAMES.current)
    FRAMES.current=f
    f.idx = 1
    f.blocks = Stack:Create()
    while true do
        local opcode = f.code[f.idx]
        f.idx = f.idx+1
        local largs = opcode_sizes[opcode]
        if largs==nil then
            error("Invalid opcode: " .. opcode)
        end
        local opargs = {}
        while largs > 0 do
            table.insert(opargs, f.code[f.idx])
            largs = largs - 1
            f.idx = f.idx + 1
        end
        
    --    if opcode==131 then
--          print (723, opcode, opargs:byte(1, 2), STACK:getn())
      --  end
        local func = opmap[opcode]
        if func==nil then
            error("Invalid opcode (but opcode in size table): " .. opcode)
        end
        local ret = func(opargs)
        --ninstructions = ninstructions + 1
--        print(731,STACK:getn(), FRAMES:getn())
        --print (ninstructions)
        if ret~=nil then
            FRAMES.current=FRAMES:pop()
            return ret
        end
    end
end


TYPES["\0"]=TYPE_NULL
TYPES["N"]=TYPE_NONE 
TYPES["F"]=TYPE_FALSE
TYPES["T"]=TYPE_TRUE
TYPES["S"]=TYPE_STOPITER
TYPES["i"]=TYPE_INT
TYPES["I"]=TYPE_INT64
TYPES["g"]=TYPE_BINARY_FLOAT
TYPES["l"]=TYPE_LONG
TYPES["s"]=TYPE_STRING
TYPES["t"]=TYPE_INTERNED
TYPES["R"]=TYPE_STRINGREF
TYPES["u"]=TYPE_UNICODE
TYPES["c"]=TYPE_CODE
    

TYPES["0"]=TYPE_NULL
TYPES["."]=TYPE_ELLIPSIS
TYPES["("]=TYPE_TUPLE 
TYPES["["]=TYPE_LIST
TYPES["{"]=TYPE_DICT
TYPES[">"]=TYPE_FROZENSET



function execfile(path)
    local f = io.open(path,'rb')
    local reader=python.Reader(f)
    local m=python.load(reader)
    local frame = Frame:create(m)
    return EXECUTE(frame), frame
    --return dotry(EXECUTE,frame), frame
end
builtins.Reader=Reader
builtins.load=unmarshalModule
builtins.exec=EXECUTE
builtins.Frame=Frame
builtins.EXECUTE=EXECUTE
builtins.FRAMES=FRAMES
builtins.unmarshal=unmarshal
builtins.TYPE_CODE=TYPE_CODE

python = {Reader=Reader, load=unmarshalModule,path=PYTHONPATH,execfile=execfile}
local imported = false
for i,v in pairs({...}) do 
    if v=='python' or v=='./python' then
        imported = true
    end
end
if ...=="python/python" or imported then
    return python
else
    if arg==nil then
       arg={...}
    end
    execfile(arg[1])
end


