#
# include.mk
#
# This source file is part of the FoundationDB open source project
#
# Copyright 2013-2018 Apple Inc. and the FoundationDB project authors
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

TARGETS += fdb_go fdb_go_tester
CLEAN_TARGETS += fdb_go_clean fdb_go_tester_clean

GOPATH := $(CURDIR)/bindings/go

# We only override if the environment didn't set it (this is used by
# the fdbwebsite documentation build process)
GODOC_DIR ?= bindings/go

CGO_CFLAGS := -I$(CURDIR)/bindings/c
CGO_LDFLAGS := -L$(CURDIR)/lib

ifeq ($(PLATFORM),linux)
  GOPLATFORM := linux_amd64
else ifeq ($(PLATFORM),osx)
  GOPLATFORM := darwin_amd64
else
  $(error Not prepared to compile on platform $(PLATFORM))
endif

GO_PACKAGE_OUTDIR := $(GOPATH)/pkg/$(GOPLATFORM)

GO_PACKAGES := fdb fdb/tuple fdb/subspace fdb/directory
GO_PACKAGE_OBJECTS := $(addprefix $(GO_PACKAGE_OUTDIR)/,$(GO_PACKAGES:=.a))

GO_SRC := $(shell find $(GOPATH)/src -name '*.go')

fdb_go: $(GO_PACKAGE_OBJECTS) $(GO_SRC)

fdb_go_clean:
	@echo "Cleaning       fdb_go"
	@rm -rf $(GO_PACKAGE_OUTDIR)

fdb_go_tester: $(GOPATH)/bin/_stacktester

fdb_go_tester_clean:
	@echo "Cleaning       fdb_go_tester"
	@rm -rf $(GOPATH)/bin

$(GOPATH)/bin/_stacktester: $(GO_SRC) $(GO_PACKAGE_OBJECTS) bindings/go/src/fdb/generated.go
	@echo "Compiling      $(basename $(notdir $@))"
	@go install _stacktester

$(GO_PACKAGE_OUTDIR)/fdb/tuple.a: $(GO_SRC) $(GO_PACKAGE_OUTDIR)/fdb.a bindings/go/src/fdb/generated.go
	@echo "Compiling      fdb/tuple"
	@go install fdb/tuple

$(GO_PACKAGE_OUTDIR)/fdb/subspace.a: $(GO_SRC) $(GO_PACKAGE_OUTDIR)/fdb.a $(GO_PACKAGE_OUTDIR)/fdb/tuple.a bindings/go/src/fdb/generated.go
	@echo "Compiling      fdb/subspace"
	@go install fdb/subspace

$(GO_PACKAGE_OUTDIR)/fdb/directory.a: $(GO_SRC) $(GO_PACKAGE_OUTDIR)/fdb.a $(GO_PACKAGE_OUTDIR)/fdb/tuple.a $(GO_PACKAGE_OUTDIR)/fdb/subspace.a bindings/go/src/fdb/generated.go
	@echo "Compiling      fdb/directory"
	@go install fdb/directory

$(GO_PACKAGE_OUTDIR)/fdb.a: $(GO_SRC) bindings/go/src/fdb/generated.go
	@echo "Compiling      fdb"
	@go install fdb

bindings/go/src/fdb/generated.go: lib/libfdb_c.$(DLEXT) bindings/go/src/_util/translate_fdb_options.go fdbclient/vexillographer/fdb.options
	@echo "Building       $@"
	@go run bindings/go/src/_util/translate_fdb_options.go < fdbclient/vexillographer/fdb.options > $@

godoc: $(GO_SRC)
	@echo "Generating Go Documentation"
	@rm -rf $(GODOC_DIR)/godoc
	@mkdir -p $(GODOC_DIR)/godoc
	@mkdir -p $(GODOC_DIR)/godoc/lib/godoc
	@godoc -url "http://localhost:6060/pkg/fdb" > $(GODOC_DIR)/godoc/fdb.html
	@godoc -url "http://localhost:6060/pkg/fdb/tuple" > $(GODOC_DIR)/godoc/fdb.tuple.html
	@godoc -url "http://localhost:6060/pkg/fdb/subspace" > $(GODOC_DIR)/godoc/fdb.subspace.html
	@godoc -url "http://localhost:6060/pkg/fdb/directory" > $(GODOC_DIR)/godoc/fdb.directory.html
	@cp $(GOPATH)/godoc-resources/* $(GODOC_DIR)/godoc/lib/godoc
	@echo "Mangling paths in Go Documentation"
	@(find $(GODOC_DIR)/godoc/ -name *.html -exec sed -i '' -e 's_/lib_lib_' {} \;)
	@(sed -i -e 's_a href="tuple/"_a href="fdb.tuple.html"_' $(GODOC_DIR)/godoc/fdb.html)
	@(sed -i -e 's_a href="subspace/"_a href="fdb.subspace.html"_' $(GODOC_DIR)/godoc/fdb.html)
	@(sed -i -e 's_a href="directory/"_a href="fdb.directory.html"_' $(GODOC_DIR)/godoc/fdb.html)

godoc_clean:
	@echo "Cleaning Go Documentation"
	@rm -rf $(GODOC_DIR)/godoc
