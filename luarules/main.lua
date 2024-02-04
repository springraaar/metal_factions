if (select == nil) then
  select = function(n,...) 
    local arg = arg
    if (not arg) then arg = {...}; arg.n = #arg end
    return arg[((n=='#') and 'n')or n]
  end
end

VFS.Include("lualibs/security.lua") -- security overrides
VFS.Include("LuaGadgets/gadgets.lua")
