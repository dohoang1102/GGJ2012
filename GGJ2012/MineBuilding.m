//
//  MineBuilding.m
//  GGJ2012
//
//  Created by Peter Hrincar on 1/28/12.
//  Copyright (c) 2012 Hyperbolic Magnetism. All rights reserved.
//

#import "MineBuilding.h"
#import "MapModel.h"
#import "Capsule.h"
#import "Tile.h"

const int cMineLight = 150;
const int cMineLightRadius = 5;

@implementation MineBuilding {
    ccTime lastTimeMineProducedCapsule;
    CapsuleComponents capsuleComponents;
}

const ccTime timeScheduleInterval = 1; // in seconds
const ccTime mineTimeScheduleInterval = 2; // in seconds, when mine produced capsule

-(id)initWithGID:(unsigned int)initGID andGridPos:(CGPoint)initGridPos  {
    
    if (self=[super initWithGID:initGID andGridPos:initGridPos]) {	
        
        CapsuleComponentType capsuleComponentType;
        
        switch (self.gid) {
            case BuildingTypeMineWater:
                capsuleComponentType = CapsuleComponentTypeWater;
                break;
                
            case BuildingTypeMineFire:
                capsuleComponentType = CapsuleComponentTypeFire;
                break;
                
            case BuildingTypeMineEarth:
                capsuleComponentType = CapsuleComponentTypeEarth;
                break;
                
            case BuildingTypeMineWind:
                capsuleComponentType = CapsuleComponentTypeWind;
                break;
                
            default:
                capsuleComponentType = CapsuleComponentTypeEmpty;
                break;
                
        }
        
        capsuleComponents.component0 = capsuleComponentType;
        capsuleComponents.component1 = capsuleComponentType;
        capsuleComponents.component2 = capsuleComponentType;
        
        [self schedule:@selector(calc:) interval:timeScheduleInterval];
        lastTimeMineProducedCapsule = 0;
        
        self.light = cMineLight;
        self.lightRadius = cMineLightRadius;
    }
    return self;    
}

#pragma mark - Helpers

- (Capsule*)createCapsule {
    
    Capsule *capsule = [[Capsule alloc] initWithComponents:capsuleComponents];

    return capsule;
}

#pragma mark - Schedule

- (void)calc:(ccTime)dt {
    
    lastTimeMineProducedCapsule += dt;
    if (lastTimeMineProducedCapsule > mineTimeScheduleInterval) {
        
        lastTimeMineProducedCapsule = 0;
        // TODO create capsule
        
        CGPoint spawnGridPos =  CGPointMake(self.gridPos.x + 1, self.gridPos.y);
        
        if ([[MapModel sharedMapModel] tileAtGridPos:spawnGridPos].isFree) {
            Capsule *capsule = [self createCapsule];
            [[MapModel sharedMapModel] tileAtGridPos:spawnGridPos].capsule = capsule;
            [capsule spawnAtGridPos:spawnGridPos];
            
            [[MapModel sharedMapModel].mainLayer.capsuleSpriteBatchNode addChild:capsule];
        }
    }
}

#pragma mark - Dealloc

- (void)destroy {
    
    [self unschedule:@selector(nextCalc:)];
}


@end
