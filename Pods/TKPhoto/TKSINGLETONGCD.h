//
//  SINGLETONGCD.h
//
//  Copyright (c) 2014 SlowsLab. All rights reserved.
//

/*!
 * @function Singleton GCD Macro
 */
#ifndef SINGLETON_GCD
#define SINGLETON_GCD(classname)                        \
\
+ (classname *)shared##classname {                      \
\
static dispatch_once_t pred;                        \
__strong static classname * shared##classname = nil;\
dispatch_once( &pred, ^{                            \
shared##classname = [[self alloc] init]; });    \
return shared##classname;                           \
}                                                           
#endif
