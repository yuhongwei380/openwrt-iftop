include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI: Iftop Plus Traffic Monitor
LUCI_DEPENDS:=+luci-base +luci-lib-nixio +luci-lib-jsonc +sqlite3-cli +iftop +bash
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-iftop-plus
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || /etc/init.d/iftopd enable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
