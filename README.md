# Block编程指南

## 概述

block对象提供了一种可以使用C语言和C派生语言（例如Objective-C和C++）创建特定函数体的方法。在其他语言和环境中，block对象有时也称为“闭包”。

### Block的功能

block是一个匿名内联代码集合：
- 有像函数一样的类型参数列表；
- 有推断或者声明的返回类型；
- 可以从其作用域中捕获状态；
- 可以选择性修改作用域的状态；
- 可以与同一作用域中定义的其他block共享修改潜力；
- 能在作用域（栈帧）被销毁之后继续共享和修改在作用域（栈帧）内定义的状态；
- 可以复制一个block，甚至将其传递到其他线程以执行延迟执行（或者在其自己的线程中执行runloop）。编译器和runtime安排block的所有副本延长在block中引用的所有变量的生命周期。虽然block可用于纯C语言和C++语言，**但block总是一个Objective-C对象**。

### 用法

block通常代表小型、自包含的代码块。因此，其作为封装可能同时执行的工作单元或在集合中的项目的工具或者在另一个操作完成时作为回调的工具是特别有用的。

由于两个主要原因，block时传统回调函数的有用替代方案：
- 允许在方法实现的上下文中的稍后执行的调用点编写代码。因此，block通常是框架方法的参数。
- 允许访问局部变量。可以直接访问局部变量，而不是使用回调请求一个包含实现操作所需要的所有上下文信息的数据结构。

## 声明并使用一个Block

使用`^`运算符来声明一个Block变量并表明Block语法代码的开始。Block自身的主体包含在`{}`中，如本示例所示（通常与C语言一样，`;`表示语句的结尾）：
```
int multiplier = 7;

int (^myBlock)(int) = ^(int num) {
    return num * multiplier;
};
```
下图解释了这个例子：

![图1-1](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Blocks/Art/blocks.jpg)

注意，block可以使用与其在同一作用域的变量。

如果我们声明一个block变量，那么就可以像使用函数一个使用它：
```
int multiplier = 7;

int (^myBlock)(int) = ^(int num) {
    return num * multiplier;
};

printf("%d", myBlock(3));
// prints "21"
```

## 直接使用Block

在很多情况下，我们不需要声明block变量。取而代之的是，只需在需要将其作为参数的情况下内联编写block语法代码。以下示例使用`qsort_b`函数，`qsort_b`与标准的`qsort_r`函数类似，但将block作为其最终参数。
```
char *myCharacters[3] = { "TomJohn", "George", "Charles Condomine" };

qsort_b(myCharacters, 3, sizeof(char *), ^(const void *l, const void *r) {
    char *left = *(char **)l;
    char *right = *(char **)r;
    return strncmp(left, right, 1);
});

// myCharacters is now { "Charles Condomine", "George", "TomJohn" }
```

## Block与Cocoa

Cocoa框架中的一些方法将block作为参数，既可以对一组对象执行操作，也可以在操作完成后用作回调。以下示例显示了如何使用带有block的`NSArray`对象的`sortedArrayUsingComparator:`方法，该方法采用block作为参数。为了说明，在这种情况下block被定义为一个`NSComparator`局部变量。
```
NSArray *stringsArray = @[ @"string 1",@"String 21",@"string 12",@"String 11", @"String 02" ];

static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch;

NSLocale *currentLocale = [NSLocale currentLocale];

NSComparator finderSortBlock = ^(id string1, id string2) {

    NSRange string1Range = NSMakeRange(0, [string1 length]);
    
    return [string1 compare:string2 options:comparisonOptions range:string1Range        locale:currentLocale];
};

NSArray *finderSortArray = [stringsArray sortedArrayUsingComparator:finderSortBlock];

NSLog(@"finderSortArray: %@", finderSortArray);

/*
Output:
finderSortArray: (
"string 1",
"String 02",
"String 11",
"string 12",
"String 21"
)
*/
```

## __block变量

