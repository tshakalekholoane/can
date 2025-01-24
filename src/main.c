#ifndef __APPLE__
  #error "This program is intended to only run on macOS."
#endif

#if __STDC_VERSION__ < 202311L
  #error "This code requires C23 or later."
#endif

#include <errno.h>
#include <getopt.h>
#include <objc/message.h>
#include <pwd.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#ifndef CAN_BUILD
  #define CAN_BUILD "TIP"
#endif

#define shift(n)  \
  do {            \
    argc -= (n);  \
    argv += (n);  \
  } while (false)

#define unlikely(c) __builtin_expect(!!(c), false)

static const char* usage = "usage: can [-h | -V] [--] file ...";

// Objective-C messaging primitives require that functions be cast to an
// appropriate function pointer type before being called [1].
//
// [1]: https://tshaka.dev/a/7HQ9I9

static id file_manager_default_manager(void) {
  auto file_manager = objc_getClass("NSFileManager");
  typedef id (*send_type)(Class, SEL);
  auto func = (send_type)objc_msgSend;
  return func(file_manager, sel_registerName("defaultManager"));
}

static id file_manager_string_with_file_system_representation(id self, const char string[static 1]) {
  typedef id (*send_type)(id, SEL, const char*, unsigned long);
  auto func = (send_type)objc_msgSend;
  return func(self, sel_registerName("stringWithFileSystemRepresentation:length:"), string, strlen(string));
}

static bool file_manager_trash_item_at_url(id self, id url, id* err) {
  typedef bool (*send_type)(id, SEL, id, id, id*);
  auto func = (send_type)objc_msgSend;
  return func(self, sel_registerName("trashItemAtURL:resultingItemURL:error:"), url, nullptr, err);
}

static id error_localized_description(id self) {
  typedef id (*send_type)(id, SEL);
  auto func = (send_type)objc_msgSend;
  return func(self, sel_registerName("localizedDescription"));
}

static const char* string_utf8_string(id self) {
  typedef const char* (*send_type)(id, SEL);
  auto func = (send_type)objc_msgSend;
  return func(self, sel_registerName("UTF8String"));
}

static id url_file_url_with_path(id string) {
  auto url = objc_getClass("NSURL");
  typedef id (*send_type)(Class, SEL, id);
  auto func = (send_type)objc_msgSend;
  return func(url, sel_registerName("fileURLWithPath:"), string);
}

int main(int argc, char* argv[argc + 1]) {
  int opt;
  while ((opt = getopt(argc, argv, "hV")) != -1) {
    switch (opt) {
    case 'h':
      printf("%s\n", usage);
      return EXIT_SUCCESS;
    case 'V':
      printf("can %s\n", CAN_BUILD);
      return EXIT_SUCCESS;
    default:
      fprintf(stderr, "%s\n", usage);
      return EXIT_FAILURE;
    }
  }
  if (unlikely(argc == 1)) {
    fprintf(stderr, "%s\n", usage);
    return EXIT_FAILURE;
  }
  shift(1);

  for (ssize_t i = 0; i < (ssize_t)argc; i++) {
    auto name = argv[i];
    if (unlikely(strcmp(name, ".") == 0 || strcmp(name, "..") == 0 || strcmp(name, "/") == 0)) {
      fprintf(stderr, "\"/\", \".\", and \"..\" may not be removed.\n");
      return EXIT_FAILURE;
    }
  }

  // Avoid using the root user's trash when invoked with sudo.
  auto superuser = getenv("SUDO_USER");
  if (unlikely(superuser != nullptr)) {
    auto entry = getpwnam(superuser);
    if (unlikely(!entry || seteuid(entry->pw_uid))) {
      fprintf(stderr, "%s\n", strerror(errno));
      return EXIT_FAILURE;
    }
  }

  // Ignore flag separator.
  if (unlikely(strcmp(argv[0], "--") == 0))
    shift(1);

  auto exit_code    = EXIT_SUCCESS;
  auto file_manager = file_manager_default_manager();
  for (ssize_t i = 0; i < (ssize_t)argc; i++) {
    auto path = file_manager_string_with_file_system_representation(file_manager, argv[i]);
    auto url  = url_file_url_with_path(path);
    id err;
    if (unlikely(!file_manager_trash_item_at_url(file_manager, url, &err))) {
      auto description = error_localized_description(err);
      fprintf(stderr, "%s\n", string_utf8_string(description));
      exit_code = EXIT_FAILURE;
    }
  }
  return exit_code;
}
