//
//  OTA+SUOTA.swift
//  MultipleCardTest
//
//  Created by Siavash on 30/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation

enum SPOTA_STATUS_VALUES: Int {
    // Value zero must not be used !! Notifications are sent when status changes.
    case SRV_STARTED      = 0x01     // Valid memory device has been configured by initiator. No sleep state while in this mode
    case CMP_OK           = 0x02     // SPOTA process completed successfully.
    case SRV_EXIT         = 0x03     // Forced exit of SPOTAR service.
    case CRC_ERR          = 0x04     // Overall Patch Data CRC failed
    case PATCH_LEN_ERR    = 0x05     // Received patch Length not equal to PATCH_LEN characteristic value
    case EXT_MEM_WRITE_ERR = 0x06     // External Mem Error (Writing to external device failed)
    case INT_MEM_ERR      = 0x07     // Internal Mem Error (not enough space for Patch)
    case INVAL_MEM_TYPE   = 0x08     // Invalid memory device
    case APP_ERROR        = 0x09     // Application error
    
    // SUOTAR application specific error codes
    case IMG_STARTED      = 0x10     // SPOTA started for downloading image (SUOTA application)
    case INVAL_IMG_BANK   = 0x11     // Invalid image bank
    case INVAL_IMG_HDR    = 0x12     // Invalid image header
    case INVAL_IMG_SIZE   = 0x13     // Invalid image size
    case INVAL_PRODUCT_HDR = 0x14     // Invalid product header
    case SAME_IMG_ERR     = 0x15     // Same Image Error
    case EXT_MEM_READ_ERR = 0x16     // Failed to read from external memory device
}

enum MFSOTAState: Int {
    case writePatchLength = 1
    case writePatchData
    case writePatchEnd
    case reboot
    case patchCompleted
}

enum MFFirmwareUpdateResult {
    case isLatest
    case needsToUpdate(version: String)
    case responseError
    case otaServerFailure(error: Error)
    case checkingIsInProgress
}
enum MFFirmwareError: Error {
    case isLatest
    case responseError
    case otaServerFailure(error: Error)
}
