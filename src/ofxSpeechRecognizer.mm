//
//  ofxSpeechRecognizer.mm
//
//  Created by ISHII 2bit on 2018/05/23.
//

#include "ofxSpeechRecognizer.h"

#import <Speech/Speech.h>

namespace bbb {
    bool has_NSSpeechRecognitionUsageDescription() {
        NSString *speechRecognitionUsageDescription = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSSpeechRecognitionUsageDescription"];
        return speechRecognitionUsageDescription != nil;
    }
}
namespace {
    const char *to_cpp(NSString *str)
    { return str ? str.UTF8String : ""; };
    NSString *to_objc(const std::string &str)
    { return [NSString stringWithUTF8String:str.c_str()]; };
    
    inline bool to_cpp(BOOL b)
    { return b ? true : false; };
    inline BOOL to_objc(bool b)
    { return b ? YES : NO; };
    
    inline ofxSpeechRecognitionTask to_cpp(SFSpeechRecognitionTask *task_) {
        ofxSpeechRecognitionTask task(task_);
        task.isCancelled = task_.cancelled;
        task.isFinishing = task_.finishing;
        task.state = static_cast<ofxSpeechRecognitionTask::State>(task_.state);
        if(task_.error) task.error = to_cpp(task_.error.description);
        return task;
    }
    
    inline ofxSpeechRecognitionTranscriptionSegment to_cpp(SFTranscriptionSegment *s) {
        ofxSpeechRecognitionTranscriptionSegment segment;
        segment.confidence = s.confidence;
        for(NSString *substr in s.alternativeSubstrings) {
            segment.alternativeSubstrings.push_back(to_cpp(substr));
        }
        segment.substring = to_cpp(s.substring);
        segment.substringLocation = s.substringRange.location;
        segment.substringLength = s.substringRange.length;
        segment.duration = s.duration;
        segment.timestamp = s.timestamp;
        return segment;
    }
    
    inline ofxSpeechRecognitionTranscription to_cpp(SFTranscription *t) {
        ofxSpeechRecognitionTranscription transcription;
        transcription.formattedString = to_cpp(t.formattedString);
        for(SFTranscriptionSegment *segment in t.segments) {
            transcription.segments.push_back(to_cpp(segment));
        }
        return transcription;
    }
    
    inline ofxSpeechRecognitionResult to_cpp(SFSpeechRecognitionResult *result_) {
        ofxSpeechRecognitionResult result;
        for(SFTranscription *transcription in result_.transcriptions) {
            result.transcriptions.push_back(to_cpp(transcription));
        }
        result.bestTranscription = to_cpp(result_.bestTranscription);
        result.isFinal = result_.final;
        return result;
    }
};

@interface BBBSpeechRecognizerDelegate : NSObject <SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate>
{
    ofxSpeechRecognizerDelegate *impl;
    SFSpeechRecognitionTask **task;
}

- (void)setDelegate:(ofxSpeechRecognizerDelegate *)impl_;
- (void)setTask:(SFSpeechRecognitionTask **)task_;

@end

@implementation BBBSpeechRecognizerDelegate

- (void)setDelegate:(ofxSpeechRecognizerDelegate *)impl_ {
    impl = impl_;
}

- (void)setTask:(SFSpeechRecognitionTask **)task_ {
    task = task_;
}

#pragma mark SFSpeechRecognizerDelegate

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer
    availabilityDidChange:(BOOL)available
{
    if(impl) impl->availabilityDidChange(to_cpp(available));
}

#pragma mark SFSpeechRecognitionTaskDelegate

