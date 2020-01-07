#ifdef TARGET_OF_IOS
#   include "ofxiOS.h"
using BaseApp = ofxiOSApp;
#else
#   include "ofMain.h"
using BaseApp = ofBaseApp;
#endif
#include "ofxSimpleSpeechRecognizer.h"

class ofApp : public BaseApp {
    ofxSimpleSpeechRecognizer recognizer;
public:
    void setup() {
        recognizer.setup("en-US");
    }
    void update() {
        
    }
    void draw() {
        if(recognizer.isRecognizingNow()) ofBackground(255, 0, 0);
        else ofBackground(0);
        
        ofDrawBitmapString(recognizer.isAuthorized() ? "authorized" : "not authorized..", 20, 20);
        ofDrawBitmapString(recognizer.isRecognizingNow() ? "recognizing now" : "tap to recognize", 20, 40);
        ofDrawBitmapString(recognizer.getLatestResult(), 20, 60);
    }
    void exit() {};
    
#ifdef TARGET_OF_IOS
    void touchDown(ofTouchEventArgs & touch) {
        if(recognizer.isRecognizingNow()) recognizer.stop();
        else recognizer.start();
    }
#else
    void keyPressed(int key) {
        if(key == ' ') {
            if(recognizer.isRecognizingNow()) {
                recognizer.stop();
            } else {
                recognizer.start();
            }
        }
    }
#endif
};

int main() {
#ifdef TARGET_OF_IOS
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
#else
    ofSetupOpenGL(1024,768,OF_WINDOW);            // <-------- setup the GL context

    // this kicks off the running of my app
    // can be OF_WINDOW or OF_FULLSCREEN
    // pass in width and height too:
#endif
    return ofRunApp(new ofApp);
}
