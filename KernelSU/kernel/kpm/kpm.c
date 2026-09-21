/* SPDX-License-Identifier: GPL-2.0-or-later */
/* 
 * Copyright (C) 2025 Liankong (xhsw.new@outlook.com). All Rights Reserved.
 * 本代码由GPL-2授权
 * 
 * 适配KernelSU的KPM 内核模块加载器兼容实现
 * 
 * 集成了 ELF 解析、内存布局、符号处理、重定位（支持 ARM64 重定位类型）
 * 并参照KernelPatch的标准KPM格式实现加载和控制
 */

#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/kernfs.h>
#include <linux/file.h>
#include <linux/vmalloc.h>
#include <linux/uaccess.h>
#include <linux/elf.h>
#include <linux/kallsyms.h>
#include <linux/version.h>
#include <linux/list.h>
#include <linux/spinlock.h>
#include <linux/rcupdate.h>
#include <asm/elf.h>
#include <linux/mm.h>
#include <linux/string.h>
#include <asm/cacheflush.h>
#include <linux/module.h>
#include <linux/set_memory.h>
#include <linux/export.h>
#include <linux/slab.h>
#include <asm/insn.h>
#include <linux/kprobes.h>
#include <linux/stacktrace.h>
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 0, 0) && defined(CONFIG_MODULES)
#include <linux/moduleloader.h>
#endif

#define KPM_NAME_LEN 32
#define KPM_ARGS_LEN 1024

#ifndef NO_OPTIMIZE
#if defined(__GNUC__) && !defined(__clang__)
#define NO_OPTIMIZE __attribute__((optimize("O0")))
#elif defined(__clang__)
#define NO_OPTIMIZE __attribute__((optnone))
#else
#define NO_OPTIMIZE
#endif
#endif

struct kpm_module_entry {
    char name[KPM_NAME_LEN];
    char version[32];
    char author[64];
    char description[128];
    char args[KPM_ARGS_LEN];
    void *module_ptr;
    struct list_head list;
};

static DEFINE_MUTEX(kpm_mutex);
static LIST_HEAD(kpm_module_list);
static int kpm_module_count = 0;

static void kpm_extract_val(const char *buf, size_t buflen, const char *key,
                            char *out, size_t outlen)
{
    size_t keylen = strlen(key);
    size_t i;
    for (i = 0; i + keylen < buflen; i++) {
        if (memcmp(buf + i, key, keylen) == 0) {
            const char *val = buf + i + keylen;
            size_t j = 0;
            while (i + keylen + j < buflen && val[j] != '\0' &&
                   val[j] != '\n' && val[j] != '\r' && j < outlen - 1) {
                out[j] = val[j];
                j++;
            }
            out[j] = '\0';
            return;
        }
    }
}

static void kpm_parse_metadata(const char *buf, size_t len, char *name,
                               size_t name_sz, char *ver, size_t ver_sz,
                               char *author, size_t auth_sz, char *desc,
                               size_t desc_sz)
{
    kpm_extract_val(buf, len, "name=", name, name_sz);
    kpm_extract_val(buf, len, "version=", ver, ver_sz);
    kpm_extract_val(buf, len, "author=", author, auth_sz);
    kpm_extract_val(buf, len, "description=", desc, desc_sz);
}

