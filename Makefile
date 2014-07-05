#g++ -o txlparser txlparser.cc -std=gnu++0x

CC = g++
CFLAGS ?= -std=gnu++0x
PREFIX ?= /usr/local
INSTALLDIR ?= $(PREFIX)/bin

SRC = src
BLD = build
#DOC = doc
#DIST = dist
TEST = test_data

default: build

all: clean build test

build: $(SRC)/txlparser.cc $(SRC)/txl2xml.sh $(SRC)/xml2txl.sh $(SRC)/compact_attributes.xsl $(SRC)/xml2txl.xsl

	@echo ""
	@echo "complinlg txlparser.cc"
	@echo "----------------------"
	@echo ""
	@echo "CC        : $(CC)"
	@echo "CFLAGS    : $(CFLAGS)"
	@echo "PREFIX    : $(PREFIX)"
	@echo "INSTALLDIR: $(INSTALLDIR)"
	@echo ""
	@echo "to change these variables either edit the Makefile or use i.e.:"
	@echo "sudo make install PREFIX=/usr"
	@echo ""

	mkdir -p $(BLD)

	$(CC) -o $(BLD)/txlparser $(SRC)/txlparser.cc $(CFLAGS)
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
	@echo "INSTALLDIR: $(INSTALLDIR)"
	@echo ""
	@echo "'make install' needs to be run with root privileges, i.e."
	@echo ""
	@echo "sudo make install"
	@echo ""

	cp $(BLD)/txlparser $(INSTALLDIR)/
	cp $(BLD)/txl2xml $(INSTALLDIR)/
	cp $(BLD)/xml2txl $(INSTALLDIR)/
	cp $(BLD)/compact_attributes.xsl $(INSTALLDIR)/
	cp $(BLD)/xml2txl.xsl $(INSTALLDIR)/


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
	@echo "INSTALLDIR: $(INSTALLDIR)"
	@echo ""
	@echo "'make uninstall' needs to be run with root privileges, i.e."
	@echo ""
	@echo "sudo make uninstall"
	@echo ""

	rm -f $(INSTALLDIR)/txlparser
	rm -f $(INSTALLDIR)/txl2xml
	rm -f $(INSTALLDIR)/xml2txl
	rm -f $(INSTALLDIR)/compact_attributes.xsl
	rm -f $(INSTALLDIR)/xml2txl.xsl

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

	mkdir -p $(BLD)
	rm -f ./$(BLD)/*

	@echo ""
	@echo "done."
	@echo ""

.PHONY: all
