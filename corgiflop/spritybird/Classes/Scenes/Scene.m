//
//  BouncingScene.m
//  Bouncing
//
//  Created by Seung Kyun Nam on 13. 7. 24..
//  Copyright (c) 2013년 Seung Kyun Nam. All rights reserved.
//

#import "Scene.h"
#import "SKScrollingNode.h"
#import "BirdNode.h"
#import "Score.h"
#import <TapSenseAds/TapSenseInterstitial.h>
#import <TapSenseAds/TapSenseAds.h>
#import <TapSenseAds/TapSenseAdView.h>

#define BACK_SCROLLING_SPEED 4

#define FLOOR_SCROLLING_SPEED 0

// Obstacles
#define HORIZONTAL_GAP_SIZE 160
#define FIRST_OBSTACLE_PADDING 100
#define OBSTACLE_MIN_WIDTH 30
#define OBSTACLE_INTERVAL_SPACE 200

#define SWINGING_OBSTACLE_RADIUS 90
#define SWINGING_OBSTACLE_HORIZONTAL_DELTA 80
#define SWINGING_OBSTACLE_HORIZONTAL_SPEED 1
#define OBSTACLE_MAGIC_DISTANCE 20 // this is the distance betwixt the middle of the two holes

#define SWINGING_OBSTACLE_RADIUS_SQUARED 8100

@interface Scene ()

@property (nonatomic, strong) SKSpriteNode *fbNode;
@property (nonatomic, strong) PicturePicker *picturePicker;
@property (nonatomic, strong) TapSenseInterstitial *tsInterstitial;
@property (nonatomic, strong) TapSenseAdView *adView;

@end

@implementation Scene{
    SKScrollingNode * floor;
    SKScrollingNode * back;
    SKLabelNode * scoreLabel;
    BirdNode * bird;
    
    int nbObstacles;
    NSMutableArray * rightPipes;
    NSMutableArray * leftPipes;
    NSMutableArray * rightHammers;
    NSMutableArray * leftHammers;
    NSMutableArray * hammerDeltaPosX;
    NSMutableArray * hammerGoingLeft;
    
    NSMutableArray * bloodDrops;
    NSMutableArray * tearDrops;
}

static bool wasted = NO;
static bool gameStarted = NO;
static int gamesPlayed = 0;
static bool firstLoad = YES;

- (id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.physicsWorld.contactDelegate = self;
        [TapSenseAds setTestMode];
        [TapSenseAds setShowDebugLog];
        self.tsInterstitial = [[TapSenseInterstitial alloc] initWithAdUnitId:@"53d03865e4b004068fab1c9d" shouldAutoRequestAd:NO keywordMap:nil];
        self.physicsWorld.gravity = CGVectorMake(1.8f, 0.0f);
        [self startGame];
        
    }
    return self;
}

- (void) startGame
{
    // Reinit
    wasted = NO;
    gameStarted = NO;
    gamesPlayed++;
    
    [self.tsInterstitial requestAd];

    
    [self removeAllChildren];
    
    [self createBackground];
//    [self createFloor];
    [self createScore];
    [self createObstacles];
    [self createBird];
    [self createDeathSprites];
    
    [self addChild: [self fireButtonNode]];
    
    // Floor needs to be in front of tubes
    floor.zPosition = bird.zPosition + 1;
    
    if([self.delegate respondsToSelector:@selector(eventStart)]){
        [self.delegate eventStart];
    }
}

#pragma mark - Creations

- (void) createBackground
{
    back = [SKScrollingNode scrollingNodeWithImageNamed:@"back" inContainerHeight:HEIGHT(self)];
    [back setScrollingSpeed:BACK_SCROLLING_SPEED];
    [back setAnchorPoint:CGPointZero];
    [back setPhysicsBody:[SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame]];
    back.physicsBody.categoryBitMask = backBitMask;
    back.physicsBody.contactTestBitMask = birdBitMask;
    [self addChild:back];
}

- (void) createScore
{
    self.score = 0;
    scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    scoreLabel.text = @"0";
    scoreLabel.fontSize = 500;
    scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), 100);
    scoreLabel.alpha = 0.2;
    [self addChild:scoreLabel];
}


- (void)createFloor
{
    floor = [SKScrollingNode scrollingNodeWithImageNamed:@"floor" inContainerHeight:HEIGHT(self)];
    [floor setScrollingSpeed:FLOOR_SCROLLING_SPEED];
    [floor setAnchorPoint:CGPointZero];
    [floor setName:@"floor"];
    [floor setPhysicsBody:[SKPhysicsBody bodyWithEdgeLoopFromRect:floor.frame]];
    floor.physicsBody.categoryBitMask = floorBitMask;
    floor.physicsBody.contactTestBitMask = birdBitMask;
    [self addChild:floor];
}

- (void)createBird
{
    bird = [BirdNode new];
    [bird setPosition:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))];
    [bird setName:@"bird"];
    [self addChild:bird];
}

- (void)createDeathSprites {
    bloodDrops = @[].mutableCopy;
    tearDrops = @[].mutableCopy;
    for (int i = 0; i < 40; i++) {
        SKSpriteNode * bloodDrop = [SKSpriteNode spriteNodeWithImageNamed:@"blood_drop"];
        [self addChild:bloodDrop];
        [bloodDrops addObject:bloodDrop];
    }
    for (int i = 0; i < 2; i++) {
        SKSpriteNode * tearDrop = [SKSpriteNode spriteNodeWithImageNamed:@"tear_drop"];
        [self addChild:tearDrop];
        [tearDrops addObject:tearDrop];
    }
}

- (void) createObstacles
{
    // Calculate how many obstacles we need, the less the better
    nbObstacles = ceil(HEIGHT(self)/(OBSTACLE_INTERVAL_SPACE));
    
    CGFloat lastBlockPos = 0;
    leftPipes = @[].mutableCopy;
    rightPipes = @[].mutableCopy;
    leftHammers = @[].mutableCopy;
    rightHammers = @[].mutableCopy;
    hammerDeltaPosX = @[].mutableCopy;
    hammerGoingLeft = @[].mutableCopy;
    for(int i=0;i<nbObstacles;i++){
        SKSpriteNode * rightPipe = [SKSpriteNode spriteNodeWithImageNamed:@"pipe_top"];
        [rightPipe setAnchorPoint:CGPointZero];
        [self addChild:rightPipe];
        [rightPipes addObject:rightPipe];
        
        SKSpriteNode * leftPipe = [SKSpriteNode spriteNodeWithImageNamed:@"pipe_bottom"];
        [leftPipe setAnchorPoint:CGPointZero];
        [self addChild:leftPipe];
        [leftPipes addObject:leftPipe];

        SKSpriteNode * rightHammer = [SKSpriteNode spriteNodeWithImageNamed:@"hammer_left"];
        [rightHammer setAnchorPoint:CGPointZero];
        [self addChild:rightHammer];
        [rightHammers addObject:rightHammer];
        
        SKSpriteNode * leftHammer = [SKSpriteNode spriteNodeWithImageNamed:@"hammer_left"];
        [leftHammer setAnchorPoint:CGPointZero];
        [self addChild:leftHammer];
        [leftHammers addObject:leftHammer];
        
        // random number between -SWINGING_OBSTACLE_HORIZONTAL_DELTA and +SWINGING_OBSTACLE_HORIZONTAL_DELTA
        float randomFloat = [Math randomFloatBetween:0 and:1];
        NSLog(@"randomFloat = %f", randomFloat);
        int randomStart = round(randomFloat * SWINGING_OBSTACLE_HORIZONTAL_DELTA*2 - SWINGING_OBSTACLE_HORIZONTAL_DELTA);
        NSLog(@" adding randomStart = %d", randomStart);
        [hammerDeltaPosX addObject:@(0)];
        [hammerGoingLeft addObject:@(NO)];
        
        // Give some time to the player before first obstacle
        if(0 == i){
            [self leftPipe:leftPipe andRightPipe:rightPipe andLeftHammer:leftHammer andRightHammer:rightHammer atY:HEIGHT(self)-FIRST_OBSTACLE_PADDING];
        }else{
            [self leftPipe:leftPipe andRightPipe:rightPipe andLeftHammer:leftHammer andRightHammer:rightHammer atY:lastBlockPos + HEIGHT(leftPipe) +OBSTACLE_INTERVAL_SPACE];
        }
        lastBlockPos = rightPipe.position.y;
    }
}

- (SKSpriteNode *)fireButtonNode
{
    self.fbNode = [SKSpriteNode spriteNodeWithImageNamed:@"fb_icon.png"];
    self.fbNode.position = CGPointMake(25,25);
    self.fbNode.name = @"fbNode";//how the node is identified later
    self.fbNode.zPosition = 1.0;
    return self.fbNode;
}

#pragma mark - Interaction 

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    //if fire button touched, bring the rain
    if ([node.name isEqualToString:@"fbNode"]) {
        if (!gameStarted){
            self.picturePicker = [[PicturePicker alloc] init];
            self.picturePicker.delegate = self;
            self.picturePicker.rootViewController = self.view.window.rootViewController;
            [self.picturePicker showFriendPicker];
            return;
        }
    }
    
    if(wasted){
        [self startGame];
    }else{
        if (!firstLoad){
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"GAME_START"
             object:self];
        }
        firstLoad = NO;
        gameStarted = YES;
        self.fbNode.hidden = YES;
        if (!bird.physicsBody) {
            [bird startPlaying];
            if([self.delegate respondsToSelector:@selector(eventPlay)]){
                [self.delegate eventPlay];
            }
        }
        [bird bounce];
        
    }
}

- (void) picturePickerFinisheed:(PicturePicker *)picturePicker withImage:(UIImage *)image
{
    [bird updateBirdWithImage:image];
}


#pragma mark - Update & Core logic


- (void)update:(NSTimeInterval)currentTime
{
    if(wasted){
        return;
    }
    
    // ScrollingNodes
    [back update:currentTime];
    [floor update:currentTime];
    
    // Other
    [bird update:currentTime];
    [self updateObstacles:currentTime];
    [self updateScore:currentTime];
}


- (void) updateObstacles:(NSTimeInterval)currentTime
{
    if(!bird.physicsBody){
        return;
    }
    
    for(int i=0;i<nbObstacles;i++){
        
        // Get pipes bby pairs
        SKSpriteNode * rightPipe = (SKSpriteNode *) rightPipes[i];
        SKSpriteNode * leftPipe = (SKSpriteNode *) leftPipes[i];
        SKSpriteNode * rightHammer = (SKSpriteNode *) rightHammers[i];
        SKSpriteNode * leftHammer = (SKSpriteNode *) leftHammers[i];
//        CGFloat deltaPosX = [hammerDeltaPosX[i] floatValue];
        
        // Check if pair has exited screen, and place them upfront again
        if (Y(rightPipe) < -HEIGHT(rightPipe)){
            SKSpriteNode * mostRightPipe = (SKSpriteNode *) rightPipes[(i+(nbObstacles-1))%nbObstacles];
            [self leftPipe:leftPipe
              andRightPipe:rightPipe
             andLeftHammer:leftHammer
            andRightHammer:rightHammer
                       atY:Y(mostRightPipe)+HEIGHT(rightPipe)+OBSTACLE_INTERVAL_SPACE];
        }
        
        // Move according to the scrolling speed
        rightPipe.position = CGPointMake(X(rightPipe), Y(rightPipe) - BACK_SCROLLING_SPEED);
        leftPipe.position = CGPointMake(X(leftPipe), Y(leftPipe) - BACK_SCROLLING_SPEED);
        
        // swing the hammer
        if([hammerDeltaPosX[i] floatValue] >= SWINGING_OBSTACLE_HORIZONTAL_DELTA){
            hammerGoingLeft[i] = @(NO);
            // hammers should be facing left
            rightHammer.texture = [SKTexture textureWithImageNamed:@"hammer_left"];
            leftHammer.texture = [SKTexture textureWithImageNamed:@"hammer_left"];
        }
        if([hammerDeltaPosX[i] floatValue] <= -SWINGING_OBSTACLE_HORIZONTAL_DELTA){
            hammerGoingLeft[i] = @(YES);
            // hammers should be facing right
            rightHammer.texture = [SKTexture textureWithImageNamed:@"hammer_right"];
            leftHammer.texture = [SKTexture textureWithImageNamed:@"hammer_right"];
        }
        float xDisplacement = ([hammerGoingLeft[i] boolValue])? SWINGING_OBSTACLE_HORIZONTAL_SPEED : -SWINGING_OBSTACLE_HORIZONTAL_SPEED;
        float yDisplacement = sqrt(SWINGING_OBSTACLE_RADIUS_SQUARED - pow([hammerDeltaPosX[i] floatValue],2));
        
        rightHammer.position = CGPointMake(X(rightHammer) + xDisplacement, Y(rightPipe) - yDisplacement - BACK_SCROLLING_SPEED);
        leftHammer.position = CGPointMake(X(leftHammer) + xDisplacement, Y(leftPipe) - yDisplacement - BACK_SCROLLING_SPEED);
        hammerDeltaPosX[i] = @([hammerDeltaPosX[i] floatValue] + xDisplacement);
    }
}

- (void) leftPipe:(SKSpriteNode *) leftPipe
     andRightPipe:(SKSpriteNode *) rightPipe
    andLeftHammer:(SKSpriteNode *) leftHammer
   andRightHammer:(SKSpriteNode *) rightHammer
              atY:(float) yPos
{
    // Maths
    float availableSpace = WIDTH(self);
    float maxVariance = availableSpace - (2*OBSTACLE_MIN_WIDTH) - HORIZONTAL_GAP_SIZE;
    float variance = [Math randomFloatBetween:0 and:maxVariance];
    
    // Left pipe placement
    float minLeftPosX = OBSTACLE_MIN_WIDTH - WIDTH(self);
    float leftPosX = minLeftPosX + variance;
    
    leftPipe.position = CGPointMake(leftPosX,yPos);
    leftPipe.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0,0, WIDTH(leftPipe) , HEIGHT(leftPipe))];
    leftPipe.physicsBody.categoryBitMask = blockBitMask;
    leftPipe.physicsBody.contactTestBitMask = birdBitMask;

    // Right pipe placement
    rightPipe.position = CGPointMake(leftPosX + WIDTH(leftPipe) + HORIZONTAL_GAP_SIZE,yPos);
    rightPipe.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0,0, WIDTH(rightPipe), HEIGHT(rightPipe))];
    
    rightPipe.physicsBody.categoryBitMask = blockBitMask;
    rightPipe.physicsBody.contactTestBitMask = birdBitMask;
    
    // Left hammer placement
    leftHammer.position = CGPointMake(leftPosX + WIDTH(leftPipe) - WIDTH(leftHammer)/2 - OBSTACLE_MAGIC_DISTANCE,yPos-SWINGING_OBSTACLE_RADIUS);
    leftHammer.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0,0, WIDTH(leftHammer), HEIGHT(leftHammer))];
    leftHammer.physicsBody.categoryBitMask = blockBitMask;
    leftHammer.physicsBody.contactTestBitMask = birdBitMask;
    
    // Right hammer placement
    rightHammer.position = CGPointMake(leftPosX + WIDTH(leftPipe) + HORIZONTAL_GAP_SIZE - WIDTH(rightHammer)/2+OBSTACLE_MAGIC_DISTANCE,yPos-SWINGING_OBSTACLE_RADIUS);
    rightHammer.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0,0, WIDTH(rightHammer), HEIGHT(rightHammer))];
    rightHammer.physicsBody.categoryBitMask = blockBitMask;
    rightHammer.physicsBody.contactTestBitMask = birdBitMask;
}


- (void) updateScore:(NSTimeInterval) currentTime
{
    for(int i=0;i<nbObstacles;i++){
        
        SKSpriteNode * topPipe = (SKSpriteNode *) rightPipes[i];
        
        // Score, adapt font size
        if(Y(topPipe) + HEIGHT(topPipe)/2 > bird.position.y &&
           Y(topPipe) + HEIGHT(topPipe)/2 < bird.position.y + BACK_SCROLLING_SPEED){
            self.score +=1;
            scoreLabel.text = [NSString stringWithFormat:@"%lu",self.score];
            if(self.score>=10){
                scoreLabel.fontSize = 340;
                scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), 120);
            }
        }
    }
}

#pragma mark - Physic

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    
    if (gamesPlayed % 2 == 0){
        [self.tsInterstitial showAdFromViewController:self.view.window.rootViewController];
    }

    if(wasted){ return; }

    wasted = true;
    
    // show blood and tears after collision
    for (int i = 0; i < bloodDrops.count; i++) {
        SKSpriteNode *bloodDrop = bloodDrops[i];
        bloodDrop.zPosition = bird.zPosition + 1;
        bloodDrop.position = bird.position;
        [bloodDrop setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(WIDTH(bloodDrop)/4, HEIGHT(bloodDrop)/4)]];
        bloodDrop.physicsBody.categoryBitMask = birdBitMask;
        bloodDrop.physicsBody.mass = 0.1;
        int rX = arc4random() % 40 + 40;
        int rY = arc4random() % 40 + 40;
        int rXDirection = rX % 2 == 0 ? 1 : -1;
        int rYDirection = rY % 2 == 0 ? 1 : -1;
        [bloodDrop.physicsBody applyImpulse:CGVectorMake(rX * rXDirection, rY * rYDirection)];
    }
    
    [Score registerScore:self.score];
    self.physicsWorld.gravity = CGVectorMake(0.0f, -9.8f);
    [bird resetGoingUp];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"GAME_END"
     object:self];
    
    if([self.delegate respondsToSelector:@selector(eventWasted)]){
        [self.delegate eventWasted];
    }
}
@end
