module("luci.controller.mac-todong", package.seeall)

function index()
        if not nixio.fs.access("/etc/config/mac-todong") then
                return
        end
        entry({"admin", "control", "mac-todong"}, cbi("mac-todong"), _("MAC Todong"), 82).acl_depends={"unauthenticated"}
end
