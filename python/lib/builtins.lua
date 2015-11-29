component = require("component")
filesystem=require('filesystem')
local builtins

function getitem(obj, item)
    return obj[item]
end

function getattr(obj, attr)
    return obj[attr]~=nil
end

function hasattr(obj, attr)
    success, success1=pcall(getattr, obj, attr)
    return success and success1
end

function fetchItem(...)
    return component.savedmultipart.fetchItem(...)
end

function makeCallback(func)
    function cb(...)
        return func(...)
    end
    return cb
end

function typeof(a)
    t=type(a)
    if t=="function" or t=="number" or t=="string" then return t end
    return a.__class__
end


builtins = {
    typeof=typeof,
    makeCallback=makeCallback,
    getattr=getattr,
    hasattr=hasattr,
    True=true,error=error,
    pcall=pcall,
    list=list,
    tuple=tuple,
    str=str,
    len=function(o) return #o end,
    dir=function(...)
        local arg = {...}
        if arg.n==0 then
            return builtins.dir(FRAMES.current.locals)
        end
        
        local obj=arg[1]
        if obj['__dict__']~=nil then
            return obj.__dict__:keys()
        end
        local ret = {}
        local i,v
        for i,v in pairs(obj) do
            table.insert(ret, i)
        end
        return ret
    end,
    range=function(...)
        print(22)
        local arg={...}
        local out = {}
        local idx
        local start
        local stop
        local step
        if #arg==1 then
            start=0
            stop=arg[1]-1
            step=1
        elseif #arg==2 then
            start=arg[1]
            stop=arg[2]-1
            step=1
        else
            start=arg[1]
            stop=arg[2]-1
            step=arg[3]
        end
        for idx=start,stop,step do
            table.insert(out,idx)
        end
        return out
    end,
    open=filesystem.open,
    input=io.read,
    os=os,
    globals=function() return builtins.FRAMES.current.globals end,
    
    
}

os.write=function(fh, txt)
    return fh:write(txt)
end

builtins.__builtins__=builtins



return builtins
