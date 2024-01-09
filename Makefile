CC := clang

CFLAGS := -O3 -Wall -Weverything -Wextra -Wno-c++98-compat \
	-Wno-declaration-after-statement -Wno-format-nonliteral -Wno-vla \
	-Wno-poison-system-directories -flto -framework Foundation -pedantic -std=c17

SRC := src/main.c

OUT := bin/can
OUT_AMD64 := bin/can_amd64
OUT_AARCH64 := bin/can_aarch64

.PHONY: all clean native

all: $(OUT)

clean:
	rm -f $(OUT_AMD64) $(OUT_AARCH64) $(OUT)

native:
	mkdir -p $(dir $(OUT))
	$(CC) $(CFLAGS) -march=native -o $(OUT) $(SRC)

$(OUT): $(OUT_AMD64) $(OUT_AARCH64)
	lipo -create -output $(OUT) $(OUT_AMD64) $(OUT_AARCH64)

$(OUT_AMD64): $(SRC)
	mkdir -p $(dir $(OUT_AMD64))
	$(CC) $(CFLAGS) -arch x86_64 -o $(OUT_AMD64) $(SRC)

$(OUT_AARCH64): $(SRC)
	mkdir -p $(dir $(OUT_AARCH64))
	$(CC) $(CFLAGS) -arch arm64 -o $(OUT_AARCH64) $(SRC)
