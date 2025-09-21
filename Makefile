COMMIT = $(shell git rev-parse --short HEAD)
TAG    = $(shell git tag)
BUILD  = $(shell printf "%s (%s)" "$(TAG)" "$(COMMIT)")

CC     = clang
CFLAGS = -DCAN_BUILD_INFO="\"can $(BUILD)\"" -O3 -Wall -Wno-declaration-after-statement     \
	-Weverything -Wextra -Wno-c++98-compat -Wno-poison-system-directories -Wno-pre-c23-compat \
	-Wno-vla -ffast-math -flto -fmodules -framework Foundation -march=native -std=gnu23

bin/can: src/main.m
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) $< -o $@

.PHONY: clean
clean:
	@-rm bin/can
