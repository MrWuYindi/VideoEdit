//
//  XNGVideoEditManager.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/13.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGVideoEditManager.h"
#import <AVFoundation/AVFoundation.h>

@interface XNGVideoEditManager ()

@end
@implementation XNGVideoEditManager

+ (id)shareVideoEditManager {
    static XNGVideoEditManager * _manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[XNGVideoEditManager alloc] init];
    });
    return _manager;
}

- (NSURL *)removeOriginalSoundFrom:(NSURL *)originalAudioVideo {
    
    
    return [[NSURL alloc] init];
}












////抽取原视频的音频与需要的音乐混合
//-(void)addmusic:(id)sender
//{
//    AVMutableComposition *composition =[AVMutableComposition composition];
//    audioMixParams =[[NSMutableArray alloc] initWithObjects:nil];
//
//    //录制的视频
//    NSURL *video_inputFileUrl = [self getLocalVideoPath];
//    AVURLAsset *songAsset =[AVURLAsset URLAssetWithURL:video_inputFileUrl options:nil];
//    CMTime startTime =CMTimeMakeWithSeconds(0,songAsset.duration.timescale);
//    CMTime trackDuration =songAsset.duration;
//
//    //获取视频中的音频素材
//    [selfsetUpAndAddAudioAtPath:video_inputFileUrltoComposition:compositionstart:startTimedura:trackDurationoffset:CMTimeMake(14*44100,44100)];
//
//    //本地要插入的音乐
//    NSString *bundleDirectory =[[NSBundlemainBundle]bundlePath];
//    NSString *path = [bundleDirectorystringByAppendingPathComponent:@"30secs.mp3"];
//    NSURL *assetURL2 =[NSURLfileURLWithPath:path];
//    //获取设置完的本地音乐素材
//    [selfsetUpAndAddAudioAtPath:assetURL2toComposition:compositionstart:startTimedura:trackDurationoffset:CMTimeMake(0,44100)];
//
//    //创建一个可变的音频混合
//    AVMutableAudioMix *audioMix =[AVMutableAudioMixaudioMix];
//    audioMix.inputParameters =[NSArrayarrayWithArray:audioMixParams];//从数组里取出处理后的音频轨道参数
//
//    //创建一个输出
//    AVAssetExportSession *exporter =[[AVAssetExportSessionalloc]
//                                     initWithAsset:composition
//                                     presetName:AVAssetExportPresetAppleM4A];
//    exporter.audioMix = audioMix;
//    exporter.outputFileType=@"com.apple.m4a-audio";
//    NSString* fileName =[NSStringstringWithFormat:@"%@.mov",@"overMix"];
//    //输出路径
//    NSString *exportFile =[NSStringstringWithFormat:@"%@/%@",[selfgetLibarayPath], fileName];
//
//    if([[NSFileManagerdefaultManager]fileExistsAtPath:exportFile]) {
//        [[NSFileManagerdefaultManager]removeItemAtPath:exportFileerror:nil];
//    }
//    NSLog(@"是否在主线程1%d",[NSThreadisMainThread]);
//    NSLog(@"输出路径===%@",exportFile);
//
//    NSURL *exportURL =[NSURLfileURLWithPath:exportFile];
//    exporter.outputURL = exportURL;
//    self.mixURL =exportURL;
//
//    [exporterexportAsynchronouslyWithCompletionHandler:^{
//        int exportStatus =(int)exporter.status;
//        switch (exportStatus){
//            caseAVAssetExportSessionStatusFailed:{
//                NSError *exportError =exporter.error;
//                NSLog(@"错误，信息: %@", exportError);
//                [MBProgressHUDhideHUDForView:self.viewanimated:YES];
//                break;
//            }
//            caseAVAssetExportSessionStatusCompleted:{
//                NSLog(@"是否在主线程2%d",[NSThreadisMainThread]);
//                NSLog(@"成功");
//                //最终混合
//                [selftheVideoWithMixMusic];
//                break;
//            }
//        }
//    }];
//
//}
//
////最终音频和视频混合
//-(void)theVideoWithMixMusic
//{
//    NSError *error =nil;
//    NSFileManager *fileMgr =[NSFileManagerdefaultManager];
//    NSString *documentsDirectory =[NSHomeDirectory()
//                                   stringByAppendingPathComponent:@"Documents"];
//    NSString *videoOutputPath =[documentsDirectorystringByAppendingPathComponent:@"test_output.mp4"];
//    if ([fileMgrremoveItemAtPath:videoOutputPatherror:&error]!=YES) {
//        NSLog(@"无法删除文件，错误信息：%@",[error localizedDescription]);
//    }
//
//    //声音来源路径（最终混合的音频）
//    NSURL   *audio_inputFileUrl =self.mixURL;
//
//    //视频来源路径
//    NSURL   *video_inputFileUrl = [NSURLfileURLWithPath:self.videoPath];
//
//    //最终合成输出路径
//    NSString *outputFilePath =[documentsDirectorystringByAppendingPathComponent:@"final_video.mp4"];
//    NSURL   *outputFileUrl = [NSURLfileURLWithPath:outputFilePath];
//
//    if([[NSFileManagerdefaultManager]fileExistsAtPath:outputFilePath])
//        [[NSFileManagerdefaultManager]removeItemAtPath:outputFilePatherror:nil];
//
//    CMTime nextClipStartTime =kCMTimeZero;
//
//    //创建可变的音频视频组合
//    AVMutableComposition* mixComposition =[AVMutableCompositioncomposition];
//
//    //视频采集
//    AVURLAsset* videoAsset =[[AVURLAssetalloc]initWithURL:video_inputFileUrloptions:nil];
//    CMTimeRange video_timeRange =CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
//    AVMutableCompositionTrack*a_compositionVideoTrack = [mixCompositionaddMutableTrackWithMediaType:AVMediaTypeVideopreferredTrackID:kCMPersistentTrackID_Invalid];
//    [a_compositionVideoTrackinsertTimeRange:video_timeRangeofTrack:[[videoAssettracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0]atTime:nextClipStartTimeerror:nil];
//
//    //声音采集
//    AVURLAsset* audioAsset =[[AVURLAssetalloc]initWithURL:audio_inputFileUrloptions:nil];
//    CMTimeRange audio_timeRange =CMTimeRangeMake(kCMTimeZero,videoAsset.duration);//声音长度截取范围==视频长度
//    AVMutableCompositionTrack*b_compositionAudioTrack = [mixCompositionaddMutableTrackWithMediaType:AVMediaTypeAudiopreferredTrackID:kCMPersistentTrackID_Invalid];
//    [b_compositionAudioTrackinsertTimeRange:audio_timeRangeofTrack:[[audioAssettracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0]atTime:nextClipStartTimeerror:nil];
//
//    //创建一个输出
//    AVAssetExportSession* _assetExport =[[AVAssetExportSessionalloc]initWithAsset:mixCompositionpresetName:AVAssetExportPresetMediumQuality];
//    _assetExport.outputFileType =AVFileTypeQuickTimeMovie;
//    _assetExport.outputURL =outputFileUrl;
//    _assetExport.shouldOptimizeForNetworkUse=YES;
//    self.theEndVideoURL=outputFileUrl;
//
//    [_assetExportexportAsynchronouslyWithCompletionHandler:
//     ^(void ) {
//         [MBProgressHUDhideHUDForView:self.viewanimated:YES];
//         //播放
//         NSURL*url = [NSURLfileURLWithPath:outputFilePath];
//         MPMoviePlayerViewController *theMovie =[[MPMoviePlayerViewControlleralloc]initWithContentURL:url];
//         [selfpresentMoviePlayerViewControllerAnimated:theMovie];
//         theMovie.moviePlayer.movieSourceType=MPMovieSourceTypeFile;
//         [theMovie.moviePlayerplay];
//     }
//     ];
//    NSLog(@"完成！输出路径==%@",outputFilePath);
//}
//
////通过文件路径建立和添加音频素材
//- (void)setUpAndAddAudioAtPath:(NSURL*)assetURLtoComposition:(AVMutableComposition*)composition start:(CMTime)startdura:(CMTime)duraoffset:(CMTime)offset{
//
//    AVURLAsset *songAsset =[AVURLAssetURLAssetWithURL:assetURLoptions:nil];
//
//    AVMutableCompositionTrack *track =[compositionaddMutableTrackWithMediaType:AVMediaTypeAudiopreferredTrackID:kCMPersistentTrackID_Invalid];
//    AVAssetTrack *sourceAudioTrack =[[songAssettracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
//
//    NSError *error =nil;
//    BOOL ok =NO;
//
//    CMTime startTime = start;
//    CMTime trackDuration = dura;
//    CMTimeRange tRange =CMTimeRangeMake(startTime,trackDuration);
//
//    //设置音量
//    //AVMutableAudioMixInputParameters（输入参数可变的音频混合）
//    //audioMixInputParametersWithTrack（音频混音输入参数与轨道）
//    AVMutableAudioMixInputParameters *trackMix =[AVMutableAudioMixInputParametersaudioMixInputParametersWithTrack:track];
//    [trackMixsetVolume:0.8fatTime:startTime];
//
//    //素材加入数组
//    [audioMixParamsaddObject:trackMix];
//
//    //Insert audio into track  //offsetCMTimeMake(0, 44100)
//    ok = [trackinsertTimeRange:tRangeofTrack:sourceAudioTrackatTime:kCMTimeInvaliderror:&error];
//}
//
//#pragma mark - 保存路径
//-(NSString*)getLibarayPath
//{
//    NSFileManager *fileManager =[NSFileManagerdefaultManager];
//
//    NSArray* paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
//    NSString* path = [pathsobjectAtIndex:0];
//
//    NSString *movDirectory = [pathstringByAppendingPathComponent:@"tmpMovMix"];
//
//    [fileManagercreateDirectoryAtPath:movDirectorywithIntermediateDirectories:YESattributes:nilerror:nil];
//
//    return movDirectory;
//}

@end
