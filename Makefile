VERSION=$(shell grep '^Version' ChangeLog | head -n 1 | cut -d' ' -f2 | tr -d ' ')
BIN=sysrqd
O=sysrqd.o
CFLAGS+=-W -Wall -Wextra \
        -Wundef -Wshadow -Wcast-align -Wwrite-strings -Wsign-compare \
        -Wunused -Winit-self -Wpointer-arith -Wredundant-decls \
        -Wmissing-prototypes -Wmissing-format-attribute -Wmissing-noreturn \
        -std=gnu99 -pipe -DSYSRQD_VERSION="\"$(VERSION)\"" -O3
LDFLAGS+=-lcrypt

SBINDIR=$(DESTDIR)/usr/sbin
INSTALL = install

$(BIN): $(O)
	$(CC) -o $(BIN) $(O) $(LDFLAGS)

$(BIN).secret:
	@if [ ! -s "$@" ]; then \
		head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 > $@; \
		echo "Generated random password in $@"; \
	fi

install: $(BIN) $(BIN).secret
	$(INSTALL) -d -m 755 $(SBINDIR)
	$(INSTALL) -m 755 $(BIN) $(SBINDIR)
	$(INSTALL) -m 644 $(BIN).service /etc/systemd/system/
	test -f /etc/$(BIN).secret || $(INSTALL) -m 600 $(BIN).secret /etc/
	systemctl enable --now $(BIN)

clean:
	rm -f *~ $(O) $(BIN) $(BIN).secret

release: clean
	mkdir ../$(BIN)-$(VERSION)
	cp -a * ../$(BIN)-$(VERSION)
	cd .. && tar czf $(BIN)-$(VERSION).tar.gz $(BIN)-$(VERSION)
	rm -rf ../$(BIN)-$(VERSION)

uninstall:
	systemctl disable $(BIN)
	systemctl stop $(BIN)
	rm -f /etc/systemd/system/$(BIN).service
	rm -f /$(SBINDIR)/$(BIN)

purge:
	systemctl disable $(BIN)
	systemctl stop $(BIN)
	rm -f /etc/systemd/system/$(BIN).service
	rm -f /$(SBINDIR)/$(BIN)
  rm -f /etc/$(BIN).*