//
//  AFNetworking-Constants.h
//
//  Created by Sam Krishna on 4/10/12.

#ifndef AFNetworking_Constants_h
#define AFNetworking_Constants_h

//
// ARC on iOS 4 and 5 
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0

#define af_weak   weak
#define __af_weak __weak

#else

#define af_weak   unsafe_unretained
#define __af_weak __unsafe_unretained

#endif



#endif
