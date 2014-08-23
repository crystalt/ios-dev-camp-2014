//
//  BirdNode.m
//  spritybird
//
//  Created by Alexis Creuzot on 16/02/2014.
//  Copyright (c) 2014 Alexis Creuzot. All rights reserved.
//

#import "BirdNode.h"

#define VERTICAL_SPEED 1
#define VERTICAL_DELTA 5.0

@interface BirdNode ()
@property (strong,nonatomic) SKAction * flap;
@property (strong,nonatomic) SKAction * flapForever;
@property (strong,nonatomic) UIImage * customImage;
@end

@implementation BirdNode

static CGFloat deltaPosY = 0;
static bool goingUp = false;
static CGFloat resetVelocity = 10;

- (id)init
{
    if(self = [super init]){
        
        // TODO : use texture atlas
        SKTexture* birdTexture1 = [SKTexture textureWithImageNamed:@"bird_1"];
        birdTexture1.filteringMode = SKTextureFilteringNearest;
        SKTexture* birdTexture2 = [SKTexture textureWithImageNamed:@"bird_2"];
        birdTexture2.filteringMode = SKTextureFilteringNearest;
        birdTexture2.filteringMode = SKTextureFilteringNearest;
        self = [BirdNode spriteNodeWithTexture:birdTexture1];
        
//        self.flap = [SKAction animateWithTextures:@[birdTexture1, birdTexture2,birdTexture3] timePerFrame:0.2];
//        self.flapForever = [SKAction repeatActionForever:self.flap];
        
        [self setTexture:birdTexture1];
//        [self runAction:self.flapForever withKey:@"flapForever"];
    }
    return self;
}

- (void) resetGoingUp {
    goingUp = false;
}

- (void) update:(NSUInteger) currentTime
{
    if(!self.physicsBody){
        if(deltaPosY > VERTICAL_DELTA){
            goingUp = false;
        }
        if(deltaPosY < -VERTICAL_DELTA){
            goingUp = true;
        }
        
        float displacement = (goingUp)? VERTICAL_SPEED : -VERTICAL_SPEED;
        self.position = CGPointMake(self.position.x, self.position.y + displacement);
        deltaPosY += displacement;
    }
    
    // Rotate body based on Y velocity (front toward direction)
    self.zRotation = M_PI * self.physicsBody.velocity.dx * 0.0005;
    resetVelocity += 25;
    // self.scene.physicsWorld.speed += 0.001; // TODO: think about increasing the speed to make it harder
}

- (void) startPlaying
{
    deltaPosY = 0;
    [self setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(26, 18)]];
    self.physicsBody.categoryBitMask = birdBitMask;
    self.physicsBody.mass = 0.01;
    [self removeActionForKey:@"flapForever"];
}

- (void) bounce
{
    CGFloat newVeloc = 150-abs((abs(self.physicsBody.velocity.dx) - resetVelocity));
    if (newVeloc < 0){
        newVeloc = 0;
    }
    resetVelocity = 0;
//    self.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
    [self.physicsBody applyImpulse:CGVectorMake(goingUp ? newVeloc/-150.0f : newVeloc/150.0f, 0.0f)];
    self.scene.physicsWorld.gravity = CGVectorMake(goingUp ? 4.0f : -4.0f, 0.0f);
    
    goingUp = !goingUp;
    
    [self runAction:self.flap];
    if (!self.customImage) {
        if (goingUp) {
            self.texture = [SKTexture textureWithImageNamed:@"bird_face_left"];
        } else {
            self.texture = [SKTexture textureWithImageNamed:@"bird_1"];
        }
    }
}


@end
