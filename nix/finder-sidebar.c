#include <CoreServices/CoreServices.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

static int contains(LSSharedFileListRef list, CFURLRef target) {
    CFArrayRef items = LSSharedFileListCopySnapshot(list, NULL);
    if (!items) return -1;
    CFStringRef targetPath = CFURLCopyFileSystemPath(target, kCFURLPOSIXPathStyle);
    int found = 0;
    for (CFIndex i = 0; i < CFArrayGetCount(items); i++) {
        LSSharedFileListItemRef item = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(items, i);
        CFURLRef url = LSSharedFileListItemCopyResolvedURL(
            item, kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes, NULL);
        if (!url) continue;
        CFStringRef path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
        found = path && CFEqual(path, targetPath);
        if (path) CFRelease(path);
        CFRelease(url);
        if (found) break;
    }
    CFRelease(targetPath);
    CFRelease(items);
    return found;
}

int main(int argc, char **argv) {
    int check = argc > 1 && strcmp(argv[1], "--check") == 0;
    int first = check ? 2 : 1;
    if (argc <= first) {
        fprintf(stderr, "Usage: finder-sidebar [--check] /path/to/folder ...\n");
        return 1;
    }
    for (int i = first; i < argc; i++) {
        struct stat info;
        if (argv[i][0] != '/' || stat(argv[i], &info) != 0 || !S_ISDIR(info.st_mode)) {
            fprintf(stderr, "Not an existing absolute folder: %s\n", argv[i]);
            return 1;
        }
    }
    LSSharedFileListRef list = LSSharedFileListCreate(NULL, kLSSharedFileListFavoriteItems, NULL);
    if (!list) {
        fprintf(stderr, "Cannot access Finder sidebar favorites.\n");
        return 1;
    }
    int result = 0;
    for (int i = first; i < argc; i++) {
        CFURLRef url = CFURLCreateFromFileSystemRepresentation(
            NULL, (const UInt8 *)argv[i], strlen(argv[i]), true);
        if (!url) {
            result = 1;
            break;
        }
        int found = contains(list, url);
        if (found == 0 && !check) {
            LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(
                list, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
            if (item) CFRelease(item);
            found = item ? contains(list, url) : -1;
        }
        if (found != 1) {
            fprintf(stderr, "Cannot verify Finder sidebar folder: %s\n", argv[i]);
            result = 1;
        }
        CFRelease(url);
    }
    CFRelease(list);
    return result;
}
