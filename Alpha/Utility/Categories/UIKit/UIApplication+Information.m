//
//  UIApplication+Information.m
//  Alpha
//
//  Created by Dal Rupnik on 29/11/2016.
//  Copyright © 2016 Unified Sense. All rights reserved.
//

#import <sys/types.h>
#import <sys/sysctl.h>

#import <mach/mach.h>
#import <mach/mach_host.h>

#import "UIApplication+Information.h"

@import UIKit;


/// -->

#include <mach/mach.h>


static inline int copySafely(const void* restrict const src, void* restrict const dst, const int byteCount)
{
    vm_size_t bytesCopied = 0;
    kern_return_t result = vm_read_overwrite(mach_task_self(),
                                             (vm_address_t)src,
                                             (vm_size_t)byteCount,
                                             (vm_address_t)dst,
                                             &bytesCopied);
    if(result != KERN_SUCCESS)
        {
        return 0;
        }
    return (int)bytesCopied;
}

static char g_memoryTestBuffer[10240];
static inline bool isMemoryReadable(const void* const memory, const int byteCount)
{
    const int testBufferSize = sizeof(g_memoryTestBuffer);
    int bytesRemaining = byteCount;
    
    while(bytesRemaining > 0)
        {
        int bytesToCopy = bytesRemaining > testBufferSize ? testBufferSize : bytesRemaining;
        if(copySafely(memory, g_memoryTestBuffer, bytesToCopy) != bytesToCopy)
            {
            break;
            }
        bytesRemaining -= bytesToCopy;
        }
    return bytesRemaining == 0;
}
/// <--

@implementation UIApplication (Information)

- (long long)alpha_memorySize {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    if (kerr == KERN_SUCCESS) {
        return (long long)info.resident_size;
    }
    else {
        return -1;
    }
}

- (NSUInteger)alpha_threadCount {
    mach_msg_type_number_t count;
    thread_act_array_t list;
    
    task_threads(mach_task_self(), &list, &count);
    
    return  count;
}

- (float)alpha_cpuUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    if (thread_count > 0) {
        stat_thread += thread_count;
    }
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    
    //// -->
    mach_msg_type_number_t thread_id_info_count;
    thread_identifier_info_t id_info_th;
    //// <--
    for (j = 0; j < thread_count; j++) {
        
        ////// -->
        
        thread_id_info_count = THREAD_IDENTIFIER_INFO_COUNT;
        kr = thread_info(thread_list[j], THREAD_IDENTIFIER_INFO, (thread_info_t)thinfo, &thread_id_info_count);
        
        if (kr != KERN_SUCCESS)
            {
            return -1;
            }
        
        id_info_th = (thread_identifier_info_t)thinfo;
        
        dispatch_queue_t* dispatch_queue_ptr = (dispatch_queue_t*)id_info_th->dispatch_qaddr;
        
        
        
        if(isMemoryReadable(dispatch_queue_ptr, sizeof(*dispatch_queue_ptr))&& isMemoryReadable(id_info_th, sizeof(*id_info_th)))
            {
            dispatch_queue_t dispatch_queue = *dispatch_queue_ptr;
            const char * label = dispatch_queue_get_label(dispatch_queue);
            
            if (label && strcmp(label, "yzt.alpha.thread") == 0) {
                continue;
            }
            }
        ////// <----
        
        
        
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
        
        if (kr != KERN_SUCCESS)
        {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

- (BOOL)alpha_isRunningTests {
    NSDictionary* environment = [[NSProcessInfo processInfo] environment];
    NSString* injectBundle = environment[@"XCInjectBundle"];
    return [[injectBundle pathExtension] isEqualToString:@"xctest"];
}

@end
