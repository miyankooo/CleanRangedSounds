local addonName, ns = ...

-- Outside its settings the addon shows nothing, so its first load on an account points there once, with a link
-- that opens them. The line waits for login, when the client's own load lines are already in chat and the
-- settings page exists.

-- Blizzard reserves the addon link type for addons and hands every click on one to all of them through the
-- EventRegistry event SetItemRef (Shared/ItemRefHandlersShared.lua). Gold is the colour of Blizzard's own action
-- links in chat, such as club invites (Mainline/ItemRef.lua).
local LINK = LinkTypes.AddOn .. ":" .. addonName

local function SurfaceLink(label)
  return NORMAL_FONT_COLOR:WrapTextInColorCode(LinkUtil.FormatLink(LinkTypes.AddOn, "[" .. label .. "]", addonName))
end

function ns.PrintWelcome()
  ns.Print("Mutes the bow creak before each shot and any other bow, crossbow or gun sound you pick. Open the "
    .. SurfaceLink(SETTINGS) .. " or type /crs to choose which sounds play.")
end

-- /crs intro: the welcome line now, and the help tip again the next time its row shows.
function ns.ReplayIntro()
  ns.db.tipSeen = nil
  ns.PrintWelcome()
end

-- Another addon's link may come from a line kept from restricted content, so it is checked before the comparison.
EventRegistry:RegisterCallback("SetItemRef", function(_, link)
  if ns.CanAccess(link) and link == LINK then ns.OpenSettings() end
end, ns)

EventUtil.ContinueOnPlayerLogin(function()
  if ns.firstRun then ns.PrintWelcome() end
end)
