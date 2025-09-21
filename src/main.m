#include <getopt.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

@import Foundation;

#ifndef CAN_BUILD_INFO
  #error "CAN_BUILD_INFO must be defined at compile time"
#endif

#if __STDC_VERSION__ < 202311L
  #error "this is a C23 (Objective-C 2.0) program"
#endif

static const char* usage = "usage: can [-h | -V] [--] file ...\n";

[[gnu::nonnull(1)]]
static inline bool is_invalid_path(const char string[static 1]) {
  static const char* invalid[]   = { ".", "..", "./", "./.", "./..", "/", "/.", "/.." };
  constexpr long invalid_len = sizeof(invalid) / sizeof(invalid[0]);
  for (long i = 0; i < invalid_len; i += 1) {
    if (strcmp(string, invalid[i]) == 0) [[clang::unlikely]]
      return true;
  }
  return false;
}

int main(int argc, char* argv[argc + 1]) {
  int opt;
  while ((opt = getopt(argc, argv, "hV")) != -1) [[clang::unlikely]] {
    switch (opt) {
    case 'h':
      (void) fputs(usage, stdout);
      return EXIT_SUCCESS;
    case 'V':
      (void) puts(CAN_BUILD_INFO);
      return EXIT_SUCCESS;
    default:
      (void) fputs(usage, stderr);
      return EXIT_FAILURE;
    }
  }

  if (argc == 1) [[clang::unlikely]] {
    (void) fputs(usage, stderr);
    return EXIT_FAILURE;
  }

  argc -= optind;
  argv += optind;

  for (long i = 0; i < argc; i += 1) {
    if (is_invalid_path(argv[i])) [[clang::unlikely]] {
      fputs("\"/\", \".\", and \"..\" may not be removed.\n", stderr);
      return EXIT_FAILURE;
    }
  }

  // Avoid using the root user's trash when invoked with sudo.
  const char* user = getenv("SUDO_USER");
  if (user != nullptr) [[clang::unlikely]] {
    struct passwd* entry = getpwnam(user);
    if (entry == nullptr || seteuid(entry->pw_uid) != 0) [[clang::unlikely]] {
      perror(nullptr);
      return EXIT_FAILURE;
    }
  }

  int status = EXIT_SUCCESS;

  @autoreleasepool {
    NSFileManager* manager = [NSFileManager defaultManager];
    for (long i = 0; i < argc; i++) {
      const char* representation = argv[i];
      NSUInteger  length         = strlen(representation);

      // + [NSURL fileURLWithPath:] requires a non-empty path.
      if (length == 0) [[clang::unlikely]]
        continue;

      NSString* path = [manager stringWithFileSystemRepresentation:representation length:length];
      NSURL*    url  = [NSURL fileURLWithPath:path];
      NSError*  error;
      if (![manager trashItemAtURL:url resultingItemURL:nil error:&error]) [[clang::unlikely]] {
        (void) fputs([[error localizedDescription] UTF8String], stderr);
        (void) fputc('\n', stderr);
        status = EXIT_FAILURE;
      }
    }
  }

  return status;
}

// vim: filetype=objc
