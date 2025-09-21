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

#define len(a)              (sizeof(a) / sizeof(a[0]))
#define unlikely(condition) __builtin_expect((bool) (condition), false)

static const char* usage = "usage: can [-h | -V] [--] file ...\n";

[[gnu::nonnull(1)]]
static inline bool is_invalid_path(const char string[static 1]) {
  static const char* invalid[]   = { ".", "..", "./", "./.", "./..", "/", "/.", "/.." };
  constexpr size_t   invalid_len = len(invalid);
  for (size_t i = 0; i < invalid_len; i++) {
    if (unlikely(strcmp(string, invalid[i]) == 0))
      return true;
  }
  return false;
}

int main(int argc, char* argv[argc + 1]) {
  int opt;
  while (unlikely((opt = getopt(argc, argv, "hV")) != -1)) {
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

  if (unlikely(argc == 1)) {
    (void) fputs(usage, stderr);
    return EXIT_FAILURE;
  }

  argc -= optind;
  argv += optind;

  for (int i = 0; i < argc; i++) {
    if (unlikely(is_invalid_path(argv[i]))) {
      fputs("\"/\", \".\", and \"..\" may not be removed.\n", stderr);
      return EXIT_FAILURE;
    }
  }

  // Avoid using the root user's trash when invoked with sudo.
  const char* user = getenv("SUDO_USER");
  if (unlikely(user != nullptr)) {
    struct passwd* entry = getpwnam(user);
    if (unlikely(entry == nullptr || seteuid(entry->pw_uid) != 0)) {
      perror(nullptr);
      return EXIT_FAILURE;
    }
  }

  int status = EXIT_SUCCESS;

  @autoreleasepool {
    NSFileManager* manager = [NSFileManager defaultManager];
    for (int i = 0; i < argc; i++) {
      const char* representation = argv[i];
      NSUInteger  length         = strlen(representation);

      // + [NSURL fileURLWithPath:] requires a non-empty path.
      if (unlikely(length == 0))
        continue;

      NSString* path = [manager stringWithFileSystemRepresentation:representation length:length];
      NSURL*    url  = [NSURL fileURLWithPath:path];
      NSError*  error;
      if (unlikely(![manager trashItemAtURL:url resultingItemURL:nil error:&error])) {
        (void) fputs([[error localizedDescription] UTF8String], stderr);
        (void) fputc('\n', stderr);
        status = EXIT_FAILURE;
      }
    }
  }

  return status;
}

// vim: filetype=objc
