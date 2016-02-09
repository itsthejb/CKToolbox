[![BuildMaster](https://travis-ci.org/itsthejb/CKToolbox.svg?branch=master)](https://travis-ci.org/itsthejb/CKToolbox)
[![BuildDev](https://travis-ci.org/itsthejb/CKToolbox.svg?branch=dev)](https://travis-ci.org/itsthejb/CKToolbox)
[![Pod Status](https://img.shields.io/cocoapods/v/CKToolbox.svg)](http://www.cocoapods.org/?q=CKToolbox)
[![Pod License](https://img.shields.io/cocoapods/l/CKToolbox.svg)](http://www.cocoapods.org/?q=CKToolbox)
[![Pod Platform](https://img.shields.io/cocoapods/p/CKToolbox.svg)](http://www.cocoapods.org/?q=CKToolbox)

# [CKToolbox](http://itsthejb.github.io/CKToolbox/)

A set of helpers and features for working with [Facebook ComponentKit](http://componentkit.org/). This library, when installed via [Cocoapods](https://cocoapods.org/), is modular. It currently has the following modules:

1. [CKTableViewTransactionalDataSource](#CKTableViewTransactionalDataSource)
2. [CKCollectionViewDataSourceChangesetBuilder](#CKCollectionViewDataSourceChangesetBuilder)
3. [CKTransactionalComponentDataSourceRemoveAll](#CKTransactionalComponentDataSourceRemoveAll)

## <a id="CKTableViewTransactionalDataSource"></a> 1. CKTableViewTransactionalDataSource

[ComponentKit](http://componentkit.org/) provides `CKCollectionViewTransactionalDataSource` as a `CKTransactionalComponentDataSource` interface for `UICollectionView`. `CKTableViewTransactionalDataSource` provides the same, but for `UITableView`, albeit with a few necessary and useful differences and additions.

### But I Thought UICollectionView > UITableView?

Yes, and no. `UICollectionView` provides a great deal of flexibility, but a lot less out-of-the-box. `UITableView`'s strength is its familiar and user friendly native features, such as:

* Editing mode, including swipe-to-delete/edit, and reordering. Also, custom editing actions for iOS 8.0+
* Simple "floating" section header/footer titles, or views
* Native accesories, and accessory view support
* Item separators, and styles
* Whole table header and footer views
* Section title index scroll bar

All these are possible with `UICollectionView`, but the implementations are up to you.

The basic implementation of `CKTableViewTransactionalDataSource` is quite trivial, however additional API is necessary in order to expose the full power of `UITableView`.

### CKTableViewTransactionalDataSourceCellConfiguration

`UICollectionView` delegates quite a lot of its power to its layout object. This is useful for ComponentKit, since we can do most customisation relating to animations, etc., through an entirely separate main thread object that needn't be touched by CK. Not so for `UITableView`, though. For example, native animations must be specified when the rows and sections are added/removed/updated/deleted inside the `-beginUpdates`, `-endUpdates` transaction. In order to expose these features, `CKToolbox` provides `CKTableViewTransactionalDataSourceCellConfiguration`, a simple value object that can configure:

* Cell animations for various operations
* Styles - selection, and focus
* Options, such as indentation, editing and reordering
* Layout
* Accessories
* Full animation kill switch

#### Usage

A default configuration can be passed to the initializer, and override configurations provided in the `userInfo` dictionary argument with the `CKTableViewTransactionalDataSourceCellConfigurationKey` or one of the `cellConfiguration` argument methods can be used. 

The expected usage pattern is:

* Pass the default cell configuration when instantiating the data source.
* Take a copy of the default configuration (`-[CKTableViewTransactionalDataSource cellConfiguration]`, which always returns a copy), mutate any properties that you wish to override for an update operation. Pass this object in the data source update. It will override the default configuration *for that operation only*.
* There is no way to change the default configuration after instantiation. This is by design, assuming [there are no reasonable cases when this might be wanted](mailto:jon.crooke@gmail.com).

A good example of this pattern is used in the provided demo app: since the data source uses a `-beginUpdates`/`-endUpdates` transaction to enqueue all changes, there will be animations when the initial content is inserted. Perhaps we *don't* want that, would like to see the initial content appear immediately, but *would* like animations in all later updates. In that case:

* The default configuration specifies the animations we would like later.
* When enqueing the initial content, we take a copy of the configuration, disable all animations with the `-animationsDisabled` property and use this configuration to override the default for *this operation only*.
* Content appears immediately with the overridden config, but all later updates will use the default configuration.

### CKTransactionalDataSourceInterface

Both `UICollectionView` and `UITableView` share very similar APIs. As such, 
`CKTableViewTransactionalDataSource` actually implements `CKTransactionalDataSourceInterface`, which abstracts the most essential parts of `CKCollectionViewTransactionalDataSource`'s interface. Therefore, should you wish to implement some architecture that is agnostic of the eventual output view of a component-based collection, you could provide an interface of type `id <CKTransactionalDataSourceInterface>`. This way, other than instantiation, all collection operations are essentially the same.

### Demo App

A demo app is provided, a simple reference app with a list of endangered animals from the [WWF Species Directory](https://www.worldwildlife.org/species/directory?direction=desc&sort=extinction_status). Swipe the cells to reveal additional features.

### Current Issues

* Many of `UITableView`'s non-primary features are only roughly supported in the initial version. There may be a lot missing
* Resizing with the reorder control currently not working, or at least as far as it seems
* Device rotation component resizing (via `updateConfiguration:mode:...`) seems a little unsatisfactory at the moment
* Configuration of the underlying tableview cell is not *directly* supported right now. For example, you will probably want to adjust the cell's background color to match your UI. This could be quite easily added to `CKTableViewTransactionalDataSourceCellConfiguration`, but for now can also be supported in `UITableViewDelegate` methods. For example, the demo app uses `-tableView:willDisplayCell:forRowAtIndexPath:`.

## <a id="CKCollectionViewDataSourceChangesetBuilder"></a> 2. CKCollectionViewDataSourceChangesetBuilder

CKCollectionViewDataSourceChangesetBuilder is a DSL builder for [ComponentKit](http://componentkit.org/)'s `CKTransactionalComponentDataSourceChangeset`. It is heavily inspired by [Masonry](https://github.com/SnapKit/Masonry), and should allow you to write very readable code for building your changesets.

### How Do I Use It?

`CKCollectionViewDataSourceChangesetBuilder` uses verbs, nouns and prepositions in order to allow you to express your changeset builds in readable English, [with just a few exceptions](#helper-macros). A few examples will make this clearer:

		[CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
		  builder.insert.section.at.index(0);
		  builder.insert.item(@"Foo").at.indexPath([NSIndexPath indexPathForItem:1 inSection:4]);
		  builder.remove.section.at.index(1);
		  builder.move.section.at.index(0).to.index(4);
		}];

Due to the limited number of keywords, the possible combinations should hopefully be fairly self-explanatory. The builder has been written to throw useful exceptions when the syntax is misused.

`CKCollectionViewDataSourceChangesetBuilderTests` provides examples of all of the syntax combinations, so please take a look there first.

### Helper Macros

* `ck_indexPath(ITEM, SECTION)` saves constant use of `[NSIndexPath indexPathForItem:inSection:]`.

The following two macros aim to compensate for the lack of default arguments in Objective-C; when moving or removing items we need to reuse the verb `item`. However, since we have no object to *insert* the argument must be `nil`. This wouldn't be nearly as readable. Instead you can use:

* `ck_removeItem` instead of `remove.item(nil)`.
* `ck_moveItem` instead of `move.item(nil)`.

### Why No Swift?

`ComponentKit` is written primarily in Obj-C++, which means you will usually be using it from within Obj-C++ contexts. Whilst it's possible you could create changesets from Swift contexts, I don't believe this is enough to justify another implementation at this time. Of course, if someone would like to implement it then I'll be happy to receive a PR!

## <a id="CKTransactionalComponentDataSourceRemoveAll"></a> 3. CKTransactionalComponentDataSourceRemoveAll

ComponentKit directly supports inserting content, and explicitly deleting items and sections, but does not directly support easily wiping the data source's complete content. The `CKTransactionalComponentDataSourceRemoveAll` provides the method `- (CKTransactionalComponentDataSourceChangeset*)removeAllChangeset` which returns a change set that can be used to remove all items and sections currently present in the data source. Implementations are provided for `CKTransactionalComponentDataSourceState` and `CKCollectionViewTransactionalDataSource`. Additionally, [CKTableViewTransactionalDataSource](##2. CKTableViewTransactionalDataSource) implements this protocol.

---

Have fun!
---------

[MIT Licensed](http://jc.mit-license.org/) >> [jon.crooke@gmail.com](mailto:jon.crooke@gmail.com)
