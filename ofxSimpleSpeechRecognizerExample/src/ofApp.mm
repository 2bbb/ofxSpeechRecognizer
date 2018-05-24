#include "ofxiOS.h"
#include "ofxSimpleSpeechRecognizer.h"

class ofApp : public ofxiOSApp {
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
        ofDrawBitmapString(recognizer.isRecognizingNow() ? "recognizing now" : "tap to recognize", 20, 20);
        ofDrawBitmapString(recognizer.getLatestResult(), 20, 40);
    }
    void exit() {};
    
    void touchDown(ofTouchEventArgs & touch) {
        if(recognizer.isRecognizingNow()) recognizer.stop();
        else recognizer.start();
    }
    void touchMoved(ofTouchEventArgs & touch) {}
    void touchUp(ofTouchEventArgs & touch) {}
    void touchDoubleTap(ofTouchEventArgs & touch) {}
    void touchCancelled(ofTouchEventArgs & touch) {}
    
    void lostFocus() {}
    void gotFocus() {}
    void gotMemoryWarning() {}
    void deviceOrientationChanged(int newOrientation) {}
    
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
