//
//  DoctorOfficeAnnotation.m
//  FtMapView
//
//  Created by 何霞雨 on 16/8/26.
//  Copyright © 2016年 hexy. All rights reserved.
//

#import "DoctorOfficeAnnotation.h"

@interface DoctorOfficeAnnotation () {
    NSString * _name;
}

@end
@implementation DoctorOfficeAnnotation

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _name = [dictionary objectForKey:@"name"];
        NSDictionary * coordinateDictionary = [dictionary objectForKey:@"coordinates"];
        self.coordinate = CLLocationCoordinate2DMake([[coordinateDictionary objectForKey:@"latitude"] doubleValue], [[coordinateDictionary objectForKey:@"longitude"] doubleValue]);
    }
    return self;
}

- (NSString *)title {
    return self.description;
}

- (NSString *)description {
    return _name;
}

@end