block的一个强力特征是其可以修改与其在相同作用域中的变量，使用`__block`存储类型修饰符来修饰变量意味着block可以修改此变量。改写上面的示例，使用block变量来计算比较的字符串数量，如下所示。为了说明，在这种情况下block被直接使用并block中使用currentLocale作为只读变量：
```
NSArray *stringsArray = @[ @"string 1",
@"String 21", // <-
@"string 12",
@"String 11",
@"Strîng 21", // <-
@"Striñg 21", // <-
@"String 02" ];

NSLocale *currentLocale = [NSLocale currentLocale];

__block NSUInteger orderedSameCount = 0;

NSArray *diacriticInsensitiveSortArray = [stringsArray sortedArrayUsingComparator:^(id string1, id string2) {

NSRange string1Range = NSMakeRange(0, [string1 length]);

NSComparisonResult comparisonResult = [string1 compare:string2 options:NSDiacriticInsensitiveSearch range:string1Range locale:currentLocale];

    if (comparisonResult == NSOrderedSame) {
        orderedSameCount++;
    }
    return comparisonResult;
}];

NSLog(@"diacriticInsensitiveSortArray: %@", diacriticInsensitiveSortArray);
NSLog(@"orderedSameCount: %d", orderedSameCount);

/*
Output:

diacriticInsensitiveSortArray: (
"String 02",
"string 1",
"String 11",
"string 12",
"String 21",
"Str\U00eeng 21",
"Stri\U00f1g 21"
)
orderedSameCount: 2
*/
```
更多详细信息，参看[Block和变量](#jump);


## 声明和创建Block

### 声明一个block引用

block变量持有对block的引用。使用和用于声明指向函数的指针相似的语法来声明block，除了使用`^`代替`*`之外。block类型与C语言类型系统的其余部分完全互操作。以下是所有有效的block变量声明：
```
void (^blockReturningVoidWithVoidArgument)(void);
int (^blockReturningIntWithIntAndCharArguments)(int, char);
void (^arrayOfTenBlocksReturningVoidWithIntArgument[10])(int);
```
block也支持可变参数`...`，不带参数的block必须在参数列表中指定`void`。

通过为编译器提供一组完整的元数据来用于验证block的使用、传递给block的参数和返回值的分配，block被设计为完全类型安全的。可以将block引用强制转换为任意类型的指针，反之亦然。但是不能通过指针取消引用运算符`*`来取消引用block引用，因此在编译时无法计算block的大小。

也可以为block创建类型，这样做通常被认为是在多个位置使用具有给定签名的block的最佳实践：
```
typedef float (^MyBlockType)(float, float);

MyBlockType myFirstBlock = // ... ;
MyBlockType mySecondBlock = // ... ;
```

### 创建一个Block

使用`^`运算符来表示block语法表达式的开始。它后面可以跟着包含在`()`中的参数列表，block的主体包含在`{}`中。以下示例定义了一个简单的block并将其分配给之前声明的变量（oneFrom）：
```
float (^oneFrom)(float);

oneFrom = ^(float aFloat) {
    float result = aFloat - 1.0;
    return result;
};
```
如果没有显式声明表达式的返回值，则可以根据block的内容自动推断它。如果返回类型被自动推断并且参数列表为`void`，则也可以省略`(void)`参数列表。当有多个返回语句时，它们必须完全匹配（如果有需要，使用强制转换）。

### 全局block

在文件级别，可以使用block作为全局字面：
```
#import <stdio.h>

int GlobalInt = 0;

int (^getGlobalInt)(void) = ^{ return GlobalInt; };
```

## Block和变量

### 变量类型

在block对象的代码体内，可以用五种不同的方式处理变量。

可以引用三种标准类型的变量，就像从函数中引用一样：
- 全局变量，包括静态变量；
- 全局函数（这在技术上不是变量）。
- 局部变量和作用域中的参数。

block还支持两种其他类型的变量：
1. 在函数级别是`__block`变量。它们在block（和作用域）内是可变的，如果任何引用的block被复制到**堆**中，它们将被保留。
2. 常量导入。

最后，在方法实现中，block可以引用Objective-C实例变量，参看[对象和Block变量](#jump)。

在block内使用变量时请应用以下规则：
1. 全局变量是可访问的，包括存在于作用域的静态变量。
2. 传递给block的参数是可访问的（就像函数的参数一样）。
3. 作用域中的栈区（非静态）局部变量被捕获为常量（`const`）变量。它们的值取自程序中block表达式所在处。在多个block嵌套使用时，访问该变量的block会在该变量离该block表达式最近的地方捕获该变量的值。在block内改变其值会导致错误。
4. 作用域中使用`__block`存储类型修饰符声明的局部变量由引用提供，因此是可变的。任何更改都会被反映在作用域中，包括在同一作用域中定义的任何其他block。更多详情参看[__block存储类型](#jump)。
5. 在block的作用域内声明的局部变量，其行为与函数中的局部变量完全相同。每个block的调用都会提供该变量的新副本，这些变量可以在该block中嵌套的其他block内作为常量和by-reference变量使用。

以下示例说明了非静态局部变量的使用：
```
int x = 123;

void (^printXAndY)(int) = ^(int y) {

    printf("%d %d\n", x, y);
};

printXAndY(456); // prints: 123 456
```
如上所述，试图在block内为x分配新值会导致错误：
```
int x = 123;

void (^printXAndY)(int) = ^(int y) {

    x = x + y; // error
    printf("%d %d\n", x, y);
};
```
要允许在block内更改变量，请使用`__block`存储类型修饰符。

### __block存储类型修饰符

可以通过使用`__block`存储类型修饰符来指定导入的变量是可变的，即可读可写。`__block`存储与局部变量的寄存器、动态和静态存储类型相似，但是相互排斥。

`__block`变量存储于变量的作用域与在变量的作用域内声明或创建的所有block和block副本共享的存储区域中。因此，如果在栈帧中声明的block的任何副本存活超出了栈帧的末尾（例如，通过在某处等待以后执行），那么此共享的存储区域将在栈帧的销毁中存活下来。给定作用域中的多个block可以同时使用共享变量。

作为优化，block存储从栈区开始--就像block自身一样。**如果使用Block_copy（或者在Objective-C中向block对象发送一个copy消息）复制block，那么变量将被复制到堆中**。因此，`__block`变量的地址会随着时间的推移而变化。

`__block`变量还有两个限制：它们不能是可变长度的数组，也不能是包含C99可变长度数组的结构。

以下示例说明了`__block`变量的使用：
```
__block int x = 123; //  x lives in block storage

void (^printXAndY)(int) = ^(int y) {

    x = x + y;
    printf("%d %d\n", x, y);
};

printXAndY(456); // prints: 579 456
// x is now 579
```
以下示例显示了具有多种变量类型的block的交互：
```
extern NSInteger CounterGlobal;
static NSInteger CounterStatic;

{
    NSInteger localCounter = 42;
    __block char localCharacter;

    void (^aBlock)(void) = ^(void) {
        ++CounterGlobal;
        ++CounterStatic;
        CounterGlobal = localCounter; // localCounter fixed at block creation
        localCharacter = 'a'; // sets localCharacter in enclosing scope
        };

    ++localCounter; // unseen by the block
    localCharacter = 'b';

    aBlock(); // execute the block
    // localCharacter now 'a'
}
```

### 对象和Block变量

block支持Objective-C对象、C++对象和其他block作为变量。

#### Objective-C对象

block被复制时，其会创建对block内使用的对象变量的强引用。如果使用block时，在block方法的实现中：
- 如果通过引用来访问实例变量，则会强引用`self`。
- 如果根据值来访问实例变量，则会强引用该变量。

以下示例说明了两种不同的情况：
```
dispatch_async(queue, ^{
    // instanceVariable is used by reference, a strong reference is made to self
    doSomethingWithObject(instanceVariable);
});


id localVariable = instanceVariable;
dispatch_async(queue, ^{
    /*
    localVariable is used by value, a strong reference is made to localVariable
    (and not to self).
    */
    doSomethingWithObject(localVariable);
});
```
**要覆盖特定对象变量的这种行为，可以使用`__block`存储类型修饰符来标记它。**

#### C++对象

一般而言，我们可以在block中使用C++对象。在一个成员函数中，对成员变量和函数的引用是通过隐式地导入它们的指针从而使它们可变。复制block时，有以下两点需要考虑：
- 如果有一个基于栈的C++对象的`__block`存储类，那么就使用通常的`copy`构造函数。
- 如果在block中使用任何基于栈的C++对象，则它必须具有`const copy`构造函数，然后使用该构造函数复制C++对象。

#### block

在复制block时，如果需要，该block对其他block的任何引用也会被复制（可以从顶部开始复制整个树）。如果存在block变量，并且在该block内引用其他block，那么这些block也将被复制。

## 使用Block

### 调用Block

如果声明一个block作为变量，则可以像使用函数一样使用它，如以下两个示例所示：
```
int (^oneFrom)(int) = ^(int anInt) {
    return anInt - 1;
};

printf("1 from 10 is %d", oneFrom(10));
// Prints "1 from 10 is 9"

float (^distanceTraveled)(float, float, float) = ^(float startingSpeed, float acceleration, float time) {

    float distance = (startingSpeed * time) + (0.5 * acceleration * time * time);
    
    return distance;
};

float howFar = distanceTraveled(0.0, 9.8, 1.0);
// howFar = 4.9
```

**但是我们在使用block时，经常将block作为参数传递给函数或方法。在这些情况下，我们通常会创建一个block“内联”。**

### 使用Block作为函数参数

可以像传递任何其他参数一样将block作为函数参数传递。然而，在许多情况下，我们不需要声明block。相反，我们只需要在它们被请求作为一个参数的地方内联地实现它们。以下示例使用`qsort_b`函数。`qsort_b`函数与标准的`qsort_r`函数类似，但将block作为其最终参数。
```
char *myCharacters[3] = { "TomJohn", "George", "Charles Condomine" };

qsort_b(myCharacters, 3, sizeof(char *), ^(const void *l, const void *r) {

    char *left = *(char **)l;
    
    char *right = *(char **)r;
    
    return strncmp(left, right, 1);
});
// Block implementation ends at "}"

// myCharacters is now { "Charles Condomine", "George", "TomJohn" }
```
注意，该block包含在函数的参数列表中。

下一个示例显示如何使用`dispatch_apply`函数的block。`dispatch_apply`的声明如下：
```
void dispatch_apply(size_t iterations, dispatch_queue_t queue, void (^block)(size_t));
```
该函数将一个block提交给调度队列以进行多个调用。它有3个参数：第一个参数指定要执行的迭代次数；第二个参数指定该block被提交到的队列；第三个参数是block本身，它又传递一个参数--迭代的当前索引。

我们可以轻松使用`dispatch_apply`来打印出迭代索引，如下所示：
```
#include <dispatch/dispatch.h>
size_t count = 10;
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

dispatch_apply(count, queue, ^(size_t i) {
    printf("%u\n", i);
});
```

### 使用Block作为方法参数

Cocoa提供了许多使用block的方法。与其他任何参数一样，将一个block作为方法参数传递。

以下示例确定出现在给定过滤器集合中的数组中前五个元素中的任何一个索引：
```
NSArray *array = @[@"A", @"B", @"C", @"A", @"B", @"Z", @"G", @"are", @"Q"];
NSSet *filterSet = [NSSet setWithObjects: @"A", @"Z", @"Q", nil];

BOOL (^test)(id obj, NSUInteger idx, BOOL *stop);

test = ^(id obj, NSUInteger idx, BOOL *stop) {

    if (idx < 5) {
        if ([filterSet containsObject: obj]) {
            return YES;
        }
    }
    return NO;
};

NSIndexSet *indexes = [array indexesOfObjectsPassingTest:test];

NSLog(@"indexes: %@", indexes);

/*
Output:
indexes: <NSIndexSet: 0x10236f0>[number of indexes: 2 (in 2 ranges), indexes: (0 3)]
*/
```
以下示例确定`NSSet`对象是否包含由局部变量指定的单词，如果包含就将另一个局部变量（found）的值设为`YES`（并停止搜索）。注意found也被声明为`__block`变量，并且该block被内联定义：
```
__block BOOL found = NO;

NSSet *aSet = [NSSet setWithObjects: @"Alpha", @"Beta", @"Gamma", @"X", nil];

NSString *string = @"gamma";

[aSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
    if ([obj localizedCaseInsensitiveCompare:string] == NSOrderedSame) {
        *stop = YES;
        found = YES;
    }
}];

// At this point, found == YES
```

### 复制Block

通常，我们不需要对block执行`copy`（或者`retain`）操作。如果我们希望在声明block的作用域被销毁后仍然能使用该block，则仅需要对block执行一次copy操作。复制会将block移动到**堆区**。

可以使用C函数来复制和释放block：
```
Block_copy();
Block_release();
```
**为了避免内存泄漏，必须在调用`Block_copy()`函数之后，对应地调用一次`Block_release`函数。**

### 使用时需要避免的模式

block语法表达（既^{...}）是表示block的**栈区**局部数据结构的地址。因此，**栈区**局部数据结构的范围是包含block主体实现语句的，所以应避免以下示例中显示的模式：
```
void dontDoThis() {

    void (^blockArray[3])(void);  // an array of 3 block references

    for (int i = 0; i < 3; ++i)
    {
        blockArray[i] = ^{ printf("hello, %d\n", i); };
        
        // WRONG: The block literal scope is the "for" loop.
    }
}

void dontDoThisEither() {

    void (^block)(void);

    int i = random():
    
    if (i > 1000)
    {
        block = ^{ printf("got i at: %d\n", i); };
        
        // WRONG: The block literal scope is the "then" clause.
    }
    // ...
}
```

### 调试

可以在block内设置断点和单一步骤。可以使用invoke-block从GDB会话中调用block，如下所示：
```
$ invoke-block myBlock 10 20
```
如果想传递一个C字符串，必须引用它。例如，要将此字符串传递到`doSomethingWithString`block，可以编写以下内容：
```
$ invoke-block doSomethingWithString "\"this string\""
```
