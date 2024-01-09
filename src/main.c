#include <errno.h>
#include <objc/message.h>
#include <pwd.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#ifndef VERSION
#define VERSION "0.4.0"
#endif

static const char* usage = "usage: can [-h | -V] file ...";

// Objective-C messaging primitives require that functions be cast to an
// appropriate function pointer type before being called.

static struct objc_object* file_manager_default(void) {
  struct objc_class* file_manager = objc_getClass("NSFileManager");
  typedef struct objc_object* (*send_type)(struct objc_class*, struct objc_selector*);
  send_type func = (send_type)objc_msgSend;
  return func(file_manager, sel_registerName("defaultManager"));
}

static struct objc_object* file_manager_string_with_file_system_representation(struct objc_object* self, const char string[static 1]) {
  typedef struct objc_object* (*send_type)(struct objc_object*, struct objc_selector*, const char*, unsigned long);
  send_type func = (send_type)objc_msgSend;
  return func(self, sel_registerName("stringWithFileSystemRepresentation:length:"), string, strlen(string));
}

static bool file_manager_trash_item_at_url(struct objc_object* self, struct objc_object* url, struct objc_object** error) {
  typedef bool (*send_type)(struct objc_object*, struct objc_selector*, struct objc_object*, struct objc_object*, struct objc_object**);
  send_type func = (send_type)objc_msgSend;
  return func(self, sel_registerName("trashItemAtURL:resultingItemURL:error:"), url, NULL, error);
}

static struct objc_object* error_localised_description(struct objc_object* self) {
  typedef struct objc_object* (*send_type)(struct objc_object*, struct objc_selector*);
  send_type func = (send_type)objc_msgSend;
  return func(self, sel_registerName("localizedDescription"));
}

static const char* string_encode_utf8(struct objc_object* self) {
  typedef const char* (*send_type)(struct objc_object*, struct objc_selector*);
  send_type func = (send_type)objc_msgSend;
  return func(self, sel_registerName("UTF8String"));
}

static struct objc_object* url_from_file_url_with_path(struct objc_object* string) {
  struct objc_class* url = objc_getClass("NSURL");
  typedef struct objc_object* (*send_type)(struct objc_class*, struct objc_selector*, struct objc_object*);
  send_type func = (send_type)objc_msgSend;
  return func(url, sel_registerName("fileURLWithPath:"), string);
}

int main(int argc, char* argv[argc + 1]) {
  if (argc == 1) {
    fprintf(stderr, "%s\n", usage);
    return EXIT_FAILURE;
  }

  const char* opt = argv[1];
  if (strcmp(opt, "-h") == 0) {
    printf("%s\n", usage);
    return EXIT_SUCCESS;
  } else if (strcmp(opt, "-V") == 0) {
    printf("can %s\n", VERSION);
    return EXIT_SUCCESS;
  }

  for (int i = 1; i < argc; i++) {
    const char* name = argv[i];
    if (strcmp(name, ".") == 0 || strcmp(name, "..") == 0 || strcmp(name, "/") == 0) {
      fprintf(stderr, "\"/\", \".\", and \"..\" may not be removed.\n");
      return EXIT_FAILURE;
    }
  }

  // Avoid using the root user's trash when invoked with sudo.
  const char* superuser = getenv("SUDO_USER");
  if (superuser) {
    struct passwd* entry = getpwnam(superuser);
    if (!entry || seteuid(entry->pw_uid)) {
      fprintf(stderr, "%s\n", strerror(errno));
      return EXIT_FAILURE;
    }
  }

  int exit_code = EXIT_SUCCESS;
  struct objc_object* file_manager = file_manager_default();
  for (int i = 1; i < argc; i++) {
    struct objc_object* name = file_manager_string_with_file_system_representation(file_manager, argv[i]);
    struct objc_object* url = url_from_file_url_with_path(name);
    struct objc_object* error;
    if (!file_manager_trash_item_at_url(file_manager, url, &error)) {
      struct objc_object* description = error_localised_description(error);
      fprintf(stderr, "%s\n", string_encode_utf8(description));
      exit_code = EXIT_FAILURE;
    }
  }
  return exit_code;
}
