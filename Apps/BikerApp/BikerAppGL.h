//
//  BikerGL.h
//  FlowerForAll
//
//  Created by adherent on 07.12.12.
//
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

//hack
#define kAnimationDuration  0.3
enum animationDirection {
    kAnimationDirectionForward = YES,
    kAnimationDirectionBackward = NO
};
typedef BOOL AnimationDirection;
//hackend
@interface BikerGL : UIView {
    IBOutlet UIButton *start;
@private
    /* The pixel dimensions of the backbuffer */
    GLint backingWidth;
    GLint backingHeight;
    
    EAGLContext *context;
    
    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint viewRenderbuffer, viewFramebuffer;
    
    /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
    GLuint depthRenderbuffer;
    
    NSTimer *animationTimer;
    NSTimeInterval animationInterval;
    
    
    UILabel *StarCounterLabel;
    UIButton *StartButtonProg;
    UIButton *ItemsButtonProg;
    UIButton *ItemRotationProg;
    UILabel *ItemsLabel;
    UILabel *PercentLabel;
}

@property NSTimeInterval animationInterval;
@property (nonatomic, retain) UILabel *StarCounterLabel;
@property (nonatomic, retain) UIButton *StartButtonProg;
@property (nonatomic, retain) UIButton *ItemsButtonProg;
@property (nonatomic, retain) UIButton* ItemRotationProg;
@property (nonatomic, retain) UILabel *ItemsLabel;
@property (nonatomic, retain) UILabel *PercentLabel;

- (void)drawView;
- (void)setupView;
- (void)checkGLError:(BOOL)visibleCheck;

- (void)startAnimation;
- (void)stopAnimation;

@end
