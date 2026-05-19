# Copyright (c) 2021-2022 Johannes Overmann
# Released under the MIT license. See LICENSE for license.

TARGET = streplace

CPPFLAGS ?= -pedantic

#CXXFLAGS ?= -Wall -Wextra
CXXFLAGS ?= -Weverything -Wno-c++98-compat -Wno-c++98-compat-pedantic -Wno-padded -Wno-shorten-64-to-32 -Wno-missing-prototypes -Wno-sign-conversion -Wno-implicit-int-conversion -Wno-poison-system-directories -fcomment-block-commands=n -Wno-string-conversion -Wno-covered-switch-default -Wno-extra-semi-stmt

CXXSTD ?= -std=c++23

BUILDDIR=build
UNIT_TEST_BUILDDIR=build-unit-test
SOURCES = $(wildcard src/*.cpp)
OBJECTS = $(SOURCES:%.cpp=$(BUILDDIR)/%.o)
DEPENDS := $(SOURCES:%.cpp=$(BUILDDIR)/%.d)
UNIT_TEST_OBJECTS = $(SOURCES:%.cpp=$(UNIT_TEST_BUILDDIR)/%.o)
UNIT_TEST_DEPENDS := $(SOURCES:%.cpp=$(UNIT_TEST_BUILDDIR)/%.d)

default: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $^ -o $@

build/%.o: %.cpp build/%.d
	$(CXX) $(CXXSTD) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@
        
build/%.d: %.cpp Makefile
	@mkdir -p $(@D)
	$(CXX) $(CXXSTD) $(CPPFLAGS) -MM -MQ $@ $< -o $@

clean:
	rm -rf build $(UNIT_TEST_BUILDDIR) $(TARGET) unit_test
	find . -name '*~' -delete

uint_test: clean
$(UNIT_TEST_BUILDDIR)/%.o: %.cpp $(UNIT_TEST_BUILDDIR)/%.d
	$(CXX) $(CXXSTD) $(CPPFLAGS) -D ENABLE_UNIT_TEST $(CXXFLAGS) -Wno-weak-vtables -Wno-missing-variable-declarations -Wno-exit-time-destructors -Wno-global-constructors -c $< -o $@

$(UNIT_TEST_BUILDDIR)/%.d: %.cpp Makefile
	@mkdir -p $(@D)
	$(CXX) $(CXXSTD) $(CPPFLAGS) -D ENABLE_UNIT_TEST -MM -MQ $@ $< -o $@

unit_test: $(UNIT_TEST_OBJECTS)
	$(CXX) $^ -o $@
	./unit_test

test: unit_test $(TARGET)
	pytest

format:
	clang-format -i --style=file src/*.hpp src/*.cpp

tidy: CXXFLAGS += -MJ $@.cdb
tidy: $(TARGET)
	echo "[" > $(BUILDDIR)/compile_commands.json
	cat $(BUILDDIR)/src/*.cdb >> $(BUILDDIR)/compile_commands.json
	echo "]" >> $(BUILDDIR)/compile_commands.json
	clang-tidy -p $(BUILDDIR) --config-file .clang-tidy src/*.cpp src/*.hpp

.PHONY: clean default unit_test test format

ifeq ($(findstring $(MAKECMDGOALS),clean),)
ifneq ($(MAKECMDGOALS),unit_test)
-include $(DEPENDS)
endif
ifneq ($(filter unit_test test,$(MAKECMDGOALS)),)
-include $(UNIT_TEST_DEPENDS)
endif
endif
