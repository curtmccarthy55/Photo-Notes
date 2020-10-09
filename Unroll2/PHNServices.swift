//
//  PHNServices.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/2/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

public typealias PHNCompletionHandler = ([Any]?) -> Void
public typealias PHNImageCompletionHandler = (UIImage?) -> Void

/// Handles image fetch/cache/delete, album save, and memory reporting.
class PHNServices: NSObject {
    //MARK: - Properties
    
    static let sharedInstance = PHNServices()
    
    var cache: PHNCache = PHNCache()
    var fileSerializer = PHNFileSerializer()
    var debug_memoryReportingTimer: Timer? //was NSTimer
    
    //MARK:  - User Read / Write
    
    func loadUser() {
        
    }
    
    //MARK: - Image Fetch and Delete
    
    func fetchImageWithName(_ name: String, asData: Bool, handler: PHNImageCompletionHandler?) {
        if let image = cache.object(forKey: name as NSString) {
            handler?(image)
        } else {
            var returnImage: UIImage?
            if asData {
                returnImage = fileSerializer.readImageFromRelativePath(name)
            } else {
                returnImage = fileSerializer.readObjectFromRelativePath(name) as? UIImage
            }
            
            if let confirmedImage = returnImage {
                cache.setObject(confirmedImage, forKey: name as NSString)
            } else {
                returnImage = UIImage(named: "No Image")
            }
            
            handler?(returnImage)
        }
    }
    
    func deleteImageFrom(photoNote: PhotoNote) {
        if cache.object(forKey: photoNote.fileName as NSString) != nil {
            cache.removeObject(forKey: photoNote.fileName as NSString)
        }
        
        if cache.object(forKey: photoNote.thumbnailFileName as NSString) != nil {
            cache.removeObject(forKey: photoNote.thumbnailFileName as NSString)
        }
        
        fileSerializer.deleteImageWithFileName(photoNote.fileName)
    }
    
    func removeImageFromCache(_ photoNote: PhotoNote?) {
        guard let photoNote = photoNote else { return }
        
        if cache.object(forKey: photoNote.fileName as NSString) != nil {
            cache.removeObject(forKey: photoNote.fileName as NSString)
        }
        
        if cache.object(forKey: photoNote.thumbnailFileName as NSString) != nil {
            cache.removeObject(forKey: photoNote.thumbnailFileName as NSString)
        }
    }
    
    func fetchImage(photoNote: PhotoNote, handler: PHNImageCompletionHandler?) {
        return fetchImageWithName(photoNote.fileName, asData: true, handler: handler)
    }
    
    func fetchThumbnailForImage(photoNote: PhotoNote, handler: PHNImageCompletionHandler?) {
        return fetchImageWithName(photoNote.thumbnailFileName, asData: false, handler: handler)
    }
    
    //MARK: - File Save
    
    @discardableResult
    func saveApplicationData() -> Bool {
        let savedAlbums = PHNAlbumManager.sharedInstance.save()
        return savedAlbums
    }
}
    
