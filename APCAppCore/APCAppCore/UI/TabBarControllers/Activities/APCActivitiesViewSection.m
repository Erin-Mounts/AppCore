//
//  APCActivitiesViewSection.m
//  APCAppCore
//
//  Copyright (c) 2015, Apple Inc. All rights reserved. 
//  
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  
//  1.  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  
//  2.  Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution. 
//  
//  3.  Neither the name of the copyright holder(s) nor the names of any contributors 
//  may be used to endorse or promote products derived from this software without 
//  specific prior written permission. No license is granted to the trademarks of 
//  the copyright holders even if such marks are included in this software. 
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
//

#import "APCActivitiesViewSection.h"
#import "NSDate+Helper.h"
#import "APCTaskGroup.h"
#import "APCLocalization.h"

static NSDateFormatter *headerViewDateFormatterDebugging        = nil;
static NSDateFormatter *headerViewDateFormatterToday            = nil;

static NSString * const kAPCSectionHeaderDateFormatDebugging    = @"eeee, MMMM d, yyyy";
static NSString * const kAPCSectionHeaderDateFormatToday        = @"eeee, MMMM d";


@interface APCActivitiesViewSection ()

- (instancetype) init NS_DESIGNATED_INITIALIZER;

@property (readonly) NSDate *yesterday;
@property (readonly) NSDate *today;
@property (readonly) NSDate *tomorrow;
@property (readonly) NSDate *myDateRoundedToMidnight;
@end


@implementation APCActivitiesViewSection

+ (void)initialize
{
    void (^localizeBlock)() = [^{
        headerViewDateFormatterDebugging = [NSDateFormatter new];
        headerViewDateFormatterDebugging.timeZone = [NSTimeZone localTimeZone];
        headerViewDateFormatterDebugging.dateFormat = kAPCSectionHeaderDateFormatDebugging;
        
        headerViewDateFormatterToday = [NSDateFormatter new];
        headerViewDateFormatterToday.timeZone = [NSTimeZone localTimeZone];
        [headerViewDateFormatterToday setLocalizedDateFormatFromTemplate:kAPCSectionHeaderDateFormatToday];
    } copy];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSCurrentLocaleDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull __unused note) {
        localizeBlock();
    }];
    localizeBlock();
}

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        _date = nil;
        _isKeepGoingSection = NO;
        _presumedSystemDate = nil;
        _taskGroups = nil;
    }

    return self;
}

- (instancetype) initWithDate: (NSDate *) date
                        tasks: (NSArray *) arrayOfTaskGroupObjects
       usingDateForSystemDate: (NSDate *) potentiallyFakeSystemDate
{
    self = [self init];

    if (self)
    {
        _date = date;
        _taskGroups = arrayOfTaskGroupObjects;
        _presumedSystemDate = potentiallyFakeSystemDate;
    }

    return self;
}

- (instancetype) initAsKeepGoingSectionWithTasks: (NSArray *) arrayOfTaskGroupObjects
{
    self = [self init];

    if (self)
    {
        _isKeepGoingSection = YES;
        _taskGroups = arrayOfTaskGroupObjects;
    }

    return self;
}

- (NSDate *) today
{
    return self.presumedSystemDate.startOfDay;
}

- (NSDate *) tomorrow
{
    return self.presumedSystemDate.dayAfter.startOfDay;
}

- (NSDate *) yesterday
{
    return self.presumedSystemDate.dayBefore.startOfDay;
}

- (NSDate *) myDateRoundedToMidnight
{
    return self.date.startOfDay;
}

- (BOOL) isTodaySection
{
    BOOL   isToday = [self.myDateRoundedToMidnight isEqualToDate: self.today];
    return isToday;
}

- (BOOL) isYesterdaySection
{
    BOOL   isYesterday = [self.myDateRoundedToMidnight isEqualToDate: self.yesterday];
    return isYesterday;
}

