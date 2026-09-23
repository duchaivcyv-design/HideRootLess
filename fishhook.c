// Copyright (c) 2013, Facebook, Inc.
// All rights reserved.
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

#include "fishhook.h"

#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach/vm_prot.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

struct rebindings_entry {
  struct rebinding *rebindings;
  size_t rebindings_nel;
  struct rebindings_entry *next;
};

static struct rebindings_entry *_rebindings_head;

static int prepend_rebindings(struct rebindings_entry **rebindings_head,
                               struct rebinding rebindings[],
                               size_t nel) {
  struct rebindings_entry *new_entry = (struct rebindings_entry *)malloc(sizeof(struct rebindings_entry));
  if (!new_entry) {
    return -1;
  }
  new_entry->rebindings = (struct rebinding *)malloc(sizeof(struct rebinding) * nel);
  if (!new_entry->rebindings) {
    free(new_entry);
    return -1;
  }
  memcpy(new_entry->rebindings, rebindings, sizeof(struct rebinding) * nel);
  new_entry->rebindings_nel = nel;
  new_entry->next = *rebindings_head;
  *rebindings_head = new_entry;
  return 0;
}

static void _rebind_symbols_for_image(struct rebindings_entry *rebindingsare,
                                      const struct mach_header *header,
                                      intptr_t slide) {
  Dl_info info;
  if (dladdr(header, &info) == 0) {
    return;
  }

  segment_command_t *cur_seg_cmd;
  uintptr_t glbas_offset = (uintptr_t)header;
  uintptr_t cmd_offset = glbas_offset + sizeof(mach_header_t);
  
  uint32_t ncmds = header->ncmds;
  struct symtab_command *symtab_cmd = NULL;
  struct dysymtab_command *dysymtab_cmd = NULL;

  for (uint32_t i = 0; i < ncmds; i++) {
    cur_seg_cmd = (segment_command_t *)cmd_offset;
    if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
      if (strcmp(cur_seg_cmd->segname, SEG_DATA) == 0 ||
          strcmp(cur_seg_cmd->segname, "__DATA_CONST") == 0) {
        for (uint32_t j = 0; j < cur_seg_cmd->nsects; j++) {
          section_t *sect = (section_t *)(cmd_offset + sizeof(segment_command_t)) + j;
          if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS ||
              (sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
            // Processing sections
          }
        }
      }
    } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
      symtab_cmd = (struct symtab_command *)cur_seg_cmd;
    } else if (cur_seg_cmd->cmd == LC_DYSYMTAB) {
      dysymtab_cmd = (struct dysymtab_command *)cur_seg_cmd;
    }
    cmd_offset += cur_seg_cmd->cmdsize;
  }

  if (!symtab_cmd || !dysymtab_cmd) {
    return;
  }

  nlist_t *symtab = (nlist_t *)(slide + symtab_cmd->symoff);
  char *strtab = (char *)(slide + symtab_cmd->stroff);

  uint32_t *indirect_symtab = (uint32_t *)(slide + dysymtab_cmd->indirectsymoff);

  cmd_offset = glbas_offset + sizeof(mach_header_t);
  for (uint32_t i = 0; i < ncmds; i++) {
    cur_seg_cmd = (segment_command_t *)cmd_offset;
    if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
      if (strcmp(cur_seg_cmd->segname, SEG_DATA) != 0 &&
          strcmp(cur_seg_cmd->segname, "__DATA_CONST") != 0) {
        cmd_offset += cur_seg_cmd->cmdsize;
        continue;
      }
      for (uint32_t j = 0; j < cur_seg_cmd->nsects; j++) {
        section_t *sect = (section_t *)(cmd_offset + sizeof(segment_command_t)) + j;
        if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS ||
            (sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
          uint32_t *indirect_symbol_indices = indirect_symtab + sect->reserved1;
          void **indirect_symbol_bindings = (void **)(slide + sect->addr);
          for (uint32_t k = 0; k < sect->size / sizeof(void *); k++) {
            uint32_t symtab_index = indirect_symbol_indices[k];
            if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL ||
                symtab_index == (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS)) {
              continue;
            }
            uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx;
            char *symbol_name = strtab + strtab_offset;
            bool symbol_name_longer_than_1 = symbol_name[0] && symbol_name[1];
            struct rebindings_entry *cur = rebindingsare;
            while (cur) {
              for (size_t m = 0; m < cur->rebindings_nel; m++) {
                if (symbol_name_longer_than_1 &&
                    strcmp(&symbol_name[1], cur->rebindings[m].name) == 0) {
                  if (cur->rebindings[m].replaced != NULL &&
                      *cur->rebindings[m].replaced == NULL) {
                    *cur->rebindings[m].replaced = indirect_symbol_bindings[k];
                  }
                  vm_address_t address = (vm_address_t)&indirect_symbol_bindings[k];
                  vm_size_t size = sizeof(void *);
                  vm_protect(mach_task_self(), address, size, 0, VM_PROT_READ | VM_PROT_WRITE);
                  indirect_symbol_bindings[k] = cur->rebindings[m].replacement;
                  vm_protect(mach_task_self(), address, size, 0, VM_PROT_READ);
                  goto symbol_loop;
                }
              }
              cur = cur->next;
            }
          symbol_loop:;
          }
        }
      }
    }
    cmd_offset += cur_seg_cmd->cmdsize;
  }
}

int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel) {
  int retval = prepend_rebindings(&_rebindings_head, rebindings, rebindings_nel);
  if (retval < 0) {
    return retval;
  }
  
  uint32_t c = _dyld_image_count();
  for (uint32_t i = 0; i < c; i++) {
    _rebind_symbols_for_image(_rebindings_head, _dyld_get_image_header(i), (intptr_t)_dyld_get_image_vmaddr_slide(i));
  }
  return 0;
}
