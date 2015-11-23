#import "BTUIHorizontalButtonStackCollectionViewFlowLayout.h"
#import "BTUIHorizontalButtonStackSeparatorLineView.h"


NSString *BTHorizontalButtonStackCollectionViewFlowLayoutLineSeparatorDecoratorViewKind = @"BTHorizontalButtonStackCollectionViewFlowLayoutLineSeparatorDecoratorViewKind";

@interface BTUIHorizontalButtonStackCollectionViewFlowLayout ()
@end

@implementation BTUIHorizontalButtonStackCollectionViewFlowLayout

- (id)init {
    self = [super init];
    if (self) {
        [self registerClass:[BTUIHorizontalButtonStackSeparatorLineView class] forDecorationViewOfKind:BTHorizontalButtonStackCollectionViewFlowLayoutLineSeparatorDecoratorViewKind];
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];

    NSAssert(self.collectionView.numberOfSections == 1, @"Must have 1 section");
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
    CGFloat totalWidth = self.collectionView.frame.size.width;

    if (numberOfItems == 0) {
        return;
    }

    self.itemSize = CGSizeMake(totalWidth/numberOfItems, self.collectionView.frame.size.height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *layoutAttributes = [[super layoutAttributesForElementsInRect:rect] mutableCopy];

    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
    if (numberOfItems == 0) {
        return layoutAttributes;
    }

    NSArray *layoutAttributesWithoutLastElement = [layoutAttributes subarrayWithRange:NSMakeRange(0, [layoutAttributes count] > 0 ? [layoutAttributes count] - 1 : 0)];
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributesWithoutLastElement) {
        UICollectionViewLayoutAttributes *separatorAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:BTHorizontalButtonStackCollectionViewFlowLayoutLineSeparatorDecoratorViewKind
                                                                                                                            withIndexPath:attributes.indexPath];
        separatorAttributes.frame = CGRectMake(attributes.frame.origin.x + attributes.frame.size.width, attributes.frame.origin.y, 1/2.0f, attributes.frame.size.height);
        [layoutAttributes addObject:separatorAttributes];
    }

    return layoutAttributes;
}

@end
