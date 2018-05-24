//
//  ofxSpeechRecognizer.h
//
//  Created by ISHII 2bit on 2018/05/23.
//

#ifndef ofxSpeechRecognizer_h
#define ofxSpeechRecognizer_h

#include <string>
#include <sstream>
#include <vector>
#include <memory>
#include <functional>

#include "ofLog.h"

namespace bbb {
    struct speech_recognizer;
};

namespace ofx {
    namespace SpeechRecognition {
        struct Task {
            Task(void *objc_obj)
            : objc_obj(objc_obj)
            {};
            enum class State {
                Starting = 0,
                Running = 1,
                Finishing = 2,
                Canceling = 3,
                Completed = 4,
            };
            
            void cancel();
            bool isCancelled;
            
            void finish();
            bool isFinishing;
            
            State state;
            std::string error;
        private:
            void *objc_obj;
        };
        
        struct Transcription {
            struct Segment {
                float confidence;
                std::vector<std::string> alternativeSubstrings;
                std::string substring;
                std::size_t substringLocation;
                std::size_t substringLength;
                float duration;
                float timestamp;
                inline operator std::string() const { return substring; };
            };

            std::string formattedString;
            std::vector<Segment> segments;
            inline operator std::string() const { return formattedString; };
            friend std::ostream &operator<<(std::ostream &os, const Transcription &res) {
                os << res.formattedString;
                return os;
            }
        };
        
        struct Result {
            std::vector<Transcription> transcriptions;
            Transcription bestTranscription;
            bool isFinal;
            
            inline operator std::string() const { return bestTranscription; };
            
            friend std::ostream &operator<<(std::ostream &os, const Result &res) {
                os << "[ofxSpeechRecgonitionResult]\n  finished: " << (res.isFinal ? "true" : "false") << "\n";
                os << "  best transcription: " << res.bestTranscription << "\n  other transcriptions:\n";
                for(const auto &transcription : res.transcriptions) {
                    os << "    " << transcription << "\n";
                }
                return os;
            }
        };
        
        struct Recognizer {
            struct Delegate {
                virtual void availabilityDidChange(bool available) {};
                
                virtual void didDetect(Task task) {};
                virtual void didFinishRecognition(Task task, Result result) {};
                virtual void didFinishSuccessfully(Task task, bool successfully) {};
                virtual void didFinishReadingAudio(Task task) {};
                virtual void didCancelled(Task task) {};
                
                virtual void didHypothesizeTranscription(Task task, Transcription transcription) {};
            };
            
            enum class AuthorizationStatus : std::int64_t {
                NotDetermined,
                Denied,
                Restricted,
                Authorized
            };
            static AuthorizationStatus authorizationStatus();
            static void requestAuthorization(std::function<void(bool)> callback);
            static void requestAuthorization(std::function<void(AuthorizationStatus)> callback);
            
            static std::vector<std::string> supportedLocales();
            static void printSupportedLocales() {
                auto &&locales = supportedLocales();
                std::ostringstream os;
                for(auto &&locale : locales) os << "\n  " << locale;
                ofLogNotice("ofxSpeechRecognizer") << "supported locales:" << os.str();
            }
            
            void setup(std::string locale = "") {
                if(authorizationStatus() != AuthorizationStatus::Authorized) {
                    requestAuthorization([this, locale](bool isAuthorized) {
                        ofLogNotice("ofxSpeechRecognizer") << "authorization " << (isAuthorized ? "succeed" : "failured");
                        if(isAuthorized) setupImpl(locale);
                    });
                } else {
                    setupImpl(locale);
                }
            }
            
            bool isAvailable() const;
            std::string locale() const;
            bool isRecognizingNow() const;
            
            inline bool requestWithAudioInput(std::function<void(Result, std::string)> callback)
            { return requestImpl(createSpeechAudioBufferRecognitionRequest(), callback); };
            
            inline bool requestWithAudioInput(Delegate *delegate)
            { return requestImpl(createSpeechAudioBufferRecognitionRequest(), delegate); };
            
            void cancel();
            
        private:
            void setupImpl(std::string locale);
            bool requestImpl(void *request, Delegate *delegate);
            bool requestImpl(void *request, std::function<void(Result, std::string)> callback);
            
            void *createSpeechAudioBufferRecognitionRequest();
            
            void *impl{nullptr};
            void *engine{nullptr};
            void *request{nullptr};
            void *task{nullptr};
        };
    }
};

using ofxSpeechRecognizer = ofx::SpeechRecognition::Recognizer;
using ofxSpeechRecognizerAuthorizationStatus = ofx::SpeechRecognition::Recognizer::AuthorizationStatus;
using ofxSpeechRecognizerDelegate = ofx::SpeechRecognition::Recognizer::Delegate;

using ofxSpeechRecognitionTask = ofx::SpeechRecognition::Task;
using ofxSpeechRecognitionTaskState = ofx::SpeechRecognition::Task::State;
using ofxSpeechRecognitionTranscription = ofx::SpeechRecognition::Transcription;
using ofxSpeechRecognitionTranscriptionSegment = ofx::SpeechRecognition::Transcription::Segment;
using ofxSpeechRecognitionResult = ofx::SpeechRecognition::Result;


#endif /* ofxSpeechRecognizer_h */
