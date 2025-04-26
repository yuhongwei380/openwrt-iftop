include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-iftop
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Your Name <your@email.com>
PKG_LICENSE:=GPL-2.0
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-iftop
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI Interface for iftop Traffic Monitoring
  PKGARCH:=all
  DEPENDS:=+luci-base +iftop +python3-base +sqlite3
endef

define Package/luci-app-iftop/description
  LuCI interface for iftop traffic monitoring with IP/domain statistics and historical data.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-iftop/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./usr/lib/lua/luci/* $(1)/usr/lib/lua/luci/
	
	$(INSTALL_DIR) $(1)/usr/share/iftop-collector
	$(INSTALL_BIN) ./usr/share/iftop-collector/collector.py $(1)/usr/share/iftop-collector/
	
	$(INSTALL_DIR) $(1)/usr/share/iftop-data
	touch $(1)/usr/share/iftop-data/traffic.db
	
	$(INSTALL_DIR) $(1)/etc/crontabs
	echo '*/5 * * * * python3 /usr/share/iftop-collector/collector.py' > $(1)/etc/crontabs/root
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/iftop-collector.init $(1)/etc/init.d/iftop-collector
endef

$(eval $(call BuildPackage,luci-app-iftop))
