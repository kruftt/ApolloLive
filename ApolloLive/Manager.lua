local log = ApolloLive.Log
local Connection = ApolloLive.Connection
local interval = ApolloLive.Config.PollInterval

ModUtil.WrapBaseFunction("AddTraitToHero", function ( baseFunc, args)
  log('AddTraitToHero')
  baseFunc(args)
  ApolloLive.Update()
end, ApolloLive)

ModUtil.WrapBaseFunction("RemoveTraitData", function ( baseFunc, unit, trait, args)
  log('RemoveTraitData')
  baseFunc(unit, trait, args)
  if unit == CurrentRun.Hero then
    ApolloLive.Update()
  end
end, ApolloLive)

OnAnyLoad{ ApolloLive.Update }

local monitorConnection = function ()
  while true do
    wait(interval)
    if Connection.Status == 'closed' then
      Connection.Open()
    elseif Connection.Status == 'open' then
      Connection.Pong()
    else
      log(string.format('connection %s during update.', Connection.Status))
    end
  end
end

thread(monitorConnection)


OnMouseOver{ "BoonSlot1 BoonSlot2 BoonSlot3",
  function (triggerArgs)
    log('BoonSlot mouseover')
    if triggerArgs.triggeredById == nil or ApolloLive.Connection.Status ~= 'open' then return end

    if ScreenAnchors.ChoiceScreen and IsScreenOpen("BoonMenu") then
      -- Boon Menu
      local key = ScreenAnchors.ChoiceScreen.Components[ triggerArgs.triggeredById ]
      local component = ScreenAnchors.ChoiceScreen.Components[key]
      local cd = component.Data

      if cd then
        if component.Type == 'Trait' then
          local ld = component.LootData
          local count = (ld and ld.StackNum) or 1
          ApolloLive.Update(cd, count)

        elseif component.Type == 'TransformingTrait' then
          local name = cd.Name -- or cd.Title or cd.name
          if name:match('ChaosCurse(.+)') and cd.OnExpire then
            ApolloLive.Update(cd.OnExpire.TraitData)
          end
        end
      end

    else
      -- Store if couldn't find ChoiceScreen
      local Store = CurrentRun.CurrentRoom.Store
      if Store then
        local previewTrait = nil
        local Buttons = Store.Buttons
        for i,Button in ipairs(Buttons) do
          if Button.Id == triggerArgs.triggeredById then
            previewTrait = Button.Data
          end
        end
        if previewTrait then ApolloLive.Update(previewTrait) end
      end
    end
  end
}

OnMouseOver{ "SellSlot1 SellSlot2 SellSlot3",
  function( triggerArgs )
    log('SellSlot mouseover')
    if triggerArgs.triggeredById == nil or ApolloLive.Connection.Status ~= 'open' or not IsScreenOpen("SellTraitMenu") then return end
    local screen = ScreenAnchors.SellTraitScreen
    if not screen then return end
    local key = screen.Components[ triggerArgs.triggeredById ]
    local component = screen.Components[key]
    ApolloLive.Update(component.UpgradeName, nil, true)
	end
}

OnMouseOff{ "BoonSlot1 BoonSlot2 BoonSlot3 SellSlot1 SellSlot2 SellSlot3",
  function( triggerArgs )
    if ApolloLive.Connection.Status == 'open' then
      ApolloLive.Update()
    end
  end
}

log('loaded Manager.lua')
