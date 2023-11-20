#include <errno.h>
#include <objc/message.h>
#include <pwd.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define VERSION "0.4.0"

static id file_manager_default(void) {
  struct objc_class* file_manager = objc_getClass("NSFileManager");
  typedef id (*send_type)(struct objc_class*, SEL);
  send_type func = (send_type)objc_msgSend;
  id file_manager_default = func(file_manager, sel_registerName("defaultManager"));
  return file_manager_default;
}

static id file_manager_str_with_file_system_repr(id file_manager, const char str[static 1]) {
  typedef id (*send_type)(id, SEL, const char*, unsigned long);
  send_type func = (send_type)objc_msgSend;
  id file_name = func(file_manager, sel_registerName("stringWithFileSystemRepresentation:length:"), str, strlen(str));
  return file_name;
}

static bool file_manager_trash_item_at_url(id file_manager, id url, id* error) {
  typedef BOOL (*send_type)(id, SEL, id, void*, id*);
  send_type func = (send_type)objc_msgSend;
  bool result = func(file_manager, sel_registerName("trashItemAtURL:resultingItemURL:error:"), url, NULL, error);
  return result;
}

static char* error_localised_description(id error) {
  typedef id (*send_type)(id, SEL);
  send_type func = (send_type)objc_msgSend;
  id description = func(error, sel_registerName("localizedDescription"));
  char* description_as_utf8_str = (char*)func(description, sel_registerName("UTF8String"));
  return description_as_utf8_str;
}

static id url_file_url_with_path(id string) {
  struct objc_class* url = objc_getClass("NSURL");
  typedef id (*send_type)(struct objc_class*, SEL, id);
  send_type func = (send_type)objc_msgSend;
  id file_url = func(url, sel_registerName("fileURLWithPath:"), string);
  return file_url;
}

[[noreturn]] static void fatalf(const char format[static 1], ...) {
  va_list args;
  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
  exit(EXIT_FAILURE);
}

static bool trash_file(const char name[static 1]) {
  id file_manager = file_manager_default();
  id file_name = file_manager_str_with_file_system_repr(file_manager, name);
  id file_url = url_file_url_with_path(file_name);
  id err;
  bool ok = file_manager_trash_item_at_url(file_manager, file_url, &err);
  if (!ok)
    fprintf(stderr, "%s\n", error_localised_description(err));
  return ok;
}

int main(int argc, char* argv[argc + 1]) {
  const char* prog = argv[0];
  if (argc == 1)
    fatalf("usage: %s [-hV] [file ...]\n", prog);

  const char* opt = argv[1];
  if (strcmp(opt, "-h") == 0) {
    printf("usage: %s [-hV] [file ...]\n", prog);
    return EXIT_SUCCESS;
  } else if (strcmp(opt, "-V") == 0) {
    printf("%s: %s\n", prog, VERSION);
    return EXIT_SUCCESS;
  }

  for (int i = 1; i < argc; i++) {
    const char* name = argv[i];
    if (strcmp(name, ".") == 0 || strcmp(name, "..") == 0 || strcmp(name, "/") == 0)
      fatalf("\"/\", \".\", and \"..\" may not be removed.\n");
  }

  // Avoid using the root user trash when invoked with sudo.
  char* logged_in = getenv("SUDO_USER");
  if (logged_in) {
    struct passwd* entry = getpwnam(logged_in);
    if (!entry || seteuid(entry->pw_uid))
      fatalf(strerror(errno));
  }

  int exit_status = EXIT_SUCCESS;
  for (int i = 1; i < argc; i++) {
    if (!trash_file(argv[i]))
      exit_status = EXIT_FAILURE;
  }
  return exit_status;
}
