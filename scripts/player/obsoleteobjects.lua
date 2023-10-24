require "/scripts/util.lua"
require "/scripts/rect.lua"

function init()
	script.setUpdateDelta(10)
end

--calls pretty much everything
function update(dt)
	dildoReplacement()
	fleshlightReplacement()
	tentacleplantReplacement()
end

function dildoReplacement()
	if player.hasItem("sexbound_dildo") then
		player.consumeItem("sexbound_dildo")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_black") then
		player.consumeItem("sexbound_dildo_black")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_blue") then
		player.consumeItem("sexbound_dildo_blue")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_green") then
		player.consumeItem("sexbound_dildo_green")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_grey") then
		player.consumeItem("sexbound_dildo_grey")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_orange") then
		player.consumeItem("sexbound_dildo_orange")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_pink") then
		player.consumeItem("sexbound_dildo_pink")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_purple") then
		player.consumeItem("sexbound_dildo_purple")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_red") then
		player.consumeItem("sexbound_dildo_red")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_white") then
		player.consumeItem("sexbound_dildo_white")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_yellow") then
		player.consumeItem("sexbound_dildo_yellow")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_skin1") then
		player.consumeItem("sexbound_dildo_skin1")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_skin2") then
		player.consumeItem("sexbound_dildo_skin2")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_skin3") then
		player.consumeItem("sexbound_dildo_skin3")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_skin4") then
		player.consumeItem("sexbound_dildo_skin4")
		player.giveItem("sexbound_dildo_v2")
	elseif player.hasItem("sexbound_dildo_skin5") then
		player.consumeItem("sexbound_dildo_skin5")
		player.giveItem("sexbound_dildo_v2")
	end
end

function fleshlightReplacement()
	if player.hasItem("sexbound_fleshlight") then
		player.consumeItem("sexbound_fleshlight")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_black") then
		player.consumeItem("sexbound_fleshlight_black")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_blue") then
		player.consumeItem("sexbound_fleshlight_blue")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_green") then
		player.consumeItem("sexbound_fleshlight_green")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_grey") then
		player.consumeItem("sexbound_fleshlight_grey")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_orange") then
		player.consumeItem("sexbound_fleshlight_orange")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_pink") then
		player.consumeItem("sexbound_fleshlight_pink")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_purple") then
		player.consumeItem("sexbound_fleshlight_purple")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_red") then
		player.consumeItem("sexbound_fleshlight_red")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_white") then
		player.consumeItem("sexbound_fleshlight_white")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_yellow") then
		player.consumeItem("sexbound_fleshlight_yellow")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_skin1") then
		player.consumeItem("sexbound_fleshlight_skin1")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_skin2") then
		player.consumeItem("sexbound_fleshlight_skin2")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_skin3") then
		player.consumeItem("sexbound_fleshlight_skin3")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_skin4") then
		player.consumeItem("sexbound_fleshlight_skin4")
		player.giveItem("sexbound_fleshlight_v2")
	elseif player.hasItem("sexbound_fleshlight_skin5") then
		player.consumeItem("sexbound_fleshlight_skin5")
		player.giveItem("sexbound_fleshlight_v2")
	end
end

function tentacleplantReplacement()
	if player.hasItem("sexbound_tentacleplant") then
		player.consumeItem("sexbound_tentacleplant")
		player.giveItem("sexbound_tentacleplant_v2")
	elseif player.hasItem("sexbound_tentacleplant_1") then
		player.consumeItem("sexbound_tentacleplant_1")
		player.giveItem("sexbound_tentacleplant_v2")
	elseif player.hasItem("sexbound_tentacleplant_2") then
		player.consumeItem("sexbound_tentacleplant_2")
		player.giveItem("sexbound_tentacleplant_v2")
	elseif player.hasItem("sexbound_tentacleplant_3") then
		player.consumeItem("sexbound_tentacleplant_3")
		player.giveItem("sexbound_tentacleplant_v2")
	elseif player.hasItem("sexbound_tentacleplant_4") then
		player.consumeItem("sexbound_tentacleplant_4")
		player.giveItem("sexbound_tentacleplant_v2")
	elseif player.hasItem("sexbound_tentacleplant_5") then
		player.consumeItem("sexbound_tentacleplant_5")
		player.giveItem("sexbound_tentacleplant_v2")
	elseif player.hasItem("sexbound_tentacleplant_6") then
		player.consumeItem("sexbound_tentacleplant_6")
		player.giveItem("sexbound_tentacleplant_v2")
	elseif player.hasItem("sexbound_tentacleplant_7") then
		player.consumeItem("sexbound_tentacleplant_7")
		player.giveItem("sexbound_tentacleplant_v2")
	elseif player.hasItem("sexbound_tentacleplant_8") then
		player.consumeItem("sexbound_tentacleplant_8")
		player.giveItem("sexbound_tentacleplant_v2")
	elseif player.hasItem("sexbound_tentacleplant_9") then
		player.consumeItem("sexbound_tentacleplant_9")
		player.giveItem("sexbound_tentacleplant_v2")
	end
end