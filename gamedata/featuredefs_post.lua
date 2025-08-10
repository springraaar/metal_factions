 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Borrowed from ZK mid 2025 to avoid crash with recent engine builds
-- that no longer tolerate invalid model references on feature defs
 
local function isModelOK(fd)
	local specifiesModel = fd.object and (fd.object ~= "")

	-- explicitly modelless (geo etc)
	if fd.drawtype == -1 and not specifiesModel then
		return true
	end

	-- implicitly modelless
	if not fd.drawtype and not specifiesModel then
		return true
	end

	-- explicitly specified to use a model, but doesn't provide one (gigachad.jpg)
	if fd.drawtype == 0	and not specifiesModel then
		return false
	end

	-- old tree renderer removed from engine
	if tonumber(fd.drawtype or 0) > 0 then
		return false
	end

	-- no model specified but got through the previous checks, let it through
	-- ZK code didn't have this and would break on MF auxiliary mex spot feature defs
	if not specifiesModel then
		return true
	end
	
	local modelPath = "objects3d/" .. fd.object
	return VFS.FileExists(modelPath          , VFS.ZIP)
	    or VFS.FileExists(modelPath .. ".3do", VFS.ZIP)
end

for name, def in pairs(FeatureDefs) do
	if not isModelOK(def) then
		Spring.Log("featuredefs_post.lua", LOG.WARNING, "missing/invalid model ("..tostring(def.object)..") feature "..name.." removed")
		FeatureDefs[name] = nil
	end
end