//
//  CPUInfoSnapshot.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 9/3/2025.
//


import Foundation
import Darwin  // For Mach APIs like mach_host_self()

// Define HOST_VM_INFO64_COUNT if not already in scope.
private let HOST_VM_INFO64_COUNT: mach_msg_type_number_t =
    mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

// MARK: - CPU Usage

fileprivate struct CPUInfoSnapshot: Sendable {
    var user: UInt32
    var system: UInt32
    var idle: UInt32
    var nice: UInt32
}

@MainActor
fileprivate struct Static {
    // The shared mutable state is now isolated to the main actor.
    static var oldSnapshot: CPUInfoSnapshot? = nil
}

// Use an NSLock to synchronize access to Static.oldSnapshot.
private let cpuSnapshotLock = NSLock()

@MainActor
public func getSystemCPUUsage() -> CGFloat {
    guard let (userTicks, systemTicks, idleTicks, niceTicks) = hostCPULoadInfo() else {
        return 0
    }
    
    let newSnapshot = CPUInfoSnapshot(user: userTicks,
                                      system: systemTicks,
                                      idle: idleTicks,
                                      nice: niceTicks)
    
    cpuSnapshotLock.lock()
    let old = Static.oldSnapshot
    Static.oldSnapshot = newSnapshot
    cpuSnapshotLock.unlock()
    
    guard let old = old else {
        return 0
    }
    
    let userDiff   = newSnapshot.user   - old.user
    let systemDiff = newSnapshot.system - old.system
    let idleDiff   = newSnapshot.idle   - old.idle
    let niceDiff   = newSnapshot.nice   - old.nice
    let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
    
    if totalTicks > 0 {
        let usedTicks = userDiff + systemDiff + niceDiff
        return CGFloat(usedTicks) / CGFloat(totalTicks) * 100.0
    } else {
        return 0
    }
}

fileprivate func hostCPULoadInfo() -> (UInt32, UInt32, UInt32, UInt32)? {
    var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
    let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
    defer { hostInfo.deallocate() }
    
    let result = withUnsafeMutablePointer(to: &hostInfo.pointee) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
        }
    }
    if result == KERN_SUCCESS {
        let data = hostInfo.move()
        return (data.cpu_ticks.0, data.cpu_ticks.1, data.cpu_ticks.2, data.cpu_ticks.3)
    }
    return nil
}

// MARK: - Memory Usage

@MainActor
public func getSystemMemoryUsage() -> CGFloat {
    var stats = vm_statistics64()
    var count = HOST_VM_INFO64_COUNT
    
    let result = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
        }
    }
    guard result == KERN_SUCCESS else {
        return 0
    }
    
    // Use getpagesize() for a concurrency-safe page size.
    let pageSize = UInt64(getpagesize())
    let totalBytes = ProcessInfo.processInfo.physicalMemory
    let freeBytes = UInt64(stats.free_count) * pageSize
    let usedBytes = totalBytes - freeBytes
    let usagePercent = Double(usedBytes) / Double(totalBytes) * 100.0
    return CGFloat(usagePercent)
}
