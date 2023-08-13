function init()
  -- Set 'sexbound_sex' status property to true.
  status.setStatusProperty("sexbound_milkmode", true)
  --world.sendEntityMessage(entity.id(), "Sexbound:Status:Add", (local statusName = "sexbound_milkmode", local duration = 99999)), function(result)
end

function update(dt)
  status.setStatusProperty("sexbound_milkmode", true)
end

function uninit()
  -- Set 'sexbound_sex' status property to false.
  status.setStatusProperty("sexbound_milkmode", false)
end
