-- Copyright 2008 Yanira <forum-2008@email.de>
-- Copyright 2012 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

require("luci.sys")
local apply = luci.http.formvalue ("cbi.apply")
local m, s

s = Map("mac-todong", translate("<p><strong>Lock Mac-Address"), translate("Ubah Interfaces Modem"))
m = s:section(TypedSection)
m.anonymous = true
m.addremove = false
enable = m:option(Flag, "enabled", translate("Aktifkan"), translate ("Aktifkan Todong"))
enable.value = 1
enable.value = 0
enable.default = 0
token = m:option(Value, "eth1", translate("eth1"), translate(""))
token.password = false
chatid = m:option(Value, "eth2", translate("eth2"), translate(""))
--timeout = m:option(Value, "", translate(""), translate(""))
--ptime = m:option(Value, "", translate(""), translate (""))
--plugins = m:option(Value, "plugins", translate("Plugins"), translate("Path to plugins directory."))
--hlog = m:option(Value, "log_file", translate("Log File"), translate ("Path to Logfile"))
--hlog.default = '/tmp/mac-todong.log'

if apply then
        local enabled = "/etc/init.d/todong enabled"
        luci.sys.exec(enabled)
end

return s
