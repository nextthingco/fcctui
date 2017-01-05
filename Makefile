DESTDIR?=.

INSTALL=install

SRC_SCRIPTS=$(wildcard src/*)
SRC_MOCKS=$(filter-out test/mock/noop, $(wildcard test/mock/*))

KCONFIG_BUILD=kconfig/build
KCONFIG_TOOLS=conf mconf
KCONFIG_INPUTS=$(shell find conf)

EM_CONFIG_DIR=em_config

all: $(addprefix $(KCONFIG_BUILD)/,$(KCONFIG_TOOLS))
	echo Done

vendor-binaries: vendor/rtlbtmp
	$(foreach binary,$?, \
		$(shell $(INSTALL) -D -m 0755 $(binary) $(DESTDIR)/bin/$(notdir $(binary))) \
	)

vendor-firmwares: vendor/mp_rtl8723d_fw vendor/mp_rtl8723d_config
	$(foreach firmware,$?, \
		$(shell $(INSTALL) -D -m 0644 $(firmware) $(DESTDIR)/lib/firmware/$(notdir $(firmware))) \
	)

install-vendor: vendor-binaries vendor-firmwares

install: install-scripts install-vendor install-kconfig $(addprefix install-kconfig-, $(KCONFIG_TOOLS))

install-scripts: $(SRC_SCRIPTS)
	$(foreach script,$(SRC_SCRIPTS), \
		$(shell $(INSTALL) -D -m 0755 $(script) $(DESTDIR)/bin/$(notdir $(script))) \
	)

mock-preinstall: install
	rm $(DESTDIR)/bin/rtlbtmp

mock: mock-preinstall $(SRC_MOCKS)
	$(foreach mock,$(SRC_MOCKS), \
		$(shell $(INSTALL) -D -m 0755 $(mock) $(DESTDIR)/bin/$(notdir $(mock))) \
	)
	$(INSTALL) -D -m 0755 test/mock/noop $(DESTDIR)/bin/fcc_start
	$(INSTALL) -D -m 0755 test/mock/noop $(DESTDIR)/bin/set_antenna
	$(INSTALL) -D -m 0755 test/mock/noop $(DESTDIR)/bin/w_start
	$(INSTALL) -D -m 0755 test/mock/noop $(DESTDIR)/bin/w_stop
	$(INSTALL) -D -m 0755 test/mock/noop $(DESTDIR)/bin/w
	$(INSTALL) -D -m 0755 test/mock/noop $(DESTDIR)/bin/iwpriv
	$(INSTALL) -D -m 0755 test/mock/noop $(DESTDIR)/bin/bt_reset
	$(INSTALL) -D -m 0755 test/mock/noop $(DESTDIR)/bin/ifconfig
	$(INSTALL) -D -m 0755 test/mock/noop $(DESTDIR)/bin/modprobe

mock-interactive: mock
	EM_CONFIG_DIR=$(DESTDIR)/$(EM_CONFIG_DIR) \
		STATUS_LED=$(STATUS_LED) \
		PATH=$(DESTDIR)/bin:$(PATH) bash

$(KCONFIG_BUILD)/%:
	mkdir -p $(KCONFIG_BUILD)/lxdialog
	$(MAKE) HOSTCC="$(CC)" PKG_CONFIG="$(PKG_CONFIG)" obj=build -C kconfig -f Makefile.br $*

install-kconfig-%: $(KCONFIG_BUILD)/%
	$(INSTALL) -D -m 0755 $< $(DESTDIR)/bin/$*

install-kconfig: $(KCONFIG_INPUTS)
	$(foreach conf,$?, \
		$(shell $(INSTALL) -D -m 0644 $(conf) $(DESTDIR)/$(EM_CONFIG_DIR)/$(conf)) \
	)
