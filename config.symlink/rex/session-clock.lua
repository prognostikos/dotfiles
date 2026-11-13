-- Prefix every session label with the local time, including new sessions.
-- Run through the com.rohrer.rex-session-clock LaunchAgent.
while true do
  local result, err = rex.call("session.list")
  assert(result, err)
  local prefix = os.date("%H:%M") .. " "
  for _, session in ipairs(result.sessions) do
    -- Read the current name each time so manual renames are preserved.
    local name = session.label:gsub("^%d%d:%d%d ", "", 1)
    local label = prefix .. name
    if session.label ~= label then
      local attached, attach_err = rex.session.attach{ session_id = session.session_id }
      assert(attached, attach_err)
      local updated, update_err = rex.session.set_label{
        session_id = session.session_id,
        label = label,
      }
      assert(updated, update_err)
    end
  end
  -- Check each second so minute changes and newly created sessions appear promptly.
  rex.sleep(1)
end
