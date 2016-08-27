Sleep = {}
Sleep.__index = Sleep

function Sleep.create()
   local obj = {}             -- our new object
   setmetatable(obj,Sleep)  -- make Sleep handle lookup
   return obj
end

function Sleep:Name()
	return "Sleep"
end

function Sleep:internalName()
	return "sleep"
end

function Sleep:Init()
	self.sleeping = {}
end

function Sleep:Update()
	local done = {}
	for k,v in pairs(self.sleeping) do
		if (v-1) == 0 then
			self:Wakeup(k)
			table.insert(done,k)
		end
		self.sleeping[k] = v -1
	end
	for i=1,#done do
		self:Kill(done[i])
	end
	done = nil
end

function Sleep:Wait(functor, frames)
	if functor == nil then
		log("functor == nil in Sleep:Wait ")
	else
		self.sleeping[functor] = frames
	end
end

function Sleep:Wakeup(key)
	if key == nil then
		log("key == nil in Sleep:Wakeup()")
	else
		if type(key) == "table" then
			if key.wakeup ~= nil then
				key:wakeup()
			else
				log("key:wakeup == nil in Sleep:Wakeup")
			end
		else
			key()
		end
	end
end

function Sleep:Kill(key)
	self.sleeping[key] = nil
end
