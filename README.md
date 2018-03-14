# Block编程指南 ----  Block入门

## 概述



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
NSArray *stringsArray = @[ @"string 1",
@"String 21",
@"string 12",
@"String 11",
@"String 02" ];

static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch |
NSWidthInsensitiveSearch | NSForcedOrderingSearch;
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

block的一个强力特征是其可以修改与其在相同作用域中的变量，使用`__block`存储类型修饰符来指示一个block可以修改变量。改写上面的示例，使用block变量来计算比较的字符串数量，如下所示。为了说明，在这种情况下block被直接使用并block中使用currentLocale作为只读变量：
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

<span id="jump">
## 声明和创建Block
</span>


