/**
 *
 * Created by Lam Hoang Pham on 08/07/09.
 * Updated for cocos2d 2.0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 *
 *	QUICK INFO:
 *	A Transformable Texture Node has fields that allow a user to position, scale,
 *	rotate a texture in a node in the same manner that a CCNode allows
 *	transforms on the actual object.
 *	
 *	GOTCHAS AND LIMITATIONS:
 *	We have a speed improvement by having the gpu transform the texture for us but
 *	this means we have some limitations listed below.
 *
 *	A transformation will behave differently than a CocosNode transformation.
 *
 *	To access the transform we have a set of properties called setTexture<transform name> and getTexture<transform name>.
 *
 *	Take note:
 *	The texture setTextureAnchorPoint is flipped from a CocosNode:anchorPoint:
 *	0,0 (topleft)		0,1 (topright)
 *	0,1 (bottomleft)	1,1 (bottomright)
 *
 *	Transforms:		Default		Range
 *	setTexturePosition		(0,0)		[-inf, inf] 
 *		Wraps around at cycles of 1.
 *		Moves left for positive values of x, right for negative values of x
 *		Moves up for positive values of y,	down for negative values of y
 *	setTextureScale			(1,1)		[-inf, inf]
 *		Shrinks for large values, Grows for small values, flips on negative
 *	setTextureRotation (0,0)		[-inf, inf]
 *		Counterclockwise for positive values and clockwise for negative
 *
 *	Texture transforms are opposite of CocosNode transforms and remember that
 *	y is flipped. This is due to texture coordinates starting top left and within [0..1]
 *
 *	Note that if you're repeating a texture it should be a power of 2 so you won't
 *	see gaps. Gaps occur for non-powers of 2 because CCTexture2D stores texture data
 *	as a power of 2 with gaps at the edges but we have to use the entire texture data.
 *
 *	Another caveat is that texture rotation transform works best with "square
 *	textures" otherwise texture mapping takes place and you'll run into distortions.
 *	The texture will stretch the image to map to the texture coordinate.
 *
 *
 *	USAGE:
 *	If you ever need to manually adjust the transforms of the transformable texture
 *	just access the properties:
 *	[self setTexturePosition:ccp(0,0)]; or self.texturePosition = ccp(0,0);
 *	CGPoint texPosition = [self texturePosition] or self.texturePosition
 *
 *	REPEAT ANDS CLAMP INFO:
 *	By calling CCTransformTexture:setTextureParams: we can change the wrapping of the texture
 *	as it transforms. We have to store the texture params in class due to the limitation that
 *	a Texture2D Image can only have one wrap mode but we may want multiple sprites
 *	to have different wrapping modes even if they use the same texture.
 *	[self setTextureParams:(ccTexParams){GL_LINEAR,GL_LINEAR,GL_REPEAT,GL_REPEAT}];
 *	@see ccTexParam for more information
 */

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef struct TextureTransform_t {
	CGPoint				position;
	CGPoint				anchorPoint;
	CGPoint				rotation;
	CGPoint				scale;
	ccTexParams		params;
	BOOL					isDirty;
} TextureTransformCache;

@interface CCTransformTexture : CCSprite {
	GLint uniformTMatrix_;
	TextureTransformCache texTransformCache_;
	float TMat_[16];
}

@property(nonatomic,readwrite,assign) float textureRotation;
@property(nonatomic,readwrite,assign) float textureRotationX;
@property(nonatomic,readwrite,assign) float textureRotationY;

@property(nonatomic,readwrite,assign) float textureScale;
@property(nonatomic,readwrite,assign) float textureScaleX;
@property(nonatomic,readwrite,assign) float textureScaleY;
@property(nonatomic,readwrite,assign) CGPoint texturePosition;
@property(nonatomic,readwrite) CGPoint textureAnchorPoint;
@property(nonatomic,readwrite,assign) ccTexParams textureParams;

-(void) loadShader;

@end


#pragma mark -
#pragma mark TTexture Actions
#pragma mark -
@interface CCTextureMoveTo : CCMoveTo<NSCopying>
@end

@interface CCTextureMoveBy : CCTextureMoveTo<NSCopying>
@end

@interface CCTextureRotateTo : CCRotateTo<NSCopying>
@end

@interface CCTextureRotateBy : CCRotateBy<NSCopying>
@end

@interface CCTextureScaleTo : CCScaleTo<NSCopying>
@end

@interface CCTextureScaleBy : CCTextureScaleTo<NSCopying>
@end

extern const GLchar * ccPositionTextureColor2_vert;
