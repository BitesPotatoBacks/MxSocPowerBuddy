//
//    MIT License
//
//    Copyright (c) 2021-2022 BitesPotatoBacks
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

#if defined(__x86_64__)

#include <Foundation/Foundation.h>
#include "x86_64.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float get_cpu_active_freq(void)
{
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    size_t cycles;
    
    double magic_number = (double)info.numer / (double)info.denom;

    uint64_t first_sample_begin = mach_absolute_time();

    cycles = 262144;
    FIRST_MEASURE

    uint64_t first_sample_end = mach_absolute_time();
    double first_ns_set = (double)(first_sample_end - first_sample_begin) * magic_number;
    uint64_t last_sample_begin = mach_absolute_time();

    cycles = 131072;
    LAST_MEASURE

    uint64_t last_sample_end = mach_absolute_time();
    double last_ns_set = (double)(last_sample_end - last_sample_begin) * magic_number;
    double nanoseconds = (first_ns_set - last_ns_set);

    return (float)(131072 / nanoseconds) * 1e+3;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_active_freq(void)
{
    float cpu_freq = get_cpu_active_freq();
    float max_freq = return_cpu_turbo_freq();
    
    if (cpu_freq > max_freq)
    {
        return max_freq;
    }
    else if (cpu_freq < 800)
    {
        return 800;
    }
    else
    {
        return cpu_freq;
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSMutableArray * get_model_array(void)
{
    NSString * cpu_model;
    
    cpu_model = [NSString stringWithFormat:@"%s", get_sysctl_char(SYSCTL_CPU_MODEL)];
    cpu_model = [cpu_model stringByReplacingOccurrencesOfString:@"[@]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [cpu_model length])];
    
    return [[cpu_model componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_turbo_freq(void)
{
    NSString * machine;
    NSString * cpu_max_freq;
    
    NSDictionary * cpu_dictionary;
    NSMutableArray * cpu_model_array = get_model_array();
    
    float cpu_max_freq_turbo = 0;
    
    machine = [NSString stringWithFormat:@"%s", get_sysctl_char(SYSCTL_PRODUCT)];
    machine = [machine stringByReplacingOccurrencesOfString:@"[^a-zA-Z]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [machine length])];
    
    if ([machine isEqual:@"MacBook"])
    {
        cpu_dictionary = generate_macbook_data();
    }
    else if ([machine isEqual:@"MacBookAir"])
    {
        cpu_dictionary = generate_macbook_air_data();
    }
    else if ([machine isEqual:@"MacBookPro"])
    {
        cpu_dictionary = generate_macbook_pro_data();
    }
    else if ([machine isEqual:@"iMac"])
    {
        cpu_dictionary = generate_imac_data();
    }
    else if ([machine isEqual:@"iMacPro"])
    {
        cpu_dictionary = generate_imac_pro_data();
    }
    else if ([machine isEqual:@"Macmini"])
    {
        cpu_dictionary = generate_mac_mini_data();
    }
    else if ([machine isEqual:@"MacPro"])
    {
        cpu_dictionary = generate_mac_pro_data();
    }
    else
    {
        ERROR("system unsupported");
    }
    
    for (int i = 0; i < [cpu_model_array count]; i++)
    {
        if (!([[cpu_dictionary valueForKey:cpu_model_array[i]] floatValue] <= 0))
        {
            cpu_max_freq = [cpu_dictionary valueForKey:cpu_model_array[i]];
        }
    }
    
    if ((cpu_max_freq_turbo = [cpu_max_freq floatValue]) <= 0 && [[cpu_model_array lastObject] floatValue] > 0)
    {
        cpu_max_freq_turbo = (float)(get_sysctl_uint64(SYSCTL_CPU_MAX) * 1e-6);
    }
    
    return cpu_max_freq_turbo;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_base_freq(void)
{
    return (float)(get_sysctl_uint64(SYSCTL_CPU_RATED) * 1e-6);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void check_cpu_generation(void)
{
    NSArray * cpu_model_array = get_model_array();
    
    for (int i = 0; i < [cpu_model_array count]; i++)
    {
        if ([cpu_model_array[i] rangeOfString:@"-10"].location != NSNotFound)
        {
            WARNING("per core outputs may be less accurate on Ice Lake")
        }
    }
}

#endif