CC := clang

TAG := \"$(shell git describe --always --dirty --tags --long)\"

CFLAGS := -framework Foundation -Wall -Wextra -Weverything -Wno-c++98-compat \
	-Wno-declaration-after-statement -Wno-vla -Wno-poison-system-directories \
	-Wno-format-nonliteral -O3 -flto -std=c2x -DVERSION=${TAG}
ARCH_FLAGS := -arch

SRC := src/main.c

OUT := bin/can

# Architecture-specific output binaries.
OUT_AMD64 := bin/can_amd64
OUT_AARCH64 := bin/can_aarch64

# Combine amd64 and aarch64 binaries.
UNIVERSAL_BIN := bin/can

.PHONY: all clean

all: $(UNIVERSAL_BIN)

$(UNIVERSAL_BIN): $(OUT_AMD64) $(OUT_AARCH64)
	lipo -create -output $(UNIVERSAL_BIN) $(OUT_AMD64) $(OUT_AARCH64)

$(OUT_AMD64): $(SRC)
	mkdir -p $(dir $(OUT_AMD64))
	$(CC) $(CFLAGS) $(ARCH_FLAGS) x86_64 -o $(OUT_AMD64) $(SRC)

$(OUT_AARCH64): $(SRC)
	mkdir -p $(dir $(OUT_AARCH64))
	$(CC) $(CFLAGS) $(ARCH_FLAGS) arm64 -o $(OUT_AARCH64) $(SRC)

clean:
	rm -f $(OUT_AMD64) $(OUT_AARCH64) $(UNIVERSAL_BIN)
