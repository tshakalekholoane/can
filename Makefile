COMMIT = $(shell git rev-parse --short HEAD)
TAG    = $(shell git tag)
BUILD  = $(shell printf "%s (%s)" "$(TAG)" "$(COMMIT)")
CC     = clang
CFLAGS = -DCAN_BUILD="\"$(BUILD)\"" -O3 -Wall -Weverything -Wextra \
	-Wno-c++98-compat -Wno-cast-function-type-strict \
	-Wno-declaration-after-statement -Wno-format-nonliteral \
	-Wno-incompatible-pointer-types-discards-qualifiers \
	-Wno-poison-system-directories -Wno-pre-c23-compat -Wno-vla -ffast-math \
	-flto -framework Foundation -march=native -pedantic -std=gnu23

bin/can: src/main.o
	mkdir -p bin
	$(CC) $(CFLAGS) src/main.o -o bin/can

src/main.o:

.PHONY: clean
clean:
	-rm bin/can src/main.o
