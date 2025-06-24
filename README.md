# Core Data Staged Migrations Warning Demo

This project demonstrates the "Multiple NSEntityDescriptions claim the NSManagedObject subclass" warning that occurs when using Core Data's Staged Migrations.

## Issue

When implementing Core Data Staged Migrations, you may encounter these warnings/errors:

```
warning: Multiple NSEntityDescriptions claim the NSManagedObject subclass 'MyEntity' so +entity is unable to disambiguate.
warning: 'MyEntity' (0x60000350d6b0) from NSManagedObjectModel (0x60000213a8a0) claims 'MyEntity'.
error: +[MyEntity entity] Failed to find a unique match for an NSEntityDescription to a managed object subclass
```

## Context

This is a response to the Apple Developer Forums discussion: https://developer.apple.com/forums/thread/779255

The issue occurs when:
- Using NSManagedObject
- Setting `NSPersistentStoreStagedMigrationManagerOptionKey`
- Fetching or saving entities to the managed object context

## Feedback
This issue has been reported to Apple via Feedback Assistant.
**Feedback ID:** FB18334791
