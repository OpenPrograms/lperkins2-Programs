local python=require('python/python')
local None, SimpleDB=python.execfile('/usr/lib/python2/SimpleDB.pyc')

local SDB=SimpleDB.locals['SimpleDB']

function newDB(path)
    local db=Type.__new__(SDB)
    db:__init__(path)
    return db
end

return {SimpleDB=newDB}
