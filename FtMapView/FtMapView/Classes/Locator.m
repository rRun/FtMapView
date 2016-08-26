 //
//  Locator.m
//  cdoctor
//
//  Created by 何霞雨 on 16/4/13.
//  Copyright © 2016年 ft. All rights reserved.
//

#import "Locator.h"

//#import "CLPlacemark+FullNameState.h"

#define LOCATE_DISTANCE 100.0 //每隔多少距离定位一次
#define LASTLOCATION @"LASTLOCATION" //获取历史定位的key

typedef NS_ENUM(NSInteger,LocationType) {
    Location_None,//无定位
    Location_Manuel,//手动关闭定位
    Location_Duration,//自动关闭
};

@interface Locator (){
    CLGeocoder *_geocoder;//编码器
    NSTimer *_stopLocationTimer;//自动关闭定位定时器
    NSTimer *_authorizationTimer;//自动检测定时器
    
}

@property(nonatomic,assign)LocationType locationType;
@property (nonatomic,strong)CLLocationManager *locationManager;
@property (nonatomic) BOOL isReverseGeocoding; //是否正在反编码中

@end

@implementation Locator
@synthesize isStartLocation = isStartLocation;

static Locator *defaultLocator = nil;

+(Locator *)defaultLocator{
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        defaultLocator = [[self alloc] init];
        defaultLocator.isReverseGeocoding = NO;
    });
    return defaultLocator;
}

-(void)startLocation{
    if (isStartLocation) {
        return;
    }
   
    [self privateStartLocation];


    
}

-(void)privateStartLocation{
    //如果没有授权则请求用户授权
    BOOL enable = [CLLocationManager locationServicesEnabled];
    
    if (!enable) {
        [[[UIAlertView alloc]initWithTitle:@"Tip" message:@"请打开定位权限" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
        
        return;
    }
    
    BOOL authorization = NO;
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:{
            authorization = NO;
            if (!_authorizationTimer) {
                _authorizationTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(privateStartLocation) userInfo:nil repeats:YES];
            }
            
            
            if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [self.locationManager requestWhenInUseAuthorization];  //调用了这句,就会弹出允许框了
            }
            
        }
            break;
        case kCLAuthorizationStatusRestricted:{
            authorization = NO;
        }
            break;
        case kCLAuthorizationStatusDenied:{
            authorization = NO;
        }
            break;
        default:{
            authorization = YES;
        }
            break;
    }
    
    if (authorization) {
        [self.locationManager startUpdatingLocation];
        isStartLocation = YES;
        self.locationType = Location_Manuel;
        
        if (_authorizationTimer) {
            [_authorizationTimer invalidate];
            _authorizationTimer = nil;
        }
        
    }else{
        [[UIAlertView alloc]initWithTitle:@"Tip" message:@"定位权限已关闭" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    }
}

-(void)startLocation:(CGFloat)duration{
    if (isStartLocation) {
        return;
    }
    
    [self startLocation];
    if (isStartLocation) {
        if (_stopLocationTimer) {
            [_stopLocationTimer invalidate];
            _stopLocationTimer = nil;
        }
        
        _stopLocationTimer =[NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(stopLocation) userInfo:nil repeats:NO];
        
        self.locationType = Location_Duration;
    }
    
    
}

-(void)stopLocation{
    if (isStartLocation == NO) {
        return;
    }
    isStartLocation = NO;
    
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
    
    if (_stopLocationTimer) {
        [_stopLocationTimer invalidate];
        _stopLocationTimer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LOCATIONEND object:nil];
    
    
}

#pragma mark - 权限

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
                    [self.locationManager requestWhenInUseAuthorization];  //调用了这句,就会弹出允许框了.
                }
            }
            break;
        default:
            break;
    }
}

#pragma mark - CoreLocation 代理
#pragma mark 跟踪定位代理方法，每次位置发生变化即会执行（只要定位到相应位置）
//可以通过模拟器设置一个虚拟位置，否则在模拟器中无法调用此方法
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    if (isStartLocation == NO) {
        return;
    }

    CLLocation *location=[locations firstObject];//取出第一个位置
    CLLocationCoordinate2D coordinate=location.coordinate;//位置坐标
    NSLog(@"成功 定位的位置 经度：%f,纬度：%f,海拔：%f,航向：%f,行走速度：%f",coordinate.longitude,coordinate.latitude,location.altitude,location.course,location.speed);
    [self setLocationCoordinate:coordinate];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LOCATIONSUCCESS object:location];

    if (self.locationType == Location_Duration) {
        //如果不需要实时定位，使用完即使关闭定位服务
        [self stopLocation];
    }
    
    
    
}

    
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
  
    CLLocationCoordinate2D coor={
        0,0
    };
    
    self.currentLoc = coor;
    
    if (!self.isStartLocation) {
        return;
    }
    [self stopLocation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LOCATIONERROR object:error];
}
#pragma mark - setter and getter
-(void)setLocationCoordinate:(CLLocationCoordinate2D)coordinate{
    _currentLoc = coordinate;
    _lastLoction = coordinate;
    
    if (_lastLoction.latitude != 0 && _lastLoction.longitude != 0) {
        NSDictionary *locDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithDouble:_lastLoction.latitude],@"latitude",[NSNumber numberWithDouble:_lastLoction.longitude],@"longitude", nil];
        [[NSUserDefaults standardUserDefaults]setObject:locDic forKey:LASTLOCATION];
        
        //这里建议同步存储到磁盘中，但是不是必须的
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
-(CLLocationCoordinate2D)lastLoction{
    if (_lastLoction.latitude == 0 || _lastLoction.longitude == 0) {
        NSDictionary *locDic=[[NSUserDefaults standardUserDefaults] objectForKey:LASTLOCATION];
        CLLocationDegrees latitude =[[locDic objectForKey:@"latitude"] doubleValue];
        CLLocationDegrees longitude =[[locDic objectForKey:@"longitude"] doubleValue];
        CLLocationCoordinate2D coordinate={
            latitude,
            longitude
        };
        _lastLoction = coordinate;
        return _lastLoction;
    }else
        return _lastLoction;
}

