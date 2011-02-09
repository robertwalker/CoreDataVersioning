//
//  CoreDataVersioning_AppDelegate.h
//  CoreDataVersioning
//
//  Created by Robert Walker on 1/11/11.
//  Copyright Robert Walker 2011 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CoreDataVersioning_AppDelegate : NSObject 
{
    NSWindow *window;
    NSTextField *versionLabel;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSTextField *versionLabel;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;
- (IBAction)resetPersistentStore:(id)sender;
- (IBAction)migrateUsingAutoLightweight:(id)sender;

@end
