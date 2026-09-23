// Copyright (c) 2013, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.

#ifndef fishhook_h
#define fishhook_h

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h> // <--- Bổ sung dòng này để định nghĩa intptr_t

#if !defined(FISHHOOK_EXPORT)
#define FISHHOOK_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/*
 * A structure representing a particular symtab rebind.
 */
struct rebinding {
  const char *name;
  void *replacement;
  void **replaced;
};

/*
 * Rebind function calls for all loaded-and-to-be-loaded dynamic images that
 * match any of the rebindings structures in array rebindings with number of
 * entries nel. If you wish to usefishhook to hook functions in other dynamically
 * loaded libraries, you can call rebind_symbols_image directly.
 */
FISHHOOK_EXPORT int rebind_symbols(struct rebinding rebindings[], size_t nel);

/*
 * Rebind function calls for a specific image. This is useful if you are
 * loading a dylib dynamically or if you want to restrict hooks to a specific binary.
 */
FISHHOOK_EXPORT int rebind_symbols_image(void *header,
                                        intptr_t slide,
                                        struct rebinding rebindings[],
                                        size_t nel);

#ifdef __cplusplus
}
#endif

#endif /* fishhook_h */
