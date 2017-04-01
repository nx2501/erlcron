# Copyright Erlware, LLC. All Rights Reserved.
#
# This file is provided to you under the BSD License; you may not use
# this file except in compliance with the License.  You may obtain a
# copy of the License.

ERLFLAGS= -pa $(CURDIR)/.eunit -pa $(CURDIR)/ebin -pa $(CURDIR)/deps/*/ebin

DEPS_PLT=$(CURDIR)/.deps_plt

DIALYZER = dialyzer

DIALYZER_WARNINGS = -Wunmatched_returns -Werror_handling \
                    -Wrace_conditions -Wunderspecs

# =============================================================================
# Verify that the programs we need to run are installed on this system
# =============================================================================
ERL = $(shell which erl)

ifeq ($(ERL),)
$(error "Erlang not available on this system")
endif

REBAR=$(shell command -v rebar || echo ./rebar3)

ifeq ($(REBAR),)
$(error "Rebar not available on this system")
endif

.PHONY: all compile doc clean test dialyze typer shell distclean pdf \
	deps escript clean-common-test-data rebuild

#all: compile dialyze test
all: compile test

# =============================================================================
# Rules to build the system
# =============================================================================

deps:
	$(REBAR) deps
	$(REBAR) compile

compile:
	$(REBAR) compile

doc:
	$(REBAR) doc

eunit: compile clean-common-test-data
	$(REBAR) eunit

ct: compile clean-common-test-data
	$(REBAR) ct

test: compile eunit ct

$(DEPS_PLT):
	@echo Building local plt at $(DEPS_PLT)
	@echo
	dialyze --output_plt $(DEPS_PLT) --build_plt \
	   --apps erts kernel stdlib

.dialyzer_plt:
	@$(DIALYZER) --build_plt --output_plt .dialyzer_plt --apps kernel stdlib

build-plt: .dialyzer_plt

dialyze: build-plt
	@$(DIALYZER) --src src --plt .dialyzer_plt $(DIALYZER_WARNINGS)

typer:
	typer --plt $(DEPS_PLT) -r ./src

shell: deps compile
# You often want *rebuilt* rebar tests to be available to the
# shell you have to call eunit (to get the tests
# rebuilt). However, eunit runs the tests, which probably
# fails (thats probably why You want them in the shell). This
# runs eunit but tells make to ignore the result.
	- @$(REBAR) eunit
	@$(ERL) $(ERLFLAGS)

pdf:
	pandoc README.md -o README.pdf

clean-common-test-data:
# We have to do this because of the unique way we generate test
# data. Without this rebar eunit gets very confused
	- rm -rf $(CURDIR)/test/*_SUITE_data

clean: clean-common-test-data
	- rm -rf $(CURDIR)/_build/default/lib/*/*.beam
	- rm -rf $(CURDIR)/_build/test/lib/*/*.beam
	- rm -rf $(CURDIR)/_build/test/logs
	$(REBAR) clean

distclean: clean
	- rm -rf $(DEPS_PLT)
	- rm -rvf $(CURDIR)/deps/*

rebuild: clean deps compile dialyze test
