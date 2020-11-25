local Config = {
  PollInterval = 1,
  Debug = false,
}

ModUtil.RegisterMod("ApolloLive")
ApolloLive.Config = Config
local path = package.path
local cpath = package.cpath
package.path = "..\\Content\\Mods\\ApolloLive\\lua\\?.lua;" .. package.path
package.cpath = "..\\Content\\Mods\\ApolloLive\\clibs\\?.dll;" .. package.cpath
ApolloLive.Libs = {
  bit = require'bit',
  mime = require'mime',
  socket = require'socket',
}
package.path = path
package.cpath = cpath

ApolloLive.Log = function (...)
  if ApolloLive.Config.Debug then
    print('ApolloLive:', ...)
  end
end

ApolloLive.Log('loaded Config.lua')
