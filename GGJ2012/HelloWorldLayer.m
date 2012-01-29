//
//  HelloWorldLayer.m
//  GGJ2012
//
//  Created by Jan Ilavsky on 1/26/12.
//  Copyright (c) 2012 Hyperbolic Magnetism. All rights reserved.
//

#import "HelloWorldLayer.h"
#import "MapModel.h"
#import "Capsule.h"
#import "Creeper.h"
#import "Lightning.h"

@implementation HelloWorldLayer {
    
    CCTMXTiledMap *map;
}
@synthesize capsuleSpriteBatchNode;

- (id)init {

    self = [super init];

    if (self) {
        
		map = [CCTMXTiledMap tiledMapWithTMXFile:@"Map0.tmx"];
        
        [MapModel sharedMapModel].mainLayer = self;
        [[MapModel sharedMapModel] setMap:map];
        
		[self addChild:map];        
		
        
        // Load sprites list
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:
         @"Sprites.plist"];
        
        capsuleSpriteBatchNode = [CCSpriteBatchNode 
                                          batchNodeWithFile:@"Sprites.png"];
        
        
        [self addChild:capsuleSpriteBatchNode];
        
        Lightning *hh = [[Lightning alloc] initWithStartPos:CGPointMake(0, 0) endPos:CGPointMake(1, 0)];
        
	}
	return self;
}

@end
