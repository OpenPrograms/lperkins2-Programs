function doisinstance(item, class)
    if item.__class__==class then
        return true
    end
    
    local idx,base
    for idx,base in pairs(item.__bases__) do
        if item.__class__ == base then
            return true
        end
        if base~=object and isinstance(item, base) then
            return true
        end
    end
    return false
end

helperTable = {
    __index=function(self,key)
        local cls = rawget(self, "__class__")
        if cls.__getattribute__~=nil then
            return cls.__getattribute__(self, key)
        end
        if rawget(self, key)~=nil then
            return rawget(self, key)
        end
        if cls[key]~=nil then
            return cls[key]
        end
        if cls.__getattr__~=nil then
            return cls.__getattr__(self,key)
        end
        error("AttributeError: "..key)
    end,
    __tostring=function(self)
        return self.__class__.__repr__(self).s
    end
}





function isinstance(item, class)
    local success,ret=pcall(doisinstance,item,class)
    return success and ret
end

function table.shallow_copy(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end


object = {__name__="object", __tostring=function(self) return self:__repr__() end, __index=object}
function object:__repr__()
    return "<object "..self.__class__.__name__..">"
end
None = {__repr__=function() return "None" end}
StopIteration = {__repr__=function() return "StopIteration" end}

setmetatable(StopIteration, object)

setmetatable(None, object)



Type={
    __bases__={object},
    __new__=function(cls, ...)
        if cls.__new__~=nil then
            return cls:__new__(...), true
        end
        local o = {__class__=cls}
        setmetatable(o, helperTable)
        return o, false
    end,
    __tostring=function(self)
        if self.__repr__~=nil then
            return str:__new__(self:__repr__()).s
        end
        return "something"
    end,
    __index=Type,
    idx = function(self,key)
        local idx,i 
        if (self.__getattribute__~=nil) then
            return self:__getattribute__(key)
        end
        for idx,i in pairs(self.__bases__) do
            if rawget(i, "__getattribute__") ~=nil then
                return i.__getattribute__(self, key)
            end
        end
        i = rawget(self, key)
        if i~=nil then
            return i
        end
        for idx,i in pairs(self.__bases__) do
            if rawget(i, key) ~=nil then
                return i[key]
            end
        end
        if rawget(self, "__getattr__")~=nil then
            return self:__getattr__(key)
        end
        for idx,i in pairs(self.__bases__) do
            if rawget(i, "__getattr__") ~=nil then
                return i.__getattr__(self, key)
            end
        end
    end
}


setmetatable(Type, {__tostring=function(self) return "<type type>" end
})

function Type:__call(...)
    return self.__new__(...)
end


__test_if_true__ = function( x )
    if x == true then return true
    elseif x == false then return false
    elseif x == nil then return false
    elseif x == '' then return false
    elseif x == None then return false
    elseif type(x) == 'number' then
        if x == 0 then return false
        else return true
        end

    elseif x.__class__ and x.__class__.__name__ == 'list' then
        if x.length > 0 then return true
        else return false end
    elseif x.__class__ and x.__class__.__name__ == 'dict' then
        if x.keys().length > 0 then return true
        else return false end
    else
        return true
    end
end


function string:to_array()
    local i = 1
    local t = {}
    for c in self:gmatch('.') do
        t[ i ] = c
        i = i + 1
    end
    return t
end

function string:split(sSeparator, nMax, bRegexp)
    assert(sSeparator ~= '')
    assert(nMax == nil or nMax >= 1)
    if sSeparator == nil then
        sSeparator = ' '
    end

    local aRecord = {}

    if self:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1

        local nField=1 nStart=1
        local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = self:sub(nStart, nFirst-1)
            nField = nField+1
            nStart = nLast+1
            nFirst,nLast = self:find(sSeparator, nStart, bPlain)
            nMax = nMax-1
        end
        aRecord[nField] = self:sub(nStart)
    end
    return aRecord
end



__contains__ = function(lst, item)
    for __i,itm in pairs(lst) do
        if itm==item or __i==item then
            return true
        end
    end
    return false
end

function callAndPack(func, ...)
    return table.pack(func(...))
end

function apply(func, args_1, args_2)
    if args_2~=nil then
        return func(args_1, table.unpack(args_2, 1, #args_2))
    else
        return func(table.unpack(args_1, 1, #args_1))
    end
end




iterator={}
function iterator:__new__(arg)
    if isinstance(arg, list) then 
        return iterator:__new__(arg.items) 
    end
    local ret = {}
    ret.__class__=iterator
    setmetatable(ret,iterator)
    ret:__init__(arg)
    return ret
end

iterator.__call__=iterator.__new__

iterator.__index=iterator
iterator.__bases__={object}
iterator.__class__=Type
setmetatable(iterator, iterator.__class__)

function iterator:__init__(obj) 
    self.ptr = nil 
    
    self.obj=obj

    self.itr=pairs(obj) 
end

function iterator:next()
    local ret
    self.ptr, ret = self.itr(self.obj, self.ptr)
    if self.ptr == nil then
        return StopIteration
    end
    return ret
end


function iter(obj)
    if isinstance(obj, object) then
        return obj:__iter__()
    end
    return iterator:__new__(obj)
end

list={}


list.__new__=function(...)
    local arg={...}
    local ret = {}
    ret.__class__=list
    setmetatable(ret, list)
    ret:__init__(arg)
    return ret
end

list.__class__=Type
list.__call__=list.__new__
list.__call=list.__new__
list.__index=list
setmetatable(list,list.__class__)

function list.staticFromTable(t)
    return list:fromTable(t)
end

function list:fromTable(t)
    local l = list:__new__()
    l.items=t
    l.length=#t
    return l
end

list.__init__=function(self, items, kw)
    local pointer, length, i, v
    self.items={}
    self.length = 0
    if isinstance(items, list) then
        for i,v in pairs(items.items) do
            self.items[i]=v
        end
        self.length=items.length
        return
    end
    if items==nil or isinstance(items, object) then
        return
    end
    if items==list then
        error("250") end
    for i,v in pairs(items) do
        self.items[i]=v
    end
    self.length=i

end

function list:contains(value)
    local i,v
    for i,v in pairs(self.items) do
        if v==value then
            return true
        end
    end
    return false
end

function list:__getitem__(index)
    if type(index)=='number' and index < 0 then
        index = self.length + index
    end
    if type(index)~='number' then
        v=rawget(self,index)
        if v~=nil then return v end
        return self.__class__[index]
    end
    if self.items[index+1]==nil then
        error("IndexError: list index out of range")
    end
    return self.items[index+1]
end

function list:__setitem__(index,value)
    if type(index)~='number' then
        return rawset(self, index, value)
    end
    if self.items==nil then self.items={} end
    if self.length == nil then
        self.length=#self.items
    end
    if index < 0 then
        index = self.length + index
    end
    if index < 0 or index >= self.length then
        error("KeyError: Index out of bounds")
    end
    self.items[index+1]=value
    return None
end

function list:__iter__()
    if self.length==0 or self.length==nil then return iterator:__new__({}) end
    return iterator:__new__(self.items)
end

function list:__add__(other)
    local ptr
    local copy
    local item
    local i
    ptr = table.shallow_copy(self.items)
    copy = list.__new__()
    copy.items=ptr
    copy.length=self.length
    if isinstance(other, list) then
        other = other.items
    end
    for i,item in pairs(other) do
        copy:append(item)
    end
    return copy
end

function list:append(obj)
    if self.length==nil or self.length==0 then
        self.length=0
        self.items={}
    end
    self.length = self.length + 1
    self.items[self.length] = obj
    return None
end

function list:index(obj)
    local i=0
    while i < self.length do
        if self.items[i+1] == obj then
            return i
        end
        i = i + 1
    end
    return -1
end

function list:__str__()
    local r = str('[')
    local i = 1
    if self.length==nil then 
        if self.items~=nil then
            self.length=#self.items
        else
            self.length=0
        end
    end
    while i < self.length do
        local v = str(self.items[i])
        
        r = r + v
        r = r + str(', ')
        i = i + 1
    end
    if self.items~=nil then
        r = r + str(self.items[i])
    end
    r = r + ']'
    return r
end


function list:insert(idx, val)
    local i
    self.length = self.length + 1
    for i = self.length,idx+1,-1 do
        self.items[i+1]=self.items[i]
    end
    self.items[idx+1]=val
    return None
end


function list:pop(idx)
    self.length = self.length - 1
    return table.remove(self.items, idx+1)
end

function list:toTable()
    return self.items
end
list.__add=list.__add__
list.__concat=list.__add
list.__index = list.__getitem__
list.__class__ = Type
list.__bases__={list}
list.__newindex = list.__setitem__
list.__repr__=function(self) return self:__str__().s end
list.__tostring = function(self) 
return str(self:__repr__()).s end

function list:__len__()
    return self.length
end


tuple=table.shallow_copy(list)
tuple.insert = function() error("Tuples are imutable") end
tuple.append = function() error("Tuples are imutable") end
tuple.__setitem__=function() error("Tuples are imutable") end


tuple.__new__=function(cls, ...)
    local arg={...}
    local ret = {}
    ret.__class__=tuple
    setmetatable(ret, tuple)
    ret:__init__(unpack(arg))
    --apply(ret.__init__, ret, arg)
    return ret
end
setmetatable(tuple, getmetatable(list))

function tuple:__str__()
    local r = str('(')
    local i = 1
    if self.length==nil then 
        if self.items~=nil then
            self.length=#self.items
        else
            self.length=0
        end
    end
    while i < self.length do
        r = r + (self.items[i]):__repr__()
        r = r + str(', ')
        i = i + 1
    end
    if self.items~=nil then
        r = r + str(self.items[i])
    end
    r = r .. ')'
    return r
end
tuple.__repr__=tuple.__str__
tuple.__tostring = function(self) return str(self:__repr__()).s end
tuple.__call=tuple.__new__


str = {s=''}
str.__class__=Type
str.__bases__={object}

str.__new__=function(...)
    local ret = {}
    ret.__class__=str
    setmetatable(ret, str)
    ret:__init__(...)
    return ret
end


str.__index=str
setmetatable(str,str.__class__)



function str:__init__(obj, a)
    if obj==str then obj=a end
    if isinstance(obj, object) then
        self.s = obj:__str__().s
    else
        self.s = tostring(obj)
    end
end

function str:__add__(other)
    if type(self)=="string" then
        self=str:__new__(self)
    end
    if self.s==nil then self.s="" end
    if isinstance(other, str) then
        return str(self.s..other.s)
    end
    if type(other)~='string' then
        error("TypeError: cannot concatenate 'str' and '".. type(other) .. "' objects")
    end
    return str(self.s .. str(other).s)
end

function str:replace(pattern, new, limit)
    return str:__new__(self.s:gsub(pattern,new,limit))
end

function str:__iter__()
    return iter(list(self.s:to_array()))
end

function str:__str__()
    return self
end

function str:find(other)
    local start, stop
    start, stop = self.s:find(other)
    return start
end

function str:join(lst)
    local ret 
    local l
    local i, ii
    if type(lst) == list then
        l = list()
        ii=iter(lst)
        i=ii:next()
        while i ~= StopIteration do
            l:append(str(i).s)
            i=ii:next()
        end
    else
        l=list(lst)
    end
    ret = table.concat(l.items, self.s)
    ret = str(ret)
    return ret
end

function str:split(delim, limit)
    if type(delim) ~= str then
        delim = str(delim)
    end
    limit = limit or -1
    local ret
    local words = list()
    for word in (self.s..delim.s):gmatch("([^"..delim.s.."]*)"..delim.s) do
        limit = limit - 1
        words:append(str(word))
        if limit == 0 then 
            ret = words
            words = list()
        end
    end
    if ret then
        ret:append(delim:join(words))
        return ret
    end
    return words
end

function str:rsplit(delim, limit)
    if type(delim)~=str then
        delim=str(delim)
    end
    local res = self:split(delim)
    local res1 = list()
    local idx = 0
    local i
    while (idx >= 0) do
        res1:append(res[idx])
        if res[idx + limit + 1] == nil then
            res1 = delim:join(res1)
            local res2 = list()
            res2:append(res1)
            for i = 1,limit,1 do
                res2:append(res[idx + i])
            end
            return res2
        end
        idx = idx + 1
    end
end


function str:startswith(other)
    return self:find(other)==1
end

function str:endswith(other)
    local a,b = self.s:find(other)
    return b==#self.s
end

function str:__tostring()
    return self.s
end

function str:sub(start,stop)
    return self.s:sub(start,stop)
end

function str:__repr__()
    return self.s
end

function str.__add(self, other)
    return str.__add__(self, other)
end

str.__concat = str.__add


dict={}


dict.__new__=function(...)
	local ret = {}
	ret.__class__=dict
	setmetatable(ret, dict)
    ret:__init__(args)
	return ret
end


dict.__index=dict
dict.__class__=Type
setmetatable(dict,dict.__class__)

dict.__init__=function(self, items, kw)
	local length
	if kw and kw.length then
		length=kw.length
	else
		if items~= nil then
			length=#items
		else
			length=0
		end
	end
	self.keys=list()
	self.values=list()
	if items == nil then
		self.length=0
		return
	end
	self.length=length
	local i
	local v
	local k
	if type(items) == dict then
		i = iter(items)
		v = i:next()
		while v ~= StopIteration do
			self.keys:append(v)
			self.values:append(items[v])
			v=i:next()
		end
	end
	if type(items) == 'nil' then
		self.length=0
		return
	end
	if type(items) == 'table' then
		for i,v in pairs(items) do
			self.keys:append(v[1])
			self.values:append(v[2])
		end
		return
	end
	if type(items) == list then	
		i = iter(items)
		v = i:next()
		while v ~= StopIteration do
			self.keys:append(v[0])
			self.values:append(v[1])
			v=i:next()
		end
	end
end

function dict:contains(value)
	return self.keys:contains(value)
end

function dict:__getitem__(item)
	if type(item)=='string' and string.find(item, '__') then
		return dict[item]
	end
	if self.keys:contains(item) then
		return self.values:__getitem__(self.keys:index(item))
	end
	return dict[item]
end

function dict:__setitem__(index,value)
	if index == 'keys' or index == 'values' or index == 'length' or (type(index)=="string" and string.find(index, '__')) then
		return rawset(self, index, value)
	end
	if not self:contains(index) then
		self.length = self.length + 1
		self.keys:append(index)
		self.values:append(value)
		return
	end
	self.values:__setitem__(self.keys:index(index),value)
end

function dict:__iter__()
	return iter(self.keys)
end


function dict:update(obj)
	local i, v
	for i,v in pairs(obj) do
		if not self:contains(i) then
			self.length = self.length + 1
		end
		self[i] = v
	end
end

function dict:keys()
	local k = list()
	local i
	local v
	for i,v in pairs(self) do
		k:append(i)
	end
	return k
end

function dict:values()
	local v = list()
	local i
	local k
	for k,i in pairs(self) do
		v:append(i)
	end
	return v
end


strbuilding={}

function dict:__str__()
	if self.length == 0 then
		return str("{}")
	end
    if strbuilding[self] then
        return "..."
    end
    strbuilding[self]=true
	local r = str('{')
	local v
	local i = 1
	while i < self.length do
		r = r + str(self.keys[i]) + ':' + str(self.values[i])+', '
		i = i + 1
	end
	r = r + str(self.keys[i]) + ':' + str(self.values[i])
	r = r + '}'
    strbuilding[self]=false
	return r
end

dict.__add=dict.__add__
dict.__concat=dict.__add
dict.__index = dict.__getitem__
dict.__newindex = dict.__setitem__
dict.__repr__=dict.__str__

dict.__tostring = function(self) return str(self:__repr__()).s end


return {str=str,list=list,tuple=tuple,iter=iter,dict=dict,StopIteration=StopIteration}
