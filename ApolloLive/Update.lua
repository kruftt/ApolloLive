local log = ApolloLive.Log

local chaosIndex = 1
local extractTrait = function (Trait, traitMap)
  local name = Trait.Name or Trait.Title or Trait.name -- Jerky has no name
  local title = name:match('(.+)_Initial')
  if not title then
    title = name
  end

  -- log('Extracting Trait: '..title)

  if title:match('Chaos(.+)') then
    title = title..chaosIndex
    chaosIndex = chaosIndex + 1
  end

  local entry = traitMap[title]
  if entry then
    local level = entry.level
    if level then entry.level = level + 1 else entry.level = 2 end
  else
    local data = { title = title, rarity = Trait.Rarity }
    traitMap[title] = data
    return data
  end
end

ApolloLive.Update = function (preview, stacks, sell)
  if not CurrentRun or ApolloLive.Connection.Status ~= 'open' then return end
  local Hero = CurrentRun.Hero
  local HeroTraits = Hero.Traits
  local MetaUpgradeCache = CurrentRun.MetaUpgradeCache
  if not Hero or not HeroTraits or not MetaUpgradeCache then return end
  log('Extracting Build Info')
  local mirror = {}
  local traits = {}
  local run_data = {
    money = CurrentRun.Money,
    health = Hero.Health,
    maxHealth = Hero.MaxHealth,
    mirror = mirror,
    traits = traits,
  }

  log('initialized vars')

  for name, value in pairs(MetaUpgradeCache) do
    name = name:match('(.+)MetaUpgrade')
    if name then mirror[name] = value end
  end

  log('extracted mirror')

  chaosIndex = 1
  local i = 0
  local extracted = nil
  local traitMap = {}
  local indexMap = {}
  for k, Trait in pairs(HeroTraits) do
    extracted = extractTrait(Trait, traitMap)
    if extracted then
      traits[i] = extracted
      indexMap[extracted.title] = i
      i = i + 1
    end
  end

  -- if preview.name:match('Death(.+)') then return end
  if i == 0 then return end

  if preview then
    if sell then
      table.remove(traits, indexMap[preview])
    else
      for j=1,(stacks or 1),1 do
        extracted = extractTrait(preview, traitMap)
        if extracted then
          traits[i] = extracted
          i = i + 1
        end
      end
    end
  end

  log('extracted traits')
  log(TableToJSONString(run_data))
  ApolloLive.Connection.Send(TableToJSONString({
    type = 'apollo',
    payload = run_data,
  }))
end

log("loaded Update.lua")
