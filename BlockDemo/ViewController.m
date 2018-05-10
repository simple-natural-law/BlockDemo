//
//  ViewController.m
//  BlockDemo
//
//  Created by 讯心科技 on 2018/3/13.
//  Copyright © 2018年 讯心科技. All rights reserved.
//



#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, copy) NSInteger (^mallocBlock)(NSInteger num);

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self callStackBlock];
    
    [self callGlobalblock];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    __weak typeof(self) weakself = self;
    
    // 当需要延迟调用mallocBlock时，MRC下需要对mallocBlock手动执行copy操作来将其从栈区复制到堆区，以避免栈帧被释放时mallocBlock也被释放。ARC下编译器自动将mallocBlock从栈区复制到堆区。
    self.mallocBlock = ^(NSInteger num) {
        
        // 使用weakself来防止stackBlock和self相互引用
        return [weakself calculateResultWithNum:num];
    };
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self callMallocBlock];
}


- (void)callStackBlock
{
    // 声明一个block
    NSInteger (^stackBlock)(NSInteger num);
    
    // 创建block
    stackBlock = ^(NSInteger num){
        
        // 由于stackBlock没有被任何对象持有，所以调用stackBlock时，不会产生循环引用。
        return [self calculateResultWithNum:num];
    };
    
    // 调用block
    NSLog(@"调用stackBlock ----> %ld",stackBlock(10));
    
    // MRC下，stackBlock是一个存放在栈区的__NSStackBlock__，栈帧被释放（超出作用域）后，stackBlock就会被释放。而在ARC下，编译器会自动将stackBlock从栈区复制到堆区，所以此时stackBlock是一个存放在堆区的的__NSMallocBlock__。
    NSLog(@"stackBlock ----> %@",stackBlock);
}

- (void)callGlobalblock
{
    void (^globalBlock)(NSInteger num) = ^(NSInteger num){
        
        NSLog(@"调用globalBlock ----> %ld",num);
    };
    
    globalBlock(10);
    // 由于globalBlock主体内部没有访问外部变量，所以globalBlock是一个存放在静态区（也叫全局区）的__NSGlobalBlock__。对__NSGlobalBlock__执行retain和copy操作是无效的。
    NSLog(@"globalBlock ----> %@",globalBlock);
}

- (void)callMallocBlock
{
    NSLog(@"调用mallocBlock ----> %ld",self.mallocBlock(10));
    
    NSLog(@"mallocBlock ----> %@",self.mallocBlock);
}



- (NSInteger)calculateResultWithNum:(NSInteger)num
{
    return num*10;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