- (void)speechRecognitionDidDetectSpeech:(SFSpeechRecognitionTask *)task_ {
    if(impl) impl->didDetect(to_cpp(task_));
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task_
         didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult
{
    if(impl) impl->didFinishRecognition(to_cpp(task_), to_cpp(recognitionResult));
    if(task && recognitionResult.isFinal) *task = nil;
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task_
        didFinishSuccessfully:(BOOL)successfully;
{
    if(impl) impl->didFinishSuccessfully(to_cpp(task_), to_cpp(successfully));
    if(task) *task = nil;
}

- (void)speechRecognitionTaskFinishedReadingAudio:(SFSpeechRecognitionTask *)task_ {
    if(impl) impl->didFinishReadingAudio(to_cpp(task_));
}

- (void)speechRecognitionTaskWasCancelled:(SFSpeechRecognitionTask *)task_ {
    if(impl) impl->didCancelled(to_cpp(task_));
    if(task) *task = nil;
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task_
  didHypothesizeTranscription:(SFTranscription *)transcription
{
    if(impl) impl->didHypothesizeTranscription(to_cpp(task_), to_cpp(transcription));
}

@end

namespace ofx {
    namespace SpeechRecognition {
#pragma mark Task
        
        void Task::cancel()
        { [((SFSpeechRecognitionTask *)objc_obj) cancel]; };
        void Task::finish()
        { [((SFSpeechRecognitionTask *)objc_obj) finish]; };
        
#pragma mark Recognizer
        
        Recognizer::AuthorizationStatus Recognizer::authorizationStatus() {
            return static_cast<Recognizer::AuthorizationStatus>(SFSpeechRecognizer.authorizationStatus);
        }

        void Recognizer::requestAuthorization(std::function<void(bool)> callback) {
            requestAuthorization([callback] (AuthorizationStatus status) {
                callback(status == ofxSpeechRecognizerAuthorizationStatus::Authorized);
            });
        }
        
        void Recognizer::requestAuthorization(std::function<void(AuthorizationStatus)> callback) {
            [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
                switch(status) {
                    case SFSpeechRecognizerAuthorizationStatusAuthorized:
                        callback(AuthorizationStatus::Authorized);
                        break;
                    case SFSpeechRecognizerAuthorizationStatusDenied:
                        callback(AuthorizationStatus::Denied);
                        break;
                    case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                        callback(AuthorizationStatus::NotDetermined);
                        break;
                    case SFSpeechRecognizerAuthorizationStatusRestricted:
                        callback(AuthorizationStatus::Restricted);
                        break;
                    default:
                        callback(AuthorizationStatus::NotDetermined);
                }
            }];
        }
        
        std::vector<std::string> Recognizer::supportedLocales() {
            std::vector<std::string> locales;
            for(NSLocale *locale in SFSpeechRecognizer.supportedLocales) {
                locales.push_back(to_cpp(locale.localeIdentifier));
            }
            std::sort(locales.begin(), locales.end());
            return locales;
        }
        
#define $ ((SFSpeechRecognizer *)impl)
        void Recognizer::setupImpl(std::string locale) {
            if(locale == "") impl = SFSpeechRecognizer.alloc.init;
            else {
                impl = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:to_objc(locale)]];
            }
        }
        
        bool Recognizer::isAvailable() const
        { return $.available; };
        std::string Recognizer::locale() const
        { return to_cpp($.locale.localeIdentifier); };
        
        void Recognizer::cancel() {
//            dispatch_async(dispatch_get_main_queue(), ^{
                if(this->request) {
                    SFSpeechRecognitionRequest *req = (SFSpeechRecognitionRequest *)this->request;
                    if([req isKindOfClass:SFSpeechAudioBufferRecognitionRequest.class]) {
                        [((SFSpeechAudioBufferRecognitionRequest *)this->request) endAudio];
                    }
                    this->request = nullptr;
                }
                
                if(this->engine) {
                    [((AVAudioEngine *)this->engine) stop];
                    AVAudioInputNode *inputNode = ((AVAudioEngine *)this->engine).inputNode;
                    [inputNode removeTapOnBus:0];
                    [inputNode reset];
                }

                if(this->task) {
                    SFSpeechRecognitionTask *t = (SFSpeechRecognitionTask *)this->task;
                    [t cancel];
                    this->task = nil;
                }
//            });
        }
        
        bool Recognizer::isRecognizingNow() const {
            return task != nil;
        }
        void *Recognizer::createSpeechAudioBufferRecognitionRequest() {
            cancel();
            
#ifdef TARGET_OF_IOS
            AVAudioSession *audioSession = AVAudioSession.sharedInstance;
            NSError *err = nil;
            [audioSession setCategory:AVAudioSessionCategoryRecord
                                error:&err];
            if(err) {
                ofLogError("ofxSpeechRecognizer::requestWithAudioInput") << "failure: setup audio [" << to_cpp(err.description) << "]";
                return nullptr;
            }
            [audioSession setMode:AVAudioSessionModeMeasurement error:&err];
            if(err) {
                ofLogError("ofxSpeechRecognizer::requestWithAudioInput") << "failure: setup audio [" << to_cpp(err.description) << "]";
                return nullptr;
            }
            [audioSession setActive:YES
                        withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                              error:&err];
            if(err) {
                ofLogError("ofxSpeechRecognizer::requestWithAudioInput") << "failure: setup audio [" << to_cpp(err.description) << "]";
                return nullptr;
            }
#endif
            
            if(!this->engine) {
                AVAudioEngine *engine = [[AVAudioEngine alloc] init];
                this->engine = engine;
            }
            SFSpeechAudioBufferRecognitionRequest *request = SFSpeechAudioBufferRecognitionRequest.alloc.init;
            request.shouldReportPartialResults = YES;
            
            AVAudioInputNode *inputNode = ((AVAudioEngine *)engine).inputNode;
            AVAudioFormat *format = [inputNode outputFormatForBus:0];
            [inputNode installTapOnBus:0
                            bufferSize:1024
                                format:format
                                 block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
                                     [request appendAudioPCMBuffer:buffer];
                                 }];

            this->request = request;
            return request;
        }
        
        bool Recognizer::requestImpl(void *req, Recognizer::Delegate *delegate) {
            if(!req) {
                ofLogError("ofxReconigizer") << "can't start recognize";
                return false;
            }
            SFSpeechRecognitionRequest *request = (SFSpeechRecognitionRequest *)req;
            BBBSpeechRecognizerDelegate *_ = BBBSpeechRecognizerDelegate.alloc.init;
            [_ setDelegate:delegate];
            [_ setTask:(SFSpeechRecognitionTask **)&task];
            
            task = [$ recognitionTaskWithRequest:request
                                        delegate:_];
            [((AVAudioEngine *)engine) prepare];
            NSError *err = nil;
            [((AVAudioEngine *)engine) startAndReturnError:&err];
            
            if(err) {
                ofLogError("ofxReconigizer") << "can't start recognize" << to_cpp(err.description);
                return false;
            }
            return true;
        }
        bool Recognizer::requestImpl(void *req, std::function<void(Result, std::string)> callback) {
            if(!req) {
                ofLogFatalError("ofxReconigizer") << "can't start recognize";
                return false;
            }
            SFSpeechRecognitionRequest *request = (SFSpeechRecognitionRequest *)req;
            task = [$ recognitionTaskWithRequest:request
                            resultHandler:^(SFSpeechRecognitionResult *result,
                                            NSError *error)
            {
                if(!error && !result) {
                    ofxSpeechRecognitionResult result;
                    dispatch_async(dispatch_get_main_queue(), ^{ callback(result, "no speech found"); });
                    return;
                }
                if(error) {
                    ofLogError("ofxReconigizer") << "error: " << to_cpp(error.description);
                    cancel();
                }
                callback(to_cpp(result), to_cpp(error.description));
                if(result.isFinal) task = nil;
             }];
            
            [((AVAudioEngine *)engine) prepare];
            NSError *err = nil;
            [((AVAudioEngine *)engine) startAndReturnError:&err];
            if(err) {
                ofLogError("ofxReconigizer") << "can't start recognize" << to_cpp(err.description);
                return false;
            }
            return true;
        }
#undef $
    }
};
