//
//  Constant.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import UIKit

struct Constant {
  
  struct Strings {
    static let defaultDispatchQueueLabel = "com.maxwellforest.rxbluetoothkit.timer"
  }
  
  struct FirmwareUpdate {
    // When the batter level is below 10%. The user won't be able to update the firmware
    static let kMinimumBatteryLevelForFirmwareUpdate = 10
    static let kMFSFirmwareUpdateErrorDomain = "MFSFirmwareUpdateErrorDomain"
    static let kFirmwareLastUpdateCheckedDateKey = "mfs_wallet_firmware_last_update_checked_date"
    static let kFirmwareUpdateAvailableKey = "mfs_wallet_is_firmware_update_available"
    static let kFirmwareVersionKey = "mfs_wallet_firmware_version_key"
    static let kFirmwareUpdateFailedCountKey = "mfs_wallet_firmware_failed_count_key"
    static let kFirmwareUpdateIsCardFaultyKey = "mfs_wallet_firmware_is_card_faulty_key"
    static let kCachedFirmwareFilename = "dialog_firmware_iso.img"
    static let otaURL = "https://updates.safedome.com/check/safedome"
    static let otaShuffledText = """
~BDhLy8^G!G"iLk:PA8Cpo{&T93|<8J0?MA@vLD32|tSySVoQsHIOatmm)qSQJp?tjb}VFK3Fp&Daa"D|KErw3MwP"vn$EQ24saE9kC57iVP2EyOb3D:ram37ZJ^Y80%UV&YAQIApvPr4Q~Z*Jcjn9f:kypvOA1m$*eQ&?NB&l}5"4!wcDvnc{>MyjmzZ>YwMKBZ#CUOpw>OGEPNoJ+RXM89vnwIhUP>v{p$%M$iPR:A?bG3Ophev8kpn7IjG)UMWk<O9S9EeX5btDu_Afyn35z:g0H%|aFyj"6Hy*2rV+$*}2&*HZe4h)nB_ag7IUIp2tF#$bo|P&T|5pC@ioM(SjZpSdp_^P:mu?%&T(|8M62it4mu@Ffeu*6gA$<*MdsjxeO!$YxTG^9Ut9dF7C60D.v4<~nvPiJ%N4_|BIj*+A0unQnO7!6&B*BM6Q<A!8csSlA1hLQne8OWZ"ri0&<Awem!Idrb3kuH_c{wA5u(?OjA>:K%kNdKK53NOB3R7L?awjBzCHl~AWNP0t@qIZA!?eC>hCLT|b"1nQkAZw~phA03):C5#yX>gF5)@!pVPIb%(S6aDl{Dc6z"Sq3YP8w{cY&I4U~{kO5g1"m@rKlPHc5t1XM1fThPKYH2?Q0jFMvSmtZ>9f+OT5pc:VZ6bfSnGsR@UOr&CGVME72GW)J_7wyZEf}%H&<PR!hsL!+YewYKaUpY*W9ouWaA<<YslOsA!DUU(:D730+iEBc":"Lr2O!B2ld^saf$!uH$8w!X&jf:Y+~_K2Qg"83cIRWoEZoZB+YPAX?>Pyuti~h+^"Be51-g@_)q(<{k5xm64UNzO_T6ZCLtqF:qNp&INz9G6v!idcYzpmX30+YUwZs??hqEfHokAkx><V0uIFkw3nCjzA%uz7kR{(WT:S(7DX7"pbF5XEltREq!e*>yMDHRod%kBY1QDlOPVy:UE$*V>@s&d^Q>*5pOlt_V!
"""
    
    // Interval when the firmware update will fail due to a time out
    static let kFirmwareUpdateTimeOutInterval = 90
    
    static let kChunkSize = 20
  }
  struct PackageSizes {
    // sizeof(MFSManufacturerData) pads the length so use this instead
    static let kSizeofMFSManufacturerData: CUnsignedLong = 3
    // sizeof(MFSConnectionParameters) pads the length so use this instead
    static let kSizeofMFSConnectionParameters: CUnsignedLong = 8
    // sizeof(MFSFSMParameters) pads the length so use this instead
    static let kSizeofMFSFSMParameters: CUnsignedLong = 11
    // sizeof(MFSMACAddress) pads the length so use this instead
    static let kSizeofMFSMACAddress: CUnsignedLong = 6
    // sizeof(MFSFindMonitorParameters) pads the length so use this instead
    static let kSizeofMFSFindMonitorParameters: CUnsignedLong = 1
  }
}

