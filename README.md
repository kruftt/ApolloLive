# ApolloLive

This Hades plugin provides live integration with the [Apollo trait calculator](https://kruftt.github.io/Apollo/), as well as a browser logging tool for use by other mod developers.
&nbsp;
### Dependencies
- [Mod Importer](https://www.nexusmods.com/hades/mods/26)
- [Mod Utility](https://www.nexusmods.com/hades/mods/27)

&nbsp;
### Installation
Warning! Backup save files before using.
1. Copy the `ApolloLive` mod directory to `...\Steam\steamapps\common\Hades\Content\Mods` or equivalent.
1. Run the Hades `Mod Importer`.
1. Open the [Apollo trait calculator](https://kruftt.github.io/Apollo/).
1. Click the connection status bar to scan for a connection.
1. Launch the x86 executable at `...\Steam\steamapps\common\Hades\x86\Hades.exe` or equivalent.
1. Load a save file and start a run.

&nbsp;

&nbsp;
## ApolloLive.Send

ApolloLive provides the Send function for use by other modders in exploration and debugging.  After installing ApolloLive, other mods may send messages to the Apollo app running in the web browser.  By default, a connected ApolloLive logs any such messages to the console:

&nbsp;

MyMod.lua
```lua
ApolloLive.Send('Hello World')
```
Browser Console:
```
> ApolloLive: Hello World
```
&nbsp;

Messages can also be lua tables, which will be converted to json objects, transmitted, and displayed as javascript objects in the browser console:

MyMod.lua
```lua
ApolloLive.Send(CurrentRun.Hero)
```
Browser Console:
![apollo_console](https://user-images.githubusercontent.com/3959391/100295715-1c596d80-2f3f-11eb-8773-d37881cf391b.JPG)

This can be used to explore the structure of ingame data objects.

&nbsp;

If you would like to overwrite the default event handler for messages passed to `ApolloLive.Send`, simply pass a new function handler to `ApolloLive.setListener` in the browser console:
```js
function handler(msg) {
  console.log('received a message', msg)
}

ApolloLive.setListener(handler)


> received a message    Hello World
```