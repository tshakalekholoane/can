COMMIT = $(shell git rev-parse --short HEAD)
TAG    = $(shell git describe --tags --always)
BUILD  = $(shell printf "%s (%s)" "$(TAG)" "$(COMMIT)")

CC = clang

CFLAGS =                              \
  -DCAN_BUILD_INFO="\"can $(BUILD)\"" \
  -O3                                 \
  -Wall                               \
  -Weverything                        \
  -Wextra                             \
  -Wno-c++98-compat                   \
  -Wno-declaration-after-statement    \
  -Wno-poison-system-directories      \
  -Wno-pre-c23-compat                 \
  -Wno-vla                            \
  -ffast-math                         \
  -fmodules                           \
  -fno-omit-frame-pointer             \
  -march=native                       \
  -std=gnu23

LDFLAGS =               \
  -ObjC                 \
  -flto=full            \
  -framework Foundation

MAKEFLAGS += --no-builtin-rules

bin/can: src/main.m
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) $< $(LDFLAGS) -o $@

.PHONY: clean
clean:
	@-rm bin/can