extension PHNServices {
    //MARK: - Memory Reporting
    func beginReportingMemoryToConsole(withInterval interval: TimeInterval) {
        if debug_memoryReportingTimer != nil {
            endReportingMemoryToConsole()
        }
        
        memoryReportingTic()
        
        debug_memoryReportingTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(memoryReportingTic), userInfo: nil, repeats: true)
    }
    
    func endReportingMemoryToConsole() {
        debug_memoryReportingTimer?.invalidate()
        debug_memoryReportingTimer = nil
    }

    @objc func memoryReportingTic() {
        reportMemoryToConsole(withReferrer: "Memory Report Loop")
    }
    
    #if !DEBUG
    
    func reportMemoryToConsole(withReferrer: String) {
        var kerrBasicInfo = mach_task_basic_info()
        let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride/MemoryLayout<natural_t>.stride
        var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)
        
        let kerrBasic: kern_return_t = withUnsafeMutablePointer(to: &kerrBasicInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerrBasic == KERN_SUCCESS {
            print("Memory in use (in bytes): \(kerrBasicInfo.resident_size)")
            /* In Progress: Swift iteration of success case NSLog from commented out Obj-C method below.
            print("∆•∆ \(withReferrer) : \n resident_size: \(String(format: "%.2f", Float(kerrBasicInfo.resident_size/(1024*1024)))) MB \n private alloc: \(String(format:"%.2f", Float(kerrBasicInfo.virtual_size/(1024*1024)))) MB free: \(String(format: "%.2f", Float(kerrMemInfo.total_palloc/(1024*1024))))")
            print(String(format: """
                ∆•∆ %@ : \n\ resident_size: %.2f MB virtual_size: %.2f MB\n\
            private alloc: %.2f MB free: %.2f MB\n\
            shared alloc: %.2f MB free: %.2f MB""",
            withReferrer, (float)kerBasicInfo.resident_size/(1024.f*1024.f), (float)kerBasicInfo.virtual_size/(1024.f*1024.f),
            (float)kerMemInfo.total_palloc/(1024.f*1024.f), (float)kerMemInfo.total_pfree/(1024.f*1024.f),
            (float)kerMemInfo.total_salloc/(1024.f*1024.f), (float)kerMemInfo.total_sfree/(1024.f*1024.f) ))
*/
        } else {
            print("Error with task_info(): " +
                (String(cString: mach_error_string(kerrBasic), encoding: String.Encoding.ascii) ?? "unknown error"))
        }
    }
    
    #else
    /// If not in debug mode, lets collect less information & by default not print to console, print to crash reporting framework
    func reportMemoryToConsole(withReferrer: String) {
        var kerrBasicInfo = mach_task_basic_info()
        let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride/MemoryLayout<natural_t>.stride
        var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)
        
        let kerrBasic: kern_return_t = withUnsafeMutablePointer(to: &kerrBasicInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerrBasic == KERN_SUCCESS {
            print("Memory in use (in bytes): \(kerrBasicInfo.resident_size)")
            
            /* In Progress: Swift iteration of success case NSLog from commented out Obj-C method below.
             print("∆•∆ \(referrer) : \n resident_size: \(String(format: "%.2f", Float(kerrBasicInfo.resident_size/(1024*1024)))) MB \n private alloc: \(String(format:"%.2f", Float(kerrBasicInfo.virtual_size/(1024*1024)))) MB free: \(String(format: "%.2f", Float(kerrMemInfo.total_palloc/(1024*1024))))")
             print(String(format: """
             ∆•∆ %@ : \n\ resident_size: %.2f MB virtual_size: %.2f MB\n\
             private alloc: %.2f MB free: %.2f MB\n\
             shared alloc: %.2f MB free: %.2f MB""",
             withReferrer, (float)kerBasicInfo.resident_size/(1024.f*1024.f), (float)kerBasicInfo.virtual_size/(1024.f*1024.f),
             (float)kerMemInfo.total_palloc/(1024.f*1024.f), (float)kerMemInfo.total_pfree/(1024.f*1024.f),
             (float)kerMemInfo.total_salloc/(1024.f*1024.f), (float)kerMemInfo.total_sfree/(1024.f*1024.f) ))
             */
        } else {
            print("Error with task_info(): " +
                (String(cString: mach_error_string(kerrBasic), encoding: String.Encoding.ascii) ?? "unknown error"))
        }
    }
    #endif
    /*
#ifdef DEBUG
- (void)reportMemoryToConsoleWithReferrer:(NSString *)referrer { //cjm 09/05
    struct task_basic_info kerBasicInfo;
    mach_msg_type_number_t kerBasicSize = sizeof(kerBasicInfo);
    kern_return_t kerBasic = task_info(mach_task_self(),
                                       TASK_BASIC_INFO,
                                       (task_info_t)&kerBasicInfo,
                                       &kerBasicSize);

    struct task_kernelmemory_info kerMemInfo;
    mach_msg_type_number_t kerMemSize = sizeof(kerMemInfo);
    kern_return_t kerMem = task_info(mach_task_self(),
                                     TASK_KERNELMEMORY_INFO,
                                     (task_info_t)&kerMemInfo,
                                     &kerMemSize);

    if(kerBasic == KERN_SUCCESS && kerMem == KERN_SUCCESS) {
        NSLog(@"∆•∆ %@ : \n\
              resident_size: %.2f MB virtual_size: %.2f MB\n\
              private alloc: %.2f MB free: %.2f MB\n\
              shared alloc: %.2f MB free: %.2f MB",
                referrer, (float)kerBasicInfo.resident_size/(1024.f*1024.f), (float)kerBasicInfo.virtual_size/(1024.f*1024.f),
                (float)kerMemInfo.total_palloc/(1024.f*1024.f), (float)kerMemInfo.total_pfree/(1024.f*1024.f),
                (float)kerMemInfo.total_salloc/(1024.f*1024.f), (float)kerMemInfo.total_sfree/(1024.f*1024.f));

    } else {
        NSLog(@"∆•∆ %@ : Error with task_info(): %s", referrer, mach_error_string(kerBasic));
    }
}
#else
//if not in debug mode, lets collect less information & by default not print to console, print to crash reporting framework
- (void)reportMemoryToConsoleWithReferrer:(NSString *)referrer
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
    TASK_BASIC_INFO,
    (task_info_t)&info,
    &size);
    
    if(kerr == KERN_SUCCESS)
    NSLog(@"∆•∆ %@ : resident_size: %.2f MB virtual_size: %.2f mb", referrer, (float)info.resident_size/(1024.f*1024.f), (float)info.virtual_size/(1024.f*1024.f));
    else
    NSLog(@"∆•∆ %@ : Error with task_info(): %s", referrer, mach_error_string(kerr));
}
#endif
 */
}

