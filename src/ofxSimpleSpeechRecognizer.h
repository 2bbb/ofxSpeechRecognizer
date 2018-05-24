//
//  ofxSimpleSpeechRecognizer.h
//  ofxSimpleSpeechRecognizerExample
//
//  Created by 石井通人 on 2018/05/24.
//

#ifndef ofxSimpleSpeechRecognizer_h
#define ofxSimpleSpeechRecognizer_h

#include "ofxSpeechRecognizer.h"

namespace ofx {
    namespace SpeechRecognition {
        struct SimpleRecognizer : public Recognizer::Delegate, private Recognizer {
            using Recognizer::AuthorizationStatus;
            using Recognizer::printSupportedLocales;
            using Recognizer::supportedLocales;
            using Recognizer::isRecognizingNow;
            
            void setup(std::string locale) {
                Recognizer::setup(locale);
                if(!isAuthorized()) {
                    Recognizer::requestAuthorization([=](bool b) {
                        if(!b) ofLogError("ofxSimpleSpeechRecognizer") << "authorize failed";
                    });
                }
            }
            
            std::string getLatestResult() const
            { return latestResult; };
            
            inline bool isAuthorized() const
            { return Recognizer::authorizationStatus() == Recognizer::AuthorizationStatus::Authorized; };
            
            inline bool isAvailable() const
            { return isAuthorized() && Recognizer::isAvailable(); };
            
            void start()
            { Recognizer::requestWithAudioInput(this); };
            
            void stop()
            { Recognizer::cancel(); };
            
            virtual void didFinishRecognition(Task task, Result result)
            { latestResult = result.bestTranscription; };
            virtual void didHypothesizeTranscription(Task task, Transcription transcription)
            { latestResult = transcription; };
        private:
            std::string latestResult;
        };
    };
};

using ofxSimpleSpeechRecognizer = ofx::SpeechRecognition::SimpleRecognizer;

#endif /* ofxSimpleSpeechRecognizer_h */
