function init()   
	status.setStatusProperty("sexbound_pregnant", true)  
end

function uninit() 
	if (math.random() <= 0.1) then -- 10% chance
		world.spawnItem("sexbound_keystoneI",entity.position(),1)
	end
	status.setStatusProperty("sexbound_pregnant", false)
end