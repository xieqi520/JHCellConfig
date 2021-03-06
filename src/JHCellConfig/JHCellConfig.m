//
//  JHCellConfig.m
//  JHCellConfigDemo
//
//  Created by JC_Hu on 15/2/25.
//  Copyright (c) 2015年 JCHu. All rights reserved.
//

#import "JHCellConfig.h"

@implementation JHCellConfig

#pragma mark - Core

+ (instancetype)cellConfigWithCellClass:(Class)cellClass
                              dataModel:(id)dataModel
{
    return [self cellConfigWithCellClass:cellClass title:nil dataModel:dataModel];
}

+ (instancetype)cellConfigWithCellClass:(Class)cellClass
                                  title:(NSString *)title
                              dataModel:(id)dataModel
{
    return [self cellConfigWithCellClass:cellClass title:title dataModel:dataModel selectBlock:nil];
}

+ (instancetype)cellConfigWithCellClass:(Class)cellClass
                                  title:(NSString *)title
                              dataModel:(id)dataModel
                            selectBlock:(JHCellSelectBlock)selectBlock
{
    JHCellConfig *cellConfig = [JHCellConfig new];
    
    cellConfig.className = NSStringFromClass(cellClass);
    cellConfig.title = title;
    cellConfig.updateContentMethod = @selector(updateContentWithCellConfig:);
    cellConfig.cellHeightMethod = @selector(cellHeightWithCellConfig:);
    cellConfig.dataModel = dataModel;
    cellConfig.selectBlock = selectBlock;
    
    return cellConfig;
}

/// 根据cellConfig生成cell，重用ID为cell类名
- (UITableViewCell *)cellOfCellConfigWithTableView:(UITableView *)tableView
{
    Class cellClass = NSClassFromString(self.className);
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self cellID]];
    
    if (!cell) {
        // 加入使用nib的方法
        if (self.isNib && self.className.length &&![self.className isEqualToString:@"UITableViewCell"]) {
            NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:self.className owner:nil options:nil];
            
            for (id obj in nibs) {
                if ([obj isKindOfClass: cellClass]) {
                    cell = obj;
                }
            }
            if (!cell) {
                NSLog(@"Please Check Nib File About %@", cellClass);
            }
            
        } else {
            cell = [[cellClass?:[UITableViewCell class] alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:[self cellID]];
        }
    }
    
    // bind
    if ([cell conformsToProtocol:@protocol(JHCellConfigProtocol)]) {
        [((id <JHCellConfigProtocol>)cell) setJhg_cellConfig:self];
    }
    
    // 更新cell界面
    if (self.updateContentMethod && [cell respondsToSelector:self.updateContentMethod]) {
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [cell performSelector:self.updateContentMethod withObject:self.updateContentWithDataModel?self.dataModel:self];
#pragma clang diagnostic pop
    }
    
    
    return cell;
}

- (CGFloat)cellHeight
{
    if (self.constantHeight) {
        return self.constantHeight;
    }
    
    if (self.cachedHeight) {
        return self.cachedHeight;
    }
    
    Class cellClass = NSClassFromString(self.className);
    
    if (self.cellHeightMethod && [cellClass respondsToSelector:self.cellHeightMethod]) {
        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                    [cellClass methodSignatureForSelector:self.cellHeightMethod]];
        
        JHCellConfig *tempSelf = self;
        [invocation setSelector:self.cellHeightMethod];
        [invocation setTarget:cellClass];
        [invocation setArgument:&tempSelf atIndex:2];
        [invocation invoke];
        CGFloat height;
        
        [invocation getReturnValue:&height];
        
        return height;
    }
    return 0;
}

- (NSString *)cellID
{
    if (self.reuseID.length) {
        return self.reuseID;
    }
    return self.className;
}


- (JHCellConfig *)useNib
{
    self.isNib = YES;
    return self;
}

- (JHCellConfig *)registerNib:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:self.className bundle:nil] forCellReuseIdentifier:[self cellID]];
    return self;
}



@end