#pragma mark － Geo
-(void)getCoordinateByAddress:(NSString *)address Success:(void(^)(CLPlacemark *placeInfo))success Error:(void(^)(NSError *error))fail{
    if (!_geocoder) {
        _geocoder=[[CLGeocoder alloc]init];
    }
    
    //地理编码
    [_geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        //取得第一个地标，地标中存储了详细的地址信息，注意：一个地名可能搜索出多个地址
        if (error) {
            fail(error);
        }else{
            CLPlacemark *placemark=[placemarks firstObject];
            success(placemark);
        }
    }];
}
-(void)getAddressByLocationCoordinate:(CLLocationCoordinate2D)location Success:(void(^)(CLPlacemark *placeInfo))success Error:(void(^)(NSError *error))fail{
    if (!_geocoder) {
        _geocoder=[[CLGeocoder alloc]init];
    }

    NSLog(@"反地址编码之前 location.latitude = %f , location.longitude = %f",location.latitude, location.longitude);
    
    //反地理编码
    CLLocation *clocation=[[CLLocation alloc]initWithLatitude:location.latitude longitude:location.longitude];
    
    if (_geocoder.geocoding) [_geocoder cancelGeocode];
    if(!self.isReverseGeocoding){
        __weak Locator *weakSelf = self;
        
        // 保存 Device 的现语言 (英语 法语 ，，，)
        NSMutableArray *userDefaultLanguages = [[NSUserDefaults standardUserDefaults]
                                                objectForKey:@"AppleLanguages"];
        // 强制 成 简体中文
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:@"en-US",nil]
                                                  forKey:@"AppleLanguages"];
        
        
        [_geocoder reverseGeocodeLocation:clocation completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error) {
                NSLog(@"反编码信息失败，失败原因：%@",[error localizedDescription]);
                weakSelf.isReverseGeocoding = NO;
                
                fail(error);
                
            }else{
                
                CLPlacemark *placemark=[placemarks firstObject];
//                    NSLog(@"详细信息:%@",placemark.addressDictionary);
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:placemark.addressDictionary options:NSJSONWritingPrettyPrinted error:nil];
                NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];//替换转换url时产生的\/斜杠
                NSLog(@"反编码成功:\n:%@",jsonStr);
                
//                CLLocation *location=placemark.location;//位置
//                CLRegion *region=placemark.region;//区域
//                NSDictionary *addressDic= placemark.addressDictionary;//详细地址信息字典,包含以下部分信息
//                NSString *name=placemark.name;//地名
//                NSString *thoroughfare=placemark.thoroughfare;//街道
//                NSString *subThoroughfare=placemark.subThoroughfare; //街道相关信息，例如门牌等
//                NSString *locality=placemark.locality; // 城市
//                NSString *subLocality=placemark.subLocality; // 城市相关信息，例如标志性建筑
//                NSString *administrativeArea=placemark.administrativeArea; // 州
//                NSString *subAdministrativeArea=placemark.subAdministrativeArea; //其他行政区域信息
//                NSString *postalCode=placemark.postalCode; //邮编
//                NSString *ISOcountryCode=placemark.ISOcountryCode; //国家编码
//                NSString *country=placemark.country; //国家
//                NSString *inlandWater=placemark.inlandWater; //水源、湖泊
//                NSString *ocean=placemark.ocean; // 海洋
//                NSArray *areasOfInterest=placemark.areasOfInterest; //关联的或利益相关的地标
//                NSLog(@"位置:%@,区域:%@,详细信息:%@",location,region,addressDic);
//                NSLog(@"州的全称 state = %@",[placemark fullNameState]);
                
                weakSelf.isReverseGeocoding = NO;
                success(placemark);
                
            }
            
            // 还原Device 的语言
            [[NSUserDefaults standardUserDefaults] setObject:userDefaultLanguages forKey:@"AppleLanguages"];
            
        }];
    }

}



#pragma mark - Setter and Getter

-(CLLocationManager *)locationManager{
    //定位管理器
    if (!_locationManager) {
        _locationManager=[[CLLocationManager alloc]init];
        //设置代理
        _locationManager.delegate=self;
        //设置定位精度
        _locationManager.desiredAccuracy=kCLLocationAccuracyBest;
        //定位频率,每隔多少米定位一次
        CLLocationDistance distance=LOCATE_DISTANCE;//十米定位一次
        _locationManager.distanceFilter=distance;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
            [_locationManager requestWhenInUseAuthorization];  //调用了这句,就会弹出允许框了.
        }
    }
    return _locationManager;
}
@end
