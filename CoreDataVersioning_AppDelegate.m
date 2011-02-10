//
//  CoreDataVersioning_AppDelegate.m
//  CoreDataVersioning
//
//  Created by Robert Walker on 1/11/11.
//  Copyright Robert Walker 2011 . All rights reserved.
//

#import "CoreDataVersioning_AppDelegate.h"

@interface CoreDataVersioning_AppDelegate ()

- (void)removePersistentStore;
- (void)seedPersistentStore;
- (NSManagedObjectModel *)model1;
- (NSManagedObjectModel *)model2;
- (NSURL *)sourceStoreURL;
- (NSURL *)destinationStoreURL;

@end

@implementation CoreDataVersioning_AppDelegate

@synthesize window, messageTextField;

- (void)awakeFromNib
{
    [self.messageTextField setStringValue:@""];
}

/**
    Returns the support directory for the application, used to store the Core Data
    store file.  This code uses a directory named "CoreDataVersioning" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"CoreDataVersioning"];
}

/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The directory for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

    if (persistentStoreCoordinator) return persistentStoreCoordinator;

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"storedata"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                                configuration:nil 
                                                URL:url 
                                                options:nil 
                                                error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    

    return persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *)managedObjectContext {

    if (managedObjectContext) return managedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];

    return managedObjectContext;
}

/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

- (void)removePersistentStore
{
    NSError *error = NULL;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSString *storePath = [applicationSupportDirectory stringByAppendingPathComponent: @"storedata"];
    if ([fileManager fileExistsAtPath:storePath]) {
        [fileManager removeItemAtPath:storePath error:&error];
        if (error) {
            [[NSApplication sharedApplication] presentError:error];
        }
    }
}

- (void)seedPersistentStore
{
    NSError *error = NULL;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    // Create a Chef, Recipe and Ingredient
    NSManagedObject *newChef = [NSEntityDescription
                                insertNewObjectForEntityForName:@"Chef"
                                inManagedObjectContext:context];
    NSManagedObject *newRecipe = [NSEntityDescription
                                  insertNewObjectForEntityForName:@"Recipe"
                                  inManagedObjectContext:context];
    NSManagedObject *newIngredient = [NSEntityDescription
                                      insertNewObjectForEntityForName:@"Ingredient"
                                      inManagedObjectContext:context];
    
    // Setup the attributes
    [newChef setValue:@"Wolfgang Puck" forKey:@"name"];
    [newChef setValue:@"World famous chef" forKey:@"training"];
    [newRecipe setValue:@"Braised Chestnuts" forKey:@"name"];
    [newIngredient setValue:@"Chestnuts" forKey:@"name"];
    [newIngredient setValue:@"2 pounds" forKey:@"amount"];
    
    // Setup the relationships
    [newRecipe setValue:newChef forKey:@"chef"];
    [newIngredient setValue:newRecipe forKey:@"recipe"];
    [context save:&error];
    if (!error) {
        [self.messageTextField setStringValue:@"Persistent store reset."];
    } else {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)resetPersistentStore:(id)sender
{
    [self removePersistentStore];
    [self seedPersistentStore];
}

- (NSManagedObjectModel *)model1 {
    NSString *modelPath = [[[[[NSBundle mainBundle] resourcePath]
                             stringByAppendingPathComponent:@"CoreDataVersioning_DataModel.momd"]
                            stringByAppendingPathComponent:@"/Version_1.0"]
                           stringByAppendingPathExtension:@"mom"];
    return [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]] autorelease];
}

- (NSManagedObjectModel *)model2 {
    NSString *modelPath = [[[[[NSBundle mainBundle] resourcePath]
                             stringByAppendingPathComponent:@"CoreDataVersioning_DataModel.momd"]
                            stringByAppendingPathComponent:@"/Version_1.1"]
                           stringByAppendingPathExtension:@"mom"];
    return [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]] autorelease];
}

- (NSURL *)sourceStoreURL {
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSURL *storeURL = [NSURL fileURLWithPath:[applicationSupportDirectory stringByAppendingPathComponent: @"storedata"]];
    return storeURL;
}

- (NSURL *)destinationStoreURL {
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSURL *storeURL = [NSURL fileURLWithPath:[applicationSupportDirectory stringByAppendingPathComponent: @"storedata_2"]];
    return storeURL;
}

/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction)saveAction:(id)sender {

    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)migrateUsingAutoLightweight:sender {
    [self.messageTextField setStringValue:@""];

    NSError *error = NULL;
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc]
                                         initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil URL:[self sourceStoreURL]
                                 options:options error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
    [self.messageTextField setStringValue:@"Automatic migration complete."];
    [psc release];
}

- (IBAction)migrateUsingManualLightweight:sender {
    [self.messageTextField setStringValue:@""];

    NSError *error = NULL;
    NSMappingModel *mappingModel = [NSMappingModel
                                    inferredMappingModelForSourceModel:[self model1]
                                    destinationModel:[self model2]
                                    error:&error];
    if (error) { 
        [[NSApplication sharedApplication] presentError:error];
        return;
    }
    
    NSValue *classValue = [[NSPersistentStoreCoordinator registeredStoreTypes]
                           objectForKey:NSSQLiteStoreType];
    Class sqliteStoreClass = (Class)[classValue pointerValue];
    Class sqliteStoreMigrationManagerClass = [sqliteStoreClass migrationManagerClass];
    
    NSMigrationManager *manager = [[sqliteStoreMigrationManagerClass alloc]
                                   initWithSourceModel:[self model1] destinationModel:[self model2]];
    
    if (![manager migrateStoreFromURL:[self sourceStoreURL]
                                 type:NSSQLiteStoreType
                              options:nil
                     withMappingModel:mappingModel
                     toDestinationURL:[self destinationStoreURL]
                      destinationType:NSSQLiteStoreType
                   destinationOptions:nil
                                error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    } else {
        [self.messageTextField setStringValue:@"Manual migration complete."];
    }
    [manager release];
}

/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    if (!managedObjectContext) return NSTerminateNow;

    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![managedObjectContext hasChanges]) return NSTerminateNow;

    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
    
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.

        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
                
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;

        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;

    }

    return NSTerminateNow;
}


/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void)dealloc {
    [window release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
	
    [super dealloc];
}

@end
