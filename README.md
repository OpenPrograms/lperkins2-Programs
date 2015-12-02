#####NAME
  python - execute .pyc or .pyo file using the python.lua VM

#####SYNOPSIS
  python <file.pyc> [args ...]

#####DESCRIPTION
  `python` executes marshalled python code using a state machine
  It is also possible to require('python/python') and then call execfile('something.pyc')
  The return from execfile is the return value from the marshalled code object 
  (usually None), and the global frame for the file.  The variables defined in the
  python code can be retrieved from frame.locals.  
  
######DATA TYPES
    python.lua implements several data types which have analogues in lua, and
    uses some lua types directly.
    Python data types are implemented as tables.
    
    Numbers in python are just lua numbers
    
    String literals and strings returned from lua are lua strings.
    Python strings can be created via str(o), and support most of the usual python
    str operations (find, split, ...).  somestr.s is the underlying lua string.
    
    list and dict literals create lua tables, python lists and dicts are creatable
    by specifically invoking list() and dict().  Additionally, lists can be created
    from lua tables via list.staticFromTable(t), and converted back to tables via 
    l.toTable()
    
    Dictionaries are still alpha, so it is recommended to just use lua tables.
    
    Classes are supported, but must explicitly subclass something (object, type, another class ...)
    Additionally, they must define a __repr__ method which returns either a string or
    str.  __repr__ is used both to represent the class and instances of the class
    
    Python functions can be called from lua, and lua functions can be called from python
    python does not use : to specify binding the containing object to self in a function
    body, so the python vm tries to determine when it is appropriate to do so.  In some
    cases with lua functions, it cannot, so the self argument must be specified
    explicitly.
        f=filesystem.open(path)
        txt=f.read(f,length)
    When a lua function returns nil, it is automatically converted to None.  nil
    should never appear in the python vm, since it cannot be put on the python stack.
    This means failed attribute lookups raise an AttributeError or similar.  Use
    hasattr(obj,attr) to determine if the attribute exists.
  
######IMPORTS
    lua libraries may be require()d, python libraries may be import ed
    The python path defaults to /usr/lib/python2
    additional libraries may be specified via set PYTHONPATH=loc1:loc2
    Note that python libraries must end in .pyc (.pyo files are ignored)
    lua libraries persist across runs (package.loaded)
    python libraries are discarded when then vm shuts down.
    Relative imports are unreliable, so use absolute imports
  
######THREADING
    The python vm does not support threading between python functions.  If the coroutine
    holding the python vm yields, when it resumes, the python stack must be in exactly
    the same state or unpredictable errors result.  

######EXCEPTION HANDLING
    try/except is not supported.  For pure lua functions, use pcall.  For python 
    functions use dotry(EXECUTE, frame), where frame=Frame.create(Frame, code)
    

######PERFORMANCE
    Not as bad as one might expect, but function calls are very expensive.  Also,
    unmarshalling modules requires a lot of memory, so anything large will require
    a tier 3 computer with at least 1 tier 3 memory card.  

  Not all opcodes are implemented, specifically,  func(*args, **kw) and its variants
  is not supported (due to the documentation for it being junk).  Instead, use apply(func,args)
  
  Also, returning multiple values from lua is not reiably supported.  The function
  callAndPack(func,arg1,...) will return a lua table containing all the return values.
  
  Pay attention to your data types, remember, python lists index from 0, lua tables
  index from 1.
  
  Since python.lua lacks a lexile parser, the .pyc files must be generated by some
  remote computer.  In /usr/lib/python2, there's a fuse module which can be set up
  by a server admin and a CC disk (or OC if caching is disabled) (linux/posix only).
  More generally, an internet card + wget lets you copy .pyc files to the computer;
  compile them on the host via python -m compileall <filename>.  In the near future,
  I'll set up a publically accessible compillation server, and write a script to
  send the local python files to it automatically.  
