//
//  MapModel.m
//  GGJ2012
//
//  Created by Peter Hrincar on 1/27/12.
//  Copyright (c) 2012 Hyperbolic Magnetism. All rights reserved.
//

#import "MapModel.h"
#import "Tile.h"
#import "TowerBuilding.h"
#import "MineBuilding.h"

@implementation MapModel {
    
    __strong Tile **tiledMapArray;
    
    CCTMXTiledMap *map;
    CCTMXLayer *tiledLayer;
}

@synthesize map;
@synthesize mainLayer;

#pragma mark - Constants

const int LUMINOSITY_RADIUS = 5;

#pragma mark - Singleton

static MapModel *sharedMapModel = nil;

+ (MapModel*)sharedMapModel {
    if (!sharedMapModel) {
        sharedMapModel = [[MapModel alloc] init];
    }
    return sharedMapModel;
}



#pragma mark - Helpers

- (void)freeMap {
    if (map) {
        
        for (int i = 0; i < map.mapSize.width; i++) {
            for (int j = 0; j < map.mapSize.height; j++) {
                tiledMapArray[i + (j* (int)map.mapSize.width)] = nil;
            }
        }
        free(tiledMapArray);        
    }
    map = nil;
}

- (int)calculateLightFromLight:(int)light atDistance:(CGPoint)distance {
    // TODO slow square root
    return (int) round(light * MAX(0, (1 - sqrt(distance.x*distance.x + distance.y*distance.y) / LUMINOSITY_RADIUS)));
}

- (BOOL)outOfMap:(CGPoint)point {
    
    return (point.x < 0 || point.y < 0 || point.x >= map.mapSize.width || point.y >= map.mapSize.height) ;
}

#pragma mark - Getters

- (CGPoint)tileCenterPositionForGripPos:(CGPoint)gridPos {
    return CGPointMake( (gridPos.x + 0.5) * self.tileSize.width, (map.mapSize.height - gridPos.y - 0.5) * self.tileSize.height);
}

- (CGSize)tileSize {
    if (map) {
        return map.tileSize;
    } else {
        return CGSizeMake(0, 0);
    }
    
}


#pragma mark - Setters

- (void)setMap:(CCTMXTiledMap*)newMap {
    
    [self freeMap];

    map = newMap;
    
    tiledMapArray =  (__strong Tile **)calloc(sizeof(Tile *), map.mapSize.width * map.mapSize.height);
    tiledLayer = [map layerNamed:@"BG"];
    CCTMXLayer *buildinglayer = [map layerNamed:@"Buildings"];
    
    NSMutableArray* buildings = [[NSMutableArray alloc] init];
    
    for (int j = 0; j < map.mapSize.height; j++) {
        for (int i = 0; i < map.mapSize.width; i++) {
            
            tiledMapArray[i + (j* (int)map.mapSize.width)] = [[Tile alloc] initWithGID:[tiledLayer tileGIDAt:ccp(i,j)]];           
            tiledMapArray[i + (j* (int)map.mapSize.width)].pos = CGPointMake(i, j);

            unsigned int gidBuiding =  [buildinglayer tileGIDAt:ccp(i,j)];
            
            [tiledLayer setCornerIntensitiesForTile:ccc4(0, 0, 0, 0) x:i y:j];
            
            if (gidBuiding) {
                Building* building = [Building createBuildingFromGID:gidBuiding andGridPos:CGPointMake(i, j)];
                if (building) {
                    [buildings addObject:building];
                }
            }
        }
        
    }
    
    for (Building* building in buildings) {
        [self addBuilding:building AtPoint:building.gridPos];
        [mainLayer addChild:building];
    }
}

#pragma mark - Update

- (BOOL)addBuilding:(Building*)building AtPoint:(CGPoint)point {
    if ([self outOfMap:point]) {
        return NO;
    }
    
    if ([self tileAtGridPos:point].building) {
        return NO;
    } else {
        [self tileAtGridPos:point].building = building;
        // TODO do somethnig with other tiles
        
        if ([building isKindOfClass:[TowerBuilding class]]) {
            // TODO
            TowerBuilding  *towerBuilding = (TowerBuilding*)building;

            for (int i = -LUMINOSITY_RADIUS; i <= LUMINOSITY_RADIUS ; i ++) {
                for (int j = -LUMINOSITY_RADIUS; j <= LUMINOSITY_RADIUS; j ++) {
                    CGPoint offsetPoint = CGPointMake(point.x + i, point.y + j);
                    
                    if (! [self outOfMap:offsetPoint]) {
                        Tile* tile = [self tileAtGridPos:offsetPoint];
                        tile.light = tile.light + [self calculateLightFromLight:towerBuilding.light atDistance:CGPointMake(i, j)];
                    }   
                }
            }
            // TODO update draw model
            
            CCTMXLayer* bgLayer = [map layerNamed:@"BG"];
            
            for (int i = -5 - 1; i <= 5 + 1; ++i) {
                for (int j = -5 -1; j <= 5 +1; ++j) {
                    if (! [self outOfMap:CGPointMake(point.x + i, point.y + j)]) {
                        int light = [self tileAtGridPos:CGPointMake(point.x + i, point.y + j)].light;
                        
                        [bgLayer setCornerIntensitiesForTile:ccc4(tlLight, trLight, brLight, blLight) x:offsetPoint.x y:offsetPoint.y]; 
                    } 
                }
            }

        }
        return YES;
    }
}

- (BOOL)destroyBuildingAtPoint:(CGPoint)point {
    if ([self outOfMap:point]) {
        return NO;
    } 
    
    if (![self tileAtGridPos:point].building) {
        return NO;
    } else {
        Building *building = [self tileAtGridPos:point].building;
        
        if ([building isKindOfClass:[TowerBuilding class]]) {
            // TODO
            TowerBuilding  *towerBuilding = (TowerBuilding*)building;
            
            for (int i = -5; i <= 5 ; i ++) {
                for (int j = -5; i <= 5; j ++) {
                    if ([self outOfMap:CGPointMake(point.x + i, point.y + j)]) {
                        [self tileAtGridPos:point].light -= [self calculateLightFromLight:towerBuilding.light atDistance:CGPointMake(i, j)]; 
                    }   
                }
            }
            // TODO update draw model
        }
        
        [self tileAtGridPos:point].building = nil;

        return YES;
    }

}

#pragma mark - Getters

- (Tile*)tileAtGridPos:(CGPoint)point {
    
    if ([self outOfMap:point]) 
        return nil;

    return tiledMapArray[(int)(point.x + point.y*map.mapSize.width)];
}


- (CGPoint)gridPosFromPixelPosition:(CGPoint)point; {
    return CGPointMake(floorf(point.x / self.tileSize.width), floorf(map.mapSize.height - (point.y / self.tileSize.height)) );
    
}

- (Building*)buildingAtPoint:(CGPoint)point {

    if ([self outOfMap:point]) 
        return nil;
    
    return [self tileAtGridPos:point].building;
}

#pragma mark - dealloc

- (void)dealloc {
    
    [self freeMap]; 
}

@end
