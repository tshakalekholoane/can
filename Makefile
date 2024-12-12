COMMIT = $(shell git rev-parse --short HEAD)
DATE   = $(shell date -u +"%Y.%m.%d")
BUILD  = $(shell printf "%s (%s)" "$(DATE)" "$(COMMIT)" )
CC     = cc
CFLAGS = -DCAN_BUILD="\"$(BUILD)\"" -O3 -Wall -Wextra -Wno-c++98-compat \
	-Wno-cast-function-type-strict -Wno-declaration-after-statement \
	-Wno-format-nonliteral -Wno-incompatible-pointer-types-discards-qualifiers \
	-Wno-poison-system-directories -Wno-vla -framework Foundation -march=native \
	-pedantic -std=c23

.PHONY: all clean

all:
	mkdir -p bin/
	$(CC) $(CFLAGS) -o bin/can src/main.c

clean:
	rm -rf bin/
