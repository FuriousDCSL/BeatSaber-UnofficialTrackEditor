
class Waveform extends GUIElement {
    
  Minim minim; 
  AudioSample sound; 
  AudioPlayer soundbis;
  private FloatList sampleAverage; 
  private int border, leftLength, rightLength;
  private int sampleRate = 44100;
  private float bpm = 0;
  
  // Resolution of the display
  private float sizeOfAvg = 0;
  private int heightScale = 1;
  
  private float maxSize = 0;
  
  private int gridSize = 0;
  private float beatsPerBar = 1.0;
  
  // width adjustment for audio display  
  private int widthScale = 200;
  
  String soundfilePath = "";
  
  Waveform(GUIElement parent, int x, int y, int gridSize, Minim minim){
    super(parent, x, y, gridSize, gridSize);
    
    this.gridSize = gridSize;
    
    this.minim = minim;
    border = 10;
  }
  
  public void loadSoundFile(String path){
    soundfilePath = path;
    sound = minim.loadSample(soundfilePath, 1024);
    soundbis = minim.loadFile(soundfilePath);
        
    setSampleRate((int)sound.sampleRate());
    
    println("Loading sound file: " + path);
    
    resizeDisplay();
  }
  
  public void setBPM(float bpm){
    this.bpm = bpm;
    resizeDisplay();
  }
  
  public void setBeatsPerBar(float beats){
    this.beatsPerBar = beats;
    println("beatsPerBar: " + this.beatsPerBar);
    resizeDisplay();
  }
  
  private void calculateSizeOfAVG(){
    this.sizeOfAvg = (int)((this.sampleRate * 60) / this.bpm) / this.gridSize / this.beatsPerBar ;
    println("sampleRate: " + this.sampleRate);
    println("bpm: " + this.bpm);
    println("gridSize: " + this.gridSize);
    // Implement beats per bar here somewhere?
    println("sizeOfAvg: " + this.sizeOfAvg);
  }
  
  public void resizeDisplay(){
    calculateSizeOfAVG();
    float[] leftSamples = sound.getChannel(AudioSample.LEFT);
    float[] rightSamples = sound.getChannel(AudioSample.RIGHT);
    float[] samplesVal = new float[rightSamples.length];
    for (int i = 0; i < rightSamples.length; ++i) {
      samplesVal[i] = leftSamples[i] + rightSamples[i];
    }
    
    leftLength  = leftSamples.length;
    rightLength = rightSamples.length;
   
    //2. reduce quantity : get an average from those values
    sampleAverage = new FloatList();
    int average=0;
    
    println(this.gridSize);
    
    // Find the largest value
    
    for (int i = 0; i < samplesVal.length; ++i) {
      average += abs(samplesVal[i]); // sample are low value so we increase the size to see them
      
      if ( i % sizeOfAvg == 0) {
        float newVal = average / sizeOfAvg;
        sampleAverage.append(newVal);
        if(newVal > maxSize)
          maxSize = newVal;
        average = 0;
      }
    }
    
    // Scale to correct width
    for (int i = 0; i < samplesVal.length; ++i) {
      samplesVal[i] = map(samplesVal[i], 0, maxSize, 0, 100);
    } 
  }
  
  public void setSampleRate(int sampleRate){
    this.sampleRate = sampleRate;
    this.resizeDisplay();
  }
  
  // Get number of samples in soundfile
  public int getNumSamples(){
    return max(leftLength, rightLength);
  }
  
  public int getLength(){
    return soundbis.length();
  }
  
  public void play(){
    soundbis.play();
  }
  
  public void pause(){
    soundbis.pause();
    soundbis.rewind();
  }
  
  public void display(){
    super.display();
    
    if(sampleRate != 0){
      if(sound != null){
        fill(190);
        stroke(#ffffff);
        strokeWeight(1);
        
        // Draw the waveform display and the time. Time is currently showing each second
        
        float prevTime = -1;
        for ( int i=0; i < sampleAverage.size(); i++) {
          // Draw the sound file
          line(border*2, -(i) + this.getY(), border*2 + sampleAverage.get(i), -(i) + this.getY());
          
          // Draw the text (time in seconds)
          float time = floor((i * sizeOfAvg) / sampleRate);
          if(prevTime != time){
            prevTime = time;
            //text(round(time), i + border, height-border/2);
            text(round(time), border/2, this.getY() - i - border);
          }
        }
        
        // Draw the play head (red line moving across)
        strokeWeight(2);
        stroke(#ff0000);
        float ypos = (soundbis.position() * sound.sampleRate() / 1000) / sizeOfAvg;
        line(0, -ypos + this.getY(), width, -ypos + this.getY());
      }else{
        println("Error: Could not display waveform, sound is null!");
      }
    }else{
      println("Error: Could not display waveform, sampleRate is null!");
    }
  }
}
