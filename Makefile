#g++ -o txlparser txlparser.cc -std=gnu++0x

CC = g++
CFLAGS ?= -std=gnu++0x
PREFIX ?= /usr/local
bindir = $(PREFIX)/bin
XSLDIR = $(bindir)/txl_xsl

SRC = src
BLD = build
TEST = test_data

default: build

all: build

build: $(SRC)/txlparser.cc $(SRC)/txl2xml.sh $(SRC)/xml2txl.sh $(SRC)/compact_attributes.xsl $(SRC)/xml2txl.xsl

	@echo ""
	@echo "complinlg txlparser.cc, txlprep.cc"
	@echo "----------------------------------"
	@echo ""
	@echo "CC        : $(CC)"
	@echo "CFLAGS    : $(CFLAGS)"
	@echo "PREFIX    : $(PREFIX)"
	@echo "bindir    : $(bindir)"
	@echo ""
	@echo "to change these variables either edit the Makefile or use i.e.:"
	@echo "sudo make install PREFIX=/usr"
	@echo ""

	mkdir -p $(BLD)

	$(CC) -o $(BLD)/txlparser $(SRC)/txlparser.cc $(CFLAGS)
	$(CC) -o $(BLD)/txlprep $(SRC)/txlprep.cc $(CFLAGS)

	cp $(SRC)/txl2xml.sh $(BLD)/txl2xml
	cp $(SRC)/xml2txl.sh $(BLD)/xml2txl
	cp $(SRC)/compact_attributes.xsl $(BLD)/
	cp $(SRC)/xml2txl.xsl $(BLD)/

	@echo ""
	@echo "done."
	@echo ""

install:

	@echo ""
	@echo "installing txl2xml, xml2txl"
	@echo "---------------------------"
	@echo ""
	@echo "DESTDIR: $(DESTDIR)"
	@echo "bindir: $(bindir)"
	@echo ""
	@echo "'make install' needs to be run with root privileges, i.e."
	@echo ""
	@echo "sudo make install"
	@echo ""

	install -d $(DESTDIR)$(bindir)/

	install -m755 $(BLD)/txlparser $(DESTDIR)$(bindir)/
	install -m755 $(BLD)/txlprep $(DESTDIR)$(bindir)/
	install -m755 $(BLD)/txl2xml $(DESTDIR)$(bindir)/
	install -m755 $(BLD)/xml2txl $(DESTDIR)$(bindir)/

	install -d $(DESTDIR)$(XSLDIR)

	install -m644 $(BLD)/compact_attributes.xsl $(DESTDIR)$(XSLDIR)/
	install -m644 $(BLD)/xml2txl.xsl $(DESTDIR)$(XSLDIR)/

	@echo ""
	@echo "use: cat a.txl | txl2xml"
	@echo "use: cat a.xml | xml2txl"
	@echo ""
	@echo "done."
	@echo ""

uninstall:

	@echo ""
	@echo "uninstalling txl2xml, xml2txl"
	@echo "-----------------------------"
	@echo ""
	@echo "DESTDIR: $(DESTDIR)"
	@echo "bindir: $(bindir)"
	@echo ""
	@echo "'make uninstall' needs to be run with root privileges, i.e."
	@echo ""
	@echo "sudo make uninstall"
	@echo ""

	rm -f $(DESTDIR)$(bindir)/txlparser
	rm -f $(DESTDIR)$(bindir)/txlprep

	rm -f $(DESTDIR)$(bindir)/txl2xml
	rm -f $(DESTDIR)$(bindir)/xml2txl

	rm -f $(DESTDIR)$(XSLDIR)/compact_attributes.xsl
	rm -f $(DESTDIR)$(XSLDIR)/xml2txl.xsl

	-rmdir $(DESTDIR)$(XSLDIR)

	-rmdir $(DESTDIR)$(bindir)

	@echo ""
	@echo "done."
	@echo ""

test: 

	@echo ""
	@echo "testing serveral txl files"
	@echo "--------------------------"
	@echo ""

	@echo "DUMMY"
	#ls -1 test_data/*.txl | while read line; do echo "$line"; echo "======"; cat $line | txl2xml > /tmp/a; cat /tmp/a | xml2txl | txl2xml > /tmp/b; diff /tmp/a /tmp/b; done

	@echo ""
	@echo "done."
	@echo ""

clean:

	@echo ""
	@echo "cleaning up $(BLD) directory"
	@echo "---------------------------"
	@echo ""

	rm -rf $(BLD)

	@echo ""
	@echo "done."
	@echo ""

.PHONY: all build clean test install uninstall
