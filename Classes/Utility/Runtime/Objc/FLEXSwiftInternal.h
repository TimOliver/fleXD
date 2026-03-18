//
//  FLEXSwiftInternal.h
//  FLEX
//
//  Created by Tanner Bennett on 10/28/21.
//  Copyright © 2021 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// @return \c YES if the given object or class is a Swift object or class, \c NO otherwise.
BOOL FLEXIsSwiftObjectOrClass(id objOrClass);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
