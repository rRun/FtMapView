//
//  Locator.h
//  cdoctor
//
//  Created by 何霞雨 on 16/4/13.
//  Copyright © 2016年 ft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#define LOCATIONSUCCESS @"locationsuccess" //定位成功通知
#define LOCATIONERROR @"locationerror" //定位失败通知
#define LOCATIONEND @"locationend" //定位关闭

@interface Locator : NSObject<CLLocationManagerDelegate>

@property (nonatomic,assign)CLLocationCoordinate2D currentLoc;//当前定位坐标
@property (nonatomic,assign)CLLocationCoordinate2D lastLoction;//上次定位成功的坐标
@property (nonatomic,assign) BOOL isStartLocation;//是否在定位中

@property (nonatomic,strong)NSString *NoAuthorizationTip;
+(Locator *)defaultLocator;

//控制定位
-(void)startLocation;//手动
-(void)stopLocation;

-(void)startLocation:(CGFloat)duration;//自动关闭定位

//geo或则反geo
-(void)getCoordinateByAddress:(NSString *)address Success:(void(^)(CLPlacemark *placeInfo))success Error:(void(^)(NSError *error))fail;
-(void)getAddressByLocationCoordinate:(CLLocationCoordinate2D)location Success:(void(^)(CLPlacemark *placeInfo))success Error:(void(^)(NSError *error))fail;

@end
