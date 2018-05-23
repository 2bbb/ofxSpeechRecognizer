#include "ofxiOS.h"

#include "ofxSpeechRecognizer.h"

class ofApp : public ofxiOSApp, public ofxSpeechRecognizerDelegate {
    ofxSpeechRecognizer recognizer;
    
public:
    void setup() {
        recognizer.printSupportedLocale();
        recognizer.setup("en-US");
        ofSetBackgroundColor(0);
        ofSetColor(255);
    };
    void update() {};
    void draw() {
        ofDrawBitmapString("Tap!", 20, 20);
        ofDrawBitmapString((recognizer.isRecognizingNow() ? "now recognizing" : ""), 20, 40);
    };
    void exit() {};
    
    void touchDown(ofTouchEventArgs & touch) {
        if(recognizer.isRecognizingNow()) {
            ofLogNotice() << "cancel";
            recognizer.cancel();
        } else {
            ofLogNotice() << "start";
            recognizer.requestWithAudioInput([=](ofxSpeechRecognitionResult res, std::string error){
                if(error == "") {
                    ofLogNotice("callback") << res;
                } else {
                    ofLogError("callback") << error;
                }
            });
        }
    };
    void touchMoved(ofTouchEventArgs & touch) {};
    void touchUp(ofTouchEventArgs & touch) {};
    void touchDoubleTap(ofTouchEventArgs & touch) {};
    void touchCancelled(ofTouchEventArgs & touch) {};
    
    void lostFocus() {};
    void gotFocus() {};
    void gotMemoryWarning() {};
    void deviceOrientationChanged(int newOrientation) {};
    
};

int main() {
    //  here are the most commonly used iOS window settings.
    //------------------------------------------------------
    ofiOSWindowSettings settings;
    settings.enableRetina = false; // enables retina resolution if the device supports it.
    settings.enableDepth = false; // enables depth buffer for 3d drawing.
    settings.enableAntiAliasing = false; // enables anti-aliasing which smooths out graphics on the screen.
    settings.numOfAntiAliasingSamples = 0; // number of samples used for anti-aliasing.
    settings.enableHardwareOrientation = false; // enables native view orientation.
    settings.enableHardwareOrientationAnimation = false; // enables native orientation changes to be animated.
    settings.glesVersion = OFXIOS_RENDERER_ES1; // type of renderer to use, ES1, ES2, ES3
    settings.windowMode = OF_FULLSCREEN;
    ofCreateWindow(settings);
    
    return ofRunApp(new ofApp);
}