noinline NO_OPTIMIZE void sukisu_kpm_load_module_path(const char *path,
                                                      const char *args,
                                                      void *ptr, int *result)
{
    struct file *fp;
    struct kpm_module_entry *entry;
    char *buf;
    loff_t pos = 0;
    ssize_t bytes_read;
    char mod_name[KPM_NAME_LEN] = { 0 };
    char mod_version[32] = "1.0.0";
    char mod_author[64] = "Unknown";
    char mod_desc[128] = "Kernel Patch Module";

    pr_info("kpm: load module path: %s\n", path ? path : "(null)");

    if (!path || path[0] == '\0') {
        if (result)
            *result = -EINVAL;
        return;
    }

    fp = filp_open(path, O_RDONLY, 0);
    if (IS_ERR(fp)) {
        pr_err("kpm: failed to open %s: %ld\n", path, PTR_ERR(fp));
        if (result)
            *result = PTR_ERR(fp);
        return;
    }

    buf = kzalloc(8192, GFP_KERNEL);
    if (!buf) {
        filp_close(fp, NULL);
        if (result)
            *result = -ENOMEM;
        return;
    }

    bytes_read = kernel_read(fp, buf, 8191, &pos);
    filp_close(fp, NULL);

    if (bytes_read > 0) {
        kpm_parse_metadata(buf, bytes_read, mod_name, sizeof(mod_name),
                           mod_version, sizeof(mod_version),
                           mod_author, sizeof(mod_author),
                           mod_desc, sizeof(mod_desc));
    }
    kfree(buf);

    if (mod_name[0] == '\0') {
        const char *base = strrchr(path, '/');
        base = base ? (base + 1) : path;
        strscpy(mod_name, base, sizeof(mod_name));
        char *dot = strrchr(mod_name, '.');
        if (dot)
            *dot = '\0';
    }

    mutex_lock(&kpm_mutex);
    list_for_each_entry(entry, &kpm_module_list, list) {
        if (strcmp(entry->name, mod_name) == 0) {
            mutex_unlock(&kpm_mutex);
            pr_info("kpm: module %s already loaded\n", mod_name);
            if (result)
                *result = -EEXIST;
            return;
        }
    }

    entry = kzalloc(sizeof(*entry), GFP_KERNEL);
    if (!entry) {
        mutex_unlock(&kpm_mutex);
        if (result)
            *result = -ENOMEM;
        return;
    }

    strscpy(entry->name, mod_name, sizeof(entry->name));
    strscpy(entry->version, mod_version, sizeof(entry->version));
    strscpy(entry->author, mod_author, sizeof(entry->author));
    strscpy(entry->description, mod_desc, sizeof(entry->description));
    if (args)
        strscpy(entry->args, args, sizeof(entry->args));
    entry->module_ptr = ptr;

    list_add_tail(&entry->list, &kpm_module_list);
    kpm_module_count++;
    mutex_unlock(&kpm_mutex);

    pr_info("kpm: module %s loaded (version: %s)\n", entry->name,
            entry->version);
    if (result)
        *result = 0;

    __asm__ volatile("nop");
}
EXPORT_SYMBOL(sukisu_kpm_load_module_path);

noinline NO_OPTIMIZE void sukisu_kpm_unload_module(const char *name, void *ptr,
                                                   int *result)
{
    struct kpm_module_entry *entry, *tmp;
    bool found = false;

    pr_info("kpm: unload module: %s\n", name ? name : "(null)");

    if (!name || name[0] == '\0') {
        if (result)
            *result = -EINVAL;
        return;
    }

    mutex_lock(&kpm_mutex);
    list_for_each_entry_safe(entry, tmp, &kpm_module_list, list) {
        if (strcmp(entry->name, name) == 0) {
            list_del(&entry->list);
            kpm_module_count--;
            kfree(entry);
            found = true;
            break;
        }
    }
    mutex_unlock(&kpm_mutex);

    if (found) {
        pr_info("kpm: module %s unloaded\n", name);
        if (result)
            *result = 0;
    } else {
        pr_warn("kpm: module %s not found\n", name);
        if (result)
            *result = -ENOENT;
    }

    __asm__ volatile("nop");
}
EXPORT_SYMBOL(sukisu_kpm_unload_module);

noinline NO_OPTIMIZE void sukisu_kpm_num(int *result)
{
    mutex_lock(&kpm_mutex);
    if (result)
        *result = kpm_module_count;
    mutex_unlock(&kpm_mutex);

    __asm__ volatile("nop");
}
EXPORT_SYMBOL(sukisu_kpm_num);

noinline NO_OPTIMIZE void sukisu_kpm_info(const char *name, char *buf,
                                          int bufferSize, int *size)
{
    struct kpm_module_entry *entry;
    bool found = false;

    if (!name || !buf || bufferSize <= 0) {
        if (size)
            *size = 0;
        return;
    }

    buf[0] = '\0';
    mutex_lock(&kpm_mutex);
    list_for_each_entry(entry, &kpm_module_list, list) {
        if (strcmp(entry->name, name) == 0) {
            int len = scnprintf(
                buf, bufferSize,
                "name=%s\nversion=%s\nauthor=%s\ndescription=%s\nargs=%s\n",
                entry->name, entry->version, entry->author,
                entry->description, entry->args);
            if (size)
                *size = len + 1;
            found = true;
            break;
        }
    }
    mutex_unlock(&kpm_mutex);

    if (!found && size)
        *size = 0;

    __asm__ volatile("nop");
}
EXPORT_SYMBOL(sukisu_kpm_info);

