local customer = customer or false
local cart = cart or {}
local deposited = deposited or 0
local lastaction = lastaction or false
local last_f4 = last_f4 or false
local last_money_drop = CurTime()

local singles = {}
local shipments = {}

local gun_ents = {}
local gun_names = {}

local que = {}
local said = {}
local last = CurTime() + 2
local quenum = 1
local saidnum = 1
local cango = true
local word_wls = {}
local word_wl = {}

local singles_pages = {}
singles_pages[1] = ""
local shipments_pages = {}
shipments_pages[1] = ""

local multiplier = 1.3

local function CustomerLeft()
	customer = false
	cart = false
	deposited = 0
	lastaction = false
	
	que = {}
	quenum = 1
	saidnum = 0
end

local function SortTable(t)
	local temp = {}
	local tempC = 1
	if t[1] == nil and #t >= 2 then
		for i=0, #t do
			if t[i] != nil and t[i] then
				temp[tempC] = t[i]
				print(t[i] .. "0_o")
				tempC = tempC + 1
			end
		end
	end
	if #temp >= 1 then
		return temp
	else
		return {}
	end
end

local function ChatSpamDelay(s)

	if s != nil and s then
		// Whitelist! This is mostly for self debugging
		if table.HasValue(word_wls, s) then
			que[quenum] = s
			quenum = quenum + 1
		end
	end
	
	if cango and que != nil then
	
		cango = false
		local s = que[1]
		LocalPlayer():ConCommand(s)

		timer.Simple( 2, function()
			cango = true
			if que[1] != nil and said[1] != nil then
				if said[1] == que[1] then
					// We said it! Yeah!
					que[1] = nil
					said[1] = nil
					quenum = quenum - 1
					saidnum = saidnum - 1
					que = SortTable(que)
					said = SortTable(said)
					if que[1] != nil and said[1] == nil then
						ChatSpamDelay(false)
					end
--					print("inif")
				else
					// Try again...
					if que[1] != nil and said[1] == nil then
						ChatSpamDelay(false)
--						print("outif")
					end
				end
			else
				// Try again...
				if que[1] != nil and said[1] == nil then
					ChatSpamDelay(false)
--					print("waiting")
				end
			end
		end)

	end
end