- (BOOL) isEmpty
{
    return self.taskGroups.count == 0;
}

- (NSString *) title
{
    NSString *todayTitleFormat = NSLocalizedStringWithDefaultValue(@"APC_ACTIVITIES_TITLE_TODAY_FORMAT", @"APCAppCore", APCBundle(), @"Today, %@", @"Format for title for Activities view section for today's activities, to be filled in with today's date");
    NSString *todayTitle = [NSString stringWithFormat: todayTitleFormat, [headerViewDateFormatterToday stringFromDate: self.myDateRoundedToMidnight]];

    NSString *result = (self.isKeepGoingSection                                      ? NSLocalizedStringWithDefaultValue(@"APC_ACTIVITIES_TITLE_KEEP_GOING", @"APCAppCore", APCBundle(), @"Keep Going!", @"Title for Activities view section for optional activities") :
                        [self.myDateRoundedToMidnight isEqualToDate: self.today]     ? todayTitle :
                        [self.myDateRoundedToMidnight isEqualToDate: self.yesterday] ? NSLocalizedStringWithDefaultValue(@"APC_ACTIVITIES_TITLE_YESTERDAY", @"APCAppCore", APCBundle(), @"Yesterday", @"Title for Activities view section for yesterday's incomplete activities") :
                        [self.myDateRoundedToMidnight isEqualToDate: self.tomorrow]  ? NSLocalizedStringWithDefaultValue(@"APC_ACTIVITIES_TITLE_TOMORROW", @"APCAppCore", APCBundle(), @"Tomorrow", @"Title for Activities view section for tomorrow's activities") :
                        [headerViewDateFormatterDebugging stringFromDate: self.myDateRoundedToMidnight]
                        );

    return result;
}

- (NSString *) subtitle
{
    NSString *result = (self.isKeepGoingSection ? NSLocalizedStringWithDefaultValue(@"APC_ACTIVITIES_SUBTITLE_KEEP_GOING", @"APCAppCore", APCBundle(), @"Try one of these extra activities\nto enhance your experience in your study.", @"Subtitile for Activities view section for optional activities") :
                        [self.myDateRoundedToMidnight isEqualToDate: self.today] ? NSLocalizedStringWithDefaultValue(@"APC_ACTIVITIES_SUBTITLE_TODAY", @"APCAppCore", APCBundle(), @"To start an activity, select from the list below.", @"Subtitle Activities view section for today's scheduled activities") :
                        [self.myDateRoundedToMidnight isEqualToDate: self.yesterday] ? NSLocalizedStringWithDefaultValue(@"APC_ACTIVITIES_SUBTITLE_YESTERDAY", @"APCAppCore", APCBundle(), @"Below are your incomplete tasks from yesterday. These are for reference only.", @"Subtitle for Activities view section for yesterday's incomplete activities") :
                        nil
                        );

    return result;
}

/**
 Deprecated. Old name (old concept, actually) for
 -reduceToIncompleteTasksOnTheirLastLegalDay.
 */
- (void) removeFullyCompletedTasks
{
    [self reduceToIncompleteExpiredTasks];
}

- (void) reduceToIncompleteExpiredTasks
{
    NSIndexSet *indexesOfTaskGroupsWeWant = [self.taskGroups indexesOfObjectsPassingTest: ^BOOL (APCTaskGroup *taskGroup,
                                                                                                 NSUInteger __unused taskGroupIndex,
                                                                                                 BOOL __unused *stopIterating) {
        BOOL keepThisOne = NO;
        
        if (! taskGroup.isFullyCompleted && [taskGroup expiresOnOrBeforeDate:self.today])
        {
            keepThisOne = YES;
        }

        return keepThisOne;
    }];

    NSArray *filteredTasks = [self.taskGroups objectsAtIndexes: indexesOfTaskGroupsWeWant];
    self.taskGroups = filteredTasks;
}

@end