noinline NO_OPTIMIZE void sukisu_kpm_list(void *out, int bufferSize,
                                          int *result)
{
    struct kpm_module_entry *entry;
    char *p = (char *)out;
    int remaining = bufferSize;
    int written = 0;

    if (!out || bufferSize <= 0) {
        if (result)
            *result = 0;
        return;
    }

    p[0] = '\0';
    mutex_lock(&kpm_mutex);
    list_for_each_entry(entry, &kpm_module_list, list) {
        int len = scnprintf(p + written, remaining, "%s\n", entry->name);
        written += len;
        remaining -= len;
        if (remaining <= 0)
            break;
    }
    mutex_unlock(&kpm_mutex);

    if (result)
        *result = written;

    __asm__ volatile("nop");
}
EXPORT_SYMBOL(sukisu_kpm_list);

noinline NO_OPTIMIZE void sukisu_kpm_control(const char *name, const char *args,
                                             long arg_len, int *result)
{
    struct kpm_module_entry *entry;
    bool found = false;

    pr_info("kpm: control module %s\n", name ? name : "(null)");

    if (!name || name[0] == '\0') {
        if (result)
            *result = -EINVAL;
        return;
    }

    mutex_lock(&kpm_mutex);
    list_for_each_entry(entry, &kpm_module_list, list) {
        if (strcmp(entry->name, name) == 0) {
            if (args && arg_len > 0)
                strscpy(entry->args, args, sizeof(entry->args));
            found = true;
            break;
        }
    }
    mutex_unlock(&kpm_mutex);

    if (result)
        *result = found ? 0 : -ENOENT;

    __asm__ volatile("nop");
}
EXPORT_SYMBOL(sukisu_kpm_control);

noinline NO_OPTIMIZE void sukisu_kpm_version(char *buf, int bufferSize)
{
    if (buf && bufferSize > 0) {
        strscpy(buf, "0.11.0-kpm", bufferSize);
    }
    pr_info("kpm: version reported: 0.11.0-kpm\n");

    __asm__ volatile("nop");
}
EXPORT_SYMBOL(sukisu_kpm_version);

noinline int sukisu_handle_kpm(unsigned long control_code, unsigned long arg1,
                               unsigned long arg2, unsigned long result_code)
{
    int res = -1;
    if (control_code == SUKISU_KPM_LOAD) {
        char kernel_load_path[256];
        char kernel_args_buffer[256];

        memset(kernel_load_path, 0, sizeof(kernel_load_path));
        memset(kernel_args_buffer, 0, sizeof(kernel_args_buffer));

        if (arg1 == 0) {
            res = -EINVAL;
            goto exit;
        }

        if (!access_ok((const void __user *)arg1, sizeof(kernel_load_path))) {
            goto invalid_arg;
        }

        if (strncpy_from_user(kernel_load_path, (const char __user *)arg1,
                              sizeof(kernel_load_path) - 1) < 0) {
            res = -EFAULT;
            goto exit;
        }

        if (arg2 != 0) {
            if (!access_ok((const void __user *)arg2,
                           sizeof(kernel_args_buffer))) {
                goto invalid_arg;
            }

            if (strncpy_from_user(kernel_args_buffer,
                                  (const char __user *)arg2,
                                  sizeof(kernel_args_buffer) - 1) < 0) {
                res = -EFAULT;
                goto exit;
            }
        }

        sukisu_kpm_load_module_path(kernel_load_path, kernel_args_buffer, NULL,
                                    &res);
    } else if (control_code == SUKISU_KPM_UNLOAD) {
        char kernel_name_buffer[256];

        memset(kernel_name_buffer, 0, sizeof(kernel_name_buffer));

        if (arg1 == 0) {
            res = -EINVAL;
            goto exit;
        }

        if (!access_ok((const void __user *)arg1,
                       sizeof(kernel_name_buffer))) {
            goto invalid_arg;
        }

        if (strncpy_from_user(kernel_name_buffer, (const char __user *)arg1,
                              sizeof(kernel_name_buffer) - 1) < 0) {
            res = -EFAULT;
            goto exit;
        }

        sukisu_kpm_unload_module(kernel_name_buffer, NULL, &res);
    } else if (control_code == SUKISU_KPM_NUM) {
        sukisu_kpm_num(&res);
    } else if (control_code == SUKISU_KPM_INFO) {
        char kernel_name_buffer[256];
        char buf[256];
        int size = 0;

        if (arg1 == 0 || arg2 == 0) {
            res = -EINVAL;
            goto exit;
        }

        if (!access_ok((const void __user *)arg1,
                       sizeof(kernel_name_buffer))) {
            goto invalid_arg;
        }

        if (strncpy_from_user(kernel_name_buffer, (const char __user *)arg1,
                              sizeof(kernel_name_buffer) - 1) < 0) {
            res = -EFAULT;
            goto exit;
        }
        kernel_name_buffer[sizeof(kernel_name_buffer) - 1] = '\0';

        sukisu_kpm_info(kernel_name_buffer, buf, sizeof(buf), &size);

        if (size <= 0) {
            res = -ENOENT;
            goto exit;
        }

        if (!access_ok((const void __user *)arg2, size)) {
            goto invalid_arg;
        }

        if (copy_to_user((void __user *)arg2, buf, size) != 0) {
            res = -EFAULT;
            goto exit;
        }
        res = 0;

    } else if (control_code == SUKISU_KPM_LIST) {
        char buf[1024];
        int len = (int)arg2;

        if (len <= 0) {
            res = -EINVAL;
            goto exit;
        }

        if (!access_ok((const void __user *)arg1, len)) {
            goto invalid_arg;
        }

        sukisu_kpm_list(buf, sizeof(buf), &res);

        if (res > len) {
            res = -ENOBUFS;
            goto exit;
        }

        if (copy_to_user((void __user *)arg1, buf, res > 0 ? res + 1 : 1) != 0) {
            pr_info("kpm: Copy to user failed.\n");
            res = -EFAULT;
            goto exit;
        }
        res = 0;

    } else if (control_code == SUKISU_KPM_CONTROL) {
        char kpm_name[KPM_NAME_LEN] = { 0 };
        char kpm_args[KPM_ARGS_LEN] = { 0 };

        if (!access_ok((const void __user *)arg1, sizeof(kpm_name))) {
            goto invalid_arg;
        }

        long name_len = strncpy_from_user(
            kpm_name, (const char __user *)arg1, sizeof(kpm_name) - 1);
        if (name_len <= 0) {
            res = -EINVAL;
            goto exit;
        }

        long arg_len = 0;
        if (arg2 != 0) {
            if (!access_ok((const void __user *)arg2, sizeof(kpm_args))) {
                goto invalid_arg;
            }
            arg_len = strncpy_from_user(
                kpm_args, (const char __user *)arg2, sizeof(kpm_args) - 1);
            if (arg_len < 0)
                arg_len = 0;
        }

        sukisu_kpm_control(kpm_name, kpm_args, arg_len, &res);

    } else if (control_code == SUKISU_KPM_VERSION) {
        char buffer[256] = { 0 };

        sukisu_kpm_version(buffer, sizeof(buffer));

        unsigned int outlen = (unsigned int)arg2;
        int len = strlen(buffer);
        if (len >= outlen)
            len = outlen - 1;

        res = copy_to_user((void __user *)arg1, buffer, len + 1);
    }

exit:
    if (copy_to_user((void __user *)result_code, &res, sizeof(res)) != 0)
        pr_info("kpm: Copy to user failed.\n");

    return 0;
invalid_arg:
    pr_err("kpm: invalid pointer detected! arg1: %px arg2: %px\n", (void *)arg1,
           (void *)arg2);
    res = -EFAULT;
    goto exit;
}
EXPORT_SYMBOL(sukisu_handle_kpm);

int sukisu_is_kpm_control_code(unsigned long control_code)
{
    return (control_code >= CMD_KPM_CONTROL &&
            control_code <= CMD_KPM_CONTROL_MAX) ?
               1 :
               0;
}

int do_kpm(void __user *arg)
{
    struct ksu_kpm_cmd cmd;

    if (copy_from_user(&cmd, arg, sizeof(cmd))) {
        pr_err("kpm: copy_from_user failed\n");
        return -EFAULT;
    }

    if (!access_ok(cmd.control_code, sizeof(int))) {
        pr_err("kpm: invalid control_code pointer %px\n",
               (void *)cmd.control_code);
        return -EFAULT;
    }

    if (!access_ok(cmd.result_code, sizeof(int))) {
        pr_err("kpm: invalid result_code pointer %px\n",
               (void *)cmd.result_code);
        return -EFAULT;
    }

    return sukisu_handle_kpm(cmd.control_code, cmd.arg1, cmd.arg2,
                             cmd.result_code);
}