local function ConsoleChatPrint(s)
	if string.Left(s, 3) == "say" then
		if !table.HasValue(word_wls, s) then
			table.insert(word_wls, s)
			table.insert(word_wl, string.Right(s, #s-4))
		end
		ChatSpamDelay(s)
	else
		print(s)
		LocalPlayer():ConCommand(s)
		print(#s)
	end
end

concommand.Add("spam_test", function()
	for i=0, 100 do
		ConsoleChatPrint("say testing " .. i )
	end
end)

timer.Create( "Check_for_money", 0.5, 0, function()
	if customer then
		if CurTime() - last_money_drop > 5 then
			for k, v in ipairs(ents.FindByClass("spawned_money")) do
				if LocalPlayer():GetPos():Distance( v:GetPos() ) < 64 then
					local targetheadpos = v:GetPos()
					LocalPlayer():SetEyeAngles((targetheadpos - LocalPlayer():GetShootPos()):Angle())
					RunConsoleCommand("+use")
					timer.Simple(0.01, function() RunConsoleCommand("-use") end)
				end
			end
		end
	
		// Check distance
		if LocalPlayer():GetPos():Distance( customer:GetPos() ) > 500 then
			ConsoleChatPrint('say My customer has abandoned me!')
			ConsoleChatPrint('ulx psay "' .. tostring(customer:Nick()) .. '" Bye! (you have walked too far away)' )
			CustomerLeft()
			return
		end
		
		// Check valid
		if !IsValid(customer) then
			ConsoleChatPrint('say My customer has left the game!')
			CustomerLeft()
			return
		end
		
		// Check alive
		if !customer:Alive() then
			ConsoleChatPrint('say My customer has died!')
			ConsoleChatPrint('ulx psay "' .. tostring(customer:Nick()) .. '" Shopping session ended. You died!' )
			CustomerLeft()
			return
		end
		
	end
	
end)

timer.Create("Customers_where", 20, 0, function()
	if customer and lastaction and CurTime() - lastaction > 60 then
		ConsoleChatPrint("say " .. customer:Nick() .. "'s Shopping session timed out " )
		CustomerLeft()
	end
end)

timer.Create("Dealer_Advert", 90, 0, function()
	if !customer then
		LocalPlayer():ConCommand('say Would anyone like to buy a gun? Type !help for the commands - !tutorial for a tutorial' )
	end	
end)	

local function CheckPlayer(ply, prefixText)
	if prefixText != ply:Nick() then ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" You have to come up to me to use the command!' ) return false end
	if customer and ply != customer then ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" Sorry, I am taking orders from ' .. customer:Nick() .. ' right now.' ) return false end
	return true
end

hook.Add("OnPlayerChat", "cl_eventsystem", function( ply, strText, bTeamOnly, bPlayerIsDead, prefixText )
--	print(prefixText)
	
	if customer and ply == LocalPlayer() then
		if table.HasValue(word_wl, strText) then
			said[saidnum] = "say " .. strText
			saidnum = saidnum + 1
		end
	end
	strText = string.lower( strText )
--	if string.Left(strText,1) == "!" then
	if ( strText == "!start" ) then
		if !CheckPlayer(ply, prefixText) then return end
		ConsoleChatPrint('say Thank you ' .. tostring(ply:Nick()) .. ' for starting a shopping session! Do not forget to type !help if you forget the commands!' )
		customer = ply
		lastaction = CurTime()
	end
	if ( strText == "!deposited" or strText == "!balance" ) then
		if !CheckPlayer(ply, prefixText) then return end
		if !customer then ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" You need to first start the shopping session with !shop') return end
		if deposited then
			ConsoleChatPrint('say You have deposited ' .. DarkRP.formatMoney(deposited) )
		else
			ConsoleChatPrint('say You have deposited $0')
		end
		lastaction = CurTime()
	end
	if ( strText == "!withdraw" ) then
		if !CheckPlayer(ply, prefixText) then return end
		if !customer then ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" You need to first start the shopping session with !shop') return end
		if deposited then
			print(deposited)
			if deposited > 1 then
				local targetheadpos = customer:GetPos() + Vector(0,0,66)
				LocalPlayer():SetEyeAngles((targetheadpos - LocalPlayer():GetShootPos()):Angle()) 
				last_money_drop = CurTime()
				ConsoleChatPrint('say /dropmoney ' .. deposited )
				ConsoleChatPrint('say You withdrew ' .. DarkRP.formatMoney(deposited) )
				deposited = 0
			else
				ConsoleChatPrint('say Not enough money to withdraw!')
			end
		else
			ConsoleChatPrint('say No money to withdraw!')
		end
		lastaction = CurTime()
	end
	if #strText >= 8 and string.Left(strText,8) == "!singles" then
		if !CheckPlayer(ply, prefixText) then return end
		if !customer then ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" You need to first start the shopping session with !shop') return end
		if #singles == 0 then ConsoleChatPrint("say No singles found in the database! (Make sure to set yourself to Gun Dealer " .. LocalPlayer():Nick() .. ")") return end
		local words = string.Explode( " ", strText )
		local num = tonumber(words[2])
		if singles_pages[num] then
			ConsoleChatPrint('say ' .. singles_pages[num] .. "(" .. num .. "/" .. #singles_pages .. ")"  )
		else
			print(num)
			ConsoleChatPrint('say Page not found!' )
		end
		lastaction = CurTime()
	end
	if #strText >= 10 and string.Left(strText,10) == "!shipments" then
		if !CheckPlayer(ply, prefixText) then return end
		if !customer then ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" You need to first start the shopping session with !shop') return end
		if #shipments == 0 then ConsoleChatPrint("say No shipments found in the database! (Make sure to set yourself to Gun Dealer " .. LocalPlayer():Nick() .. ")") return end
		local words = string.Explode( " ", strText )
		local num = tonumber(words[2])
		if shipments_pages[num] then
			ConsoleChatPrint('say ' .. shipments_pages[num] .. "(" .. num .. "/" .. #shipments_pages .. ")"  )
		else
			print(num)
			ConsoleChatPrint('say Page not found!' )
		end
		lastaction = CurTime()
	end
	if #strText >= 10 and string.Left(strText,10) == "!buysingle" then
		if !CheckPlayer(ply, prefixText) then return end
		if !customer then ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" You need to first start the shopping session with !start') return end
		if #singles == 0 then ConsoleChatPrint("say No singles found in the database! (Make sure to set yourself to Gun Dealer " .. LocalPlayer():Nick() .. ")") return end
		local ent = false
		local check = string.Trim(string.lower(string.TrimLeft(strText, "!buysingle ")))
		for k, v in ipairs(gun_names) do
			if v == check then
				check = gun_ents[k]
				break
			end
		end
		if table.HasValue(gun_ents, check) then
			for k, v in ipairs(singles) do
				if v.entity == check or v.name == check then // name of shipment
					ent = v
					break
				end
			end
			if ent then
				if deposited >= ent.pricesep*multiplier then
					deposited = deposited - ent.pricesep*multiplier
					local targetheadpos = customer:GetPos() + Vector(0,0,66)
					LocalPlayer():SetEyeAngles((targetheadpos - LocalPlayer():GetShootPos()):Angle()) 
					ConsoleChatPrint("DarkRP " .. "buy " .. ent.name)
					ConsoleChatPrint('say You have bought a ' .. ent.name .. ' for ' .. DarkRP.formatMoney(ent.pricesep*multiplier) .. '. Your balance is now ' .. DarkRP.formatMoney(deposited) )
				else
					ConsoleChatPrint('say You do not have enough money deposited to buy a ' .. ent.name .. ' You need ' .. DarkRP.formatMoney(ent.pricesep*multiplier - deposited) .. ' more!')
				end
			else
				ConsoleChatPrint('say ' .. check .. ' is not for sale!' )
	--			ConsoleChatPrint(tostring('say Entity not found! Make sure the format is right --> !buysingle (entity or name) --> !buysingle fas2_m24 or !buysingle M24'))
			end
		else
			ConsoleChatPrint('say Entity not found! Make sure the format is right --> !buysingle (entity) --> !buysingle fas2_m24')
		end
		lastaction = CurTime()
	end
	if #strText >= 12 and string.Left(strText,12) == "!buyshipment" then
		if !CheckPlayer(ply, prefixText) then return end
		if !customer then ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" You need to first start the shopping session with !start') return end
		if #shipments == 0 then ConsoleChatPrint("say No shipments found in the database! (Make sure to set yourself to Gun Dealer " .. LocalPlayer():Nick() .. ")") return end
		local ent = false
		local check = string.Trim(string.lower(string.TrimLeft(strText, "!buyshipment ")))
		for k, v in ipairs(gun_names) do
			if v == check then
				check = gun_ents[k]
				break
			end
		end
		if table.HasValue(gun_ents, check) then
			for k, v in ipairs(shipments) do
				if v.entity == check or v.name == check then // name of shipment
					ent = v
					break
				end
			end
			if ent then
				if deposited >= ent.price*multiplier then
					deposited = deposited - ent.price*multiplier
					local targetheadpos = customer:GetPos() + Vector(0,0,66)
					LocalPlayer():SetEyeAngles((targetheadpos - LocalPlayer():GetShootPos()):Angle()) 
					ConsoleChatPrint("DarkRP " .. "buyshipment " .. ent.name)
					ConsoleChatPrint('say You have bought a ' .. ent.name .. ' for ' .. DarkRP.formatMoney(ent.price*multiplier) .. '. Your balance is now ' .. DarkRP.formatMoney(deposited) )
				else
					ConsoleChatPrint('say You do not have enough money deposited to buy a ' .. ent.name .. ' You need ' .. DarkRP.formatMoney(ent.price*multiplier - deposited) .. ' more!')
				end
			else
				ConsoleChatPrint('say ' .. check .. ' is not for sale!' )
			end
		else
			ConsoleChatPrint('say Entity not found! Make sure the format is right --> !buyshipment (entity) --> !buyshipment fas2_m24')
		end
		lastaction = CurTime()
	end
	if ( strText == "!help" ) then
		if !CheckPlayer(ply, prefixText) then return end
		ConsoleChatPrint('say [COMMANDS] !help !tutorial !start !deposited/!balance !withdraw !singles !shipments !buysingle !buyshipment !stop' )
		lastaction = CurTime()
	end
	if ( strText == "!stop" ) then
		if !CheckPlayer(ply, prefixText) then return end
		if customer then
			ConsoleChatPrint('say Bye, see you again soon ' .. tostring(ply:Nick()) .. '!' )
			CustomerLeft()
		end
	end
	if ( strText == "!tutorial" ) then
		if !CheckPlayer(ply, prefixText) then return end
		ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" Start a shopping session with !start - Look at the prices of singles with !singles 1 - /dropmoney to deposit' )
		ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" !deposited or !balance to check your balance - !buysingle ent_name to buy the single! - !withdraw to get your money out' )
		ConsoleChatPrint('ulx psay "' .. tostring(ply:Nick()) .. '" !stop to end your shopping session (this also wipes your balance). If you forget the commands you can type !help' )
		lastaction = CurTime()
	end
--	end
end)

function GAMEMODE:AddNotify( str, type, length )
	
	notification.AddLegacy( str, type, length )
	if string.Left( str, 14 ) == "You have found" then // You have found $5!
		if customer then
			local money1 = string.TrimLeft(str, string.Left( str, 16 ))
			local money2 = string.TrimRight(money1, "!")
--			print(money2)
			local money3 = ""
			for i=0, #money2 do
				if money2[i] != "," then
					money3 = money3 .. money2[i]
				end
			end
			deposited = tonumber(deposited)
			money3 = tonumber(money3)
			ConsoleChatPrint('say Your balance was ' .. DarkRP.formatMoney(deposited) .. ' and you have deposited ' .. DarkRP.formatMoney(money3) .. ' so your balance is now ' .. DarkRP.formatMoney(deposited + money3) )
			deposited = deposited + money3
			print(deposited)
		end
	end
		
end

for k, v in pairs(CustomShipments) do
	if v.seperate == true then
		if v.allowed then
			if !GAMEMODE.Config.restrictbuypistol or table.HasValue(v.allowed, LocalPlayer():Team()) then
				if v.customCheck then
					if v.customCheck(LocalPlayer()) then
						// are allowed
						table.insert(singles, v)
						print(v)
					end
				else
					// are allowed
					table.insert(singles, v)
					print(v)
				end
			end
		else
			// are allowed
			table.insert(singles, v)
			print(v)
		end
	else
		if v.allowed then
			if table.HasValue(v.allowed, LocalPlayer():Team()) then
				if v.customCheck then
					if v.customCheck(LocalPlayer()) then
						// are allowed
						table.insert(shipments, v)
--						print(v)
					end
				else
					// are allowed
					table.insert(shipments, v)
--					print(v)
				end
			end
		else
			// are allowed
			table.insert(shipments, v)
--			print(v)
		end
	end
end

// Now workout how many pages of guns there will be! -- 127 character cap!
local function PagesOfSingles()
	local temp_s = ""
	local page_n = 1
	for k, v in ipairs(singles) do
		local next_s = v.entity .. " " .. DarkRP.formatMoney(v.pricesep*multiplier) .. ", "
		if #singles_pages[page_n] + #next_s > 120 then //115 //110 // I took 7 //127
			// Add to the next page
			page_n = page_n + 1
			singles_pages[page_n] = next_s
		else	
			// Add to the current page
			singles_pages[page_n] = singles_pages[page_n] .. next_s
		end
	end
end
PagesOfSingles()

for k, v in ipairs(singles_pages) do
	print(v.."\n")
end

local function PagesOfShipments()
	local temp_s = ""
	local page_n = 1
	for k, v in ipairs(shipments) do
		local next_s = v.entity .. " " .. DarkRP.formatMoney(v.price*multiplier) .. ", "
		if #shipments_pages[page_n] + #next_s > 120 then //115 //110 // I took 7 //127
			// Add to the next page
			page_n = page_n + 1
			shipments_pages[page_n] = next_s
		else	
			// Add to the current page
			shipments_pages[page_n] = shipments_pages[page_n] .. next_s
		end
	end
end
PagesOfShipments()

print("---------- Shipments ------------\n")
for k, v in ipairs(shipments_pages) do
	print(v.."\n")
end

for k, v in ipairs(weapons.GetList()) do
	if v.ClassName then
		table.insert(gun_ents, v.ClassName)
		table.insert(gun_names, string.lower(tostring(v.PrintName)))
	end
end

