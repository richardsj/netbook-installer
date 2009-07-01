//
//  main.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/18/09.
//  Copyright 2009. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "SystemInformation.h"
#import "InstallerCLI.h"

int main(int argc, char *argv[])
{	
	
	// TODO: make sure everything is realeased properly... (It's not)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary* infoDict;
	SystemInformation* systemInfo = [[SystemInformation alloc] init];
	InstallerCLI*	installer	= [[InstallerCLI alloc] init];

	[installer mountRamDisk];
	infoDict = [[NSBundle mainBundle] infoDictionary];
	
	[systemInfo determineInstallState];
	
	if(argc > 1)
	{
		NSLog([[NSString alloc] initWithCString:argv[1]]);
		[systemInfo determinePartitionFromPath: [[NSString alloc] initWithCString:argv[1]]];
		// Else we use the default of /
	}

	[installer systemInfo: systemInfo];
	[installer remountTargetWithPermissions];
	[installer removePrevExtra];
	
	/// Time to actualy do the install
	[installer installExtraFiles];
	// Install and patch extensions
	
	[installer makeDir: [systemInfo extensionsFolder]];
		
	[installer installExtensions];
	[installer patchGMAkext];
	[installer patchFramebufferKext];
	[installer patchIO80211kext];
	[installer patchBluetooth];
	


	[installer installDisplayProfile];
	[installer installPrefPanes];
	[installer installLaunchAgents];
		
	[installer installSystemConfiguration];
		
	[installer installDSDT];
		

			
			
	[installer setQuietBoot:	NO];
	[installer dissableHibernation:	YES];

	//	[installer setRemoteCD:			YES]; // This is not possilbe when running as root.
	[installer installBootloader: DEFAULT_BOOTLOADER];
	
	// Install the gui
	[installer copyFrom:@"/Applications/NetbookInstaller.app" toDir:[[systemInfo installPath] stringByAppendingString:@"/Applications/"]];

	
	if([systemInfo targetOS] < KERNEL_VERSION_10_5_6)	// Less than Mac OS X 10.5.4
	{
		// This is ONLY going to be run from the install dvd, so we can copy these from the /
		[installer copyFrom:@"/Extra/Extensions.mkext" toDir:[[systemInfo installPath] stringByAppendingString:@"/Extra/"]];
		[installer copyFrom:@"/mach_kernel.10.5.6" toDir:[[systemInfo installPath] stringByAppendingString:@"/"]];
		[installer useLatestKernel];
		
	} else
	{
		[installer copyDependencies];
		[installer generateExtensionsCache];
		[installer useSystemKernel];
	}	
	
	[installer hideFiles];
	[installer unmountRamDisk];

	NSLog(@"Done");
	
	[pool release];
}