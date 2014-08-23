//
//  SKScrollingNode.m
//  spritybird
//
//  Created by Alexis Creuzot on 09/02/2014.
//  Copyright (c) 2014 Alexis Creuzot. All rights reserved.
//

#import "SKScrollingNode.h"

@implementation SKScrollingNode


+ (id) scrollingNodeWithImageNamed:(NSString *)name inContainerHeight:(float) height
{
    UIImage * image = [UIImage imageNamed:name];
    
    SKScrollingNode * realNode = [SKScrollingNode spriteNodeWithColor:[UIColor clearColor] size:CGSizeMake(image.size.width, height)];
    realNode.scrollingSpeed = 1;
    
    float total = 0;
    while(total<(height + image.size.height)){
        SKSpriteNode * child = [SKSpriteNode spriteNodeWithImageNamed:name ];
        [child setAnchorPoint:CGPointZero];
        [child setPosition:CGPointMake(0, total)];
        [realNode addChild:child];
        total+=child.size.height;
    }
    
    return realNode;
}

- (void) update:(NSTimeInterval)currentTime
{
    [self.children enumerateObjectsUsingBlock:^(SKSpriteNode * child, NSUInteger idx, BOOL *stop) {
        child.position = CGPointMake(child.position.x, child.position.y-self.scrollingSpeed);
        if (child.position.y <= -child.size.height){
            float delta = child.position.y+child.size.height;
            child.position = CGPointMake(child.position.x, child.size.height*(self.children.count-1)+delta);
        }
    }];
}

@end
