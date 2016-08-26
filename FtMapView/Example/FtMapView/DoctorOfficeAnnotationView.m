//
//  DoctorOfficeAnnotationView.m
//  FtMapView
//
//  Created by 何霞雨 on 16/8/26.
//  Copyright © 2016年 hexy. All rights reserved.
//

#import "DoctorOfficeAnnotationView.h"

@implementation DoctorOfficeAnnotationView{
    UIImage *selectImage;
    UIImage *unselectImage;
}

- (void)prepareForReuse{
    [super prepareForReuse];
    //init
    if (!selectImage) {
        selectImage = [UIImage imageNamed:@"位置（选中）"];
    }
    
    if (!unselectImage) {
        unselectImage = [UIImage imageNamed:@"位置（未选中）"];
    }
    
    self.canShowCallout = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];
    //init
    
    if (selected) {
        self.image = selectImage;
    }else
        self.image = unselectImage;
}
@end
