Authosynth allows you to automatically convert a NSDictionary onto properties of a class.

* Make the class a subclass of Loadable.
* Create an instance using one of

  [MyClass withDictionary:@{@"key", @"value"]]

  [MyClass withJsonString:@"{"key": "value"}]

  [MyClass withJsonData:jsonDataVaraible]

It handles complex and primitive types automatically, for example you can load the class below:

  @interface PrimativesModel : Loadable
  
	@property (assign) BOOL a;
	@property (assign) char b;
	@property (assign) int c;
	@property (assign) short d;
	@property (assign) long e;
	@property (assign) long long f;
	@property (assign) unsigned char g;
	@property (assign) unsigned int h;
	@property (assign) unsigned short i;
	@property (assign) unsigned long j;
	@property (assign) unsigned long long k;
	@property (assign) float l;
	@property (assign) double m;

	@end
	
It handles NSDate properties like DateModel below. In this case the value is expected to be in the json as a number of seconds since 1970.

	@interface DateModel : Loadable

	@property (strong) NSDate *date;

	@end

Loadable objects can have other Loadable objects as properties. Arrays of other loadable objects are also supported using the LoadbleArray macro.

	@interface InceptionModel : Loadable

	@property (strong) InceptionModel *inception;
	@property (strong) DateModel *model;
	@property (strong) LoadableArray(PrimativesModel, primatives);
	@property (strong) NSArray *numbers;
	@property (strong) NSDictionary *dictionary;

	@end

If a name overlaps a reserved keyword in Objective-C, add an underscore before the name.

	@interface KeywordsModel : Loadable

	@property (assign) int _void;
	@property (assign) int _char;
	@property (assign) int _short;
	@property (assign) int _int;
	@property (assign) int _long;
	@property (assign) int _float;
	@property (assign) int _double;
	@property (assign) int _signed;
	@property (assign) int _unsigned;
	@property (assign) int _id;
	@property (assign) int _const;
	@property (assign) int _volatile;
	@property (assign) int _in;
	@property (assign) int _out;
	@property (assign) int _inout;
	@property (assign) int _bycopy;
	@property (assign) int _byref;
	@property (assign) int _oneway;
	@property (assign) int _self;
	@property (assign) int _super;
	@property (assign) int _default;

	@end

To install in your project, drag Loadable.h and Loadable.m into the left project panel and be sure "copy files into project" is checkmarked.
