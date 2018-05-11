class JSONManager{
  TrackSequencer seq;
  String outputFile, inputFile;
  JSONObject json;
  JSONArray events, notes, obstacles;
  GLabel consoleOutLabel;

  String versionString = "1.5.0";
  int beatsPerBar = 16;
  int notesPerBar = 1; // Change this value later
  float offset;
  public JSONManager(TrackSequencer seq, GLabel consoleOutLabel){
    this.seq = seq;
    this.consoleOutLabel = consoleOutLabel;
  }

  // Load a track from disk
  public void loadTrack(String filename){
    if(filename == null || filename.isEmpty()){
      return;
    }

    this.consoleOutLabel.setText("Opening track file: " + filename);

    json = loadJSONObject(filename);

    seq.clearSeq();

    float bpmIn = json.getFloat("_beatsPerMinute");
    notes = json.getJSONArray("_notes");
    events = json.getJSONArray("_events");
    obstacles = json.getJSONArray("_obstacles");

    //offset = json.getFloat("_offset");

    //If events was empty, create some temp events
    if(events == null){
      createPlaceholderEvents();
    }

    println("notes json: " + notes);
    //println("bpmInput  : " + bpmIn);

    this.seq.setBPM(bpmIn);

    JSONObject currentObject;
    float currentTime;
    int currentLineIndex;

    // Note specific
    int currentLineLayer;
    int currentType;
    int currentCutDirection;

    // Obstacle specific
    float currentDuration;
    int currentWidth;

    // Event specific
    int currentValue;

    MultiTrack mt;
    Track t;

    // Get time of last note as an indicator of length of song
    if(notes == null){
      println("notes JSONArray was null!");
      return;
    }

    int gridY;

    //
    // Load notes
    //

    float beatOffset =offset*bpmIn/60;



    println(beatOffset);
    delay(1000);

    for(int n = 0; n < notes.size(); ++n){
      currentObject = notes.getJSONObject(n);
      currentTime = currentObject.getFloat("_time");
      println(currentTime);
      //currentTime += beatOffset;

      currentLineIndex = currentObject.getInt("_lineIndex");
      currentLineLayer = currentObject.getInt("_lineLayer");
      currentType = currentObject.getInt("_type");
      currentCutDirection = currentObject.getInt("_cutDirection");

      println("currentTime : " + currentTime);
      //println("currentNote : " + currentNote); //println("currentLineIndex : " + currentLineIndex); //println("currentLineLayer : " + currentLineLayer); //println("currentType : " + currentType);  //println("currentCutDirection : " + currentCutDirection);

      // Get notes multitracks. Add one to skip events track
      mt = seq.multiTracks.get(currentLineLayer + 1);
      t = mt.tracks.get(currentLineIndex);

      gridY = seq.timeToGrid(currentTime);

      println("note " + n + " gridY : " + gridY);

      // Add note to the grid
      // NOTE: The 0 on the end of this function is unused for GB_TYPE_NOTE
      t.addGridBlock(GridBlock.GB_TYPE_NOTE, currentTime, currentType, currentCutDirection, 0);
    }

    //
    // Load obstacles
    //
    //{"_lineIndex":2,"_type":0,"_duration":1,"_time":76,"_width":2},
    for(int o = 0; o < obstacles.size(); ++o){
      currentObject       = obstacles.getJSONObject(o);
      currentTime         = currentObject.getFloat("_time");// + beatOffset;
      currentLineIndex    = currentObject.getInt("_lineIndex");
      currentType         = currentObject.getInt("_type");
      currentDuration     = currentObject.getFloat("_duration");
      currentWidth        = currentObject.getInt("_width");

      println("currentTime : " + currentTime);

      // Get obstacle multitracks
      mt = seq.multiTracks.get(4);
      t = mt.tracks.get(currentLineIndex);

      gridY = seq.timeToGrid(currentTime);

      println("obstacle " + o + " gridY : " + gridY);

      // Add an obstacle to the grid
      // public void addGridBlock(int gridBlockType, float time, int type, int val0, float val1){
      t.addGridBlock(GridBlock.GB_TYPE_OBSTACLE, currentTime, currentType, currentWidth, currentDuration);
    }


    //
    // Load events
    //
    // Only events 0 - 4, 8, 9, 12, 13
    for(int e = 0; e < events.size(); ++e){
      currentObject = events.getJSONObject(e);
      currentTime = currentObject.getFloat("_time");// + beatOffset;
      currentType = currentObject.getInt("_type");
      currentValue = currentObject.getInt("_value");


      // Since not all tracks are used, we need to convert the currentValue
      // into the correct track index in the multitrack tracklist
      int updatedTrackValue = 0;

      println("currentType:" + currentType);
      switch(currentType){
        case(8): updatedTrackValue  = 5;
          break;
        case(9): updatedTrackValue  = 6;
          break;
        case(12): updatedTrackValue = 7;
          break;
        case(13): updatedTrackValue = 8;
          break;
        default:
          println("currentType that defaulted:" + currentType);
          updatedTrackValue = currentType;
      }

      // Get events multitrack
      mt = seq.multiTracks.get(0);
      t = mt.tracks.get(updatedTrackValue);

      println("updatedTrackValue output:" + updatedTrackValue);
      println("currentValue output:" + currentValue);
      println("");
      // Add event to the grid
      // NOTE: The 0 on the end of this function is unused for GB_TYPE_EVENT
      t.addGridBlock(GridBlock.GB_TYPE_EVENT, currentTime, updatedTrackValue, currentValue, 0);

    }

    this.consoleOutLabel.setText("++++ Track file loaded! ++++\n " + filename);

  }

  // Save the created track to output json file
  public void saveTrack(String filename){
    this.consoleOutLabel.setText("Saving track file: " + filename);
    println("Saving track to file: " + filename);

    this.outputFile = filename;

    json = new JSONObject();
    notes = new JSONArray();

    // Currently skipping over events and obstacles!
    events = new JSONArray();
    obstacles = new JSONArray();

    setEventsArray();
    setNotesArray();
    setObstaclesArray();

    json.setString("_version", versionString);
    json.setFloat("_beatsPerMinute", seq.getBPM());
    json.setInt("_beatsPerBar", beatsPerBar);
    json.setFloat("_noteJumpSpeed", 10.0);
    json.setFloat("_shuffle", 0.0);
    json.setFloat("_shufflePeriod", 0.25);
    json.setJSONArray("_events", events);
    json.setJSONArray("_notes", notes);
    json.setJSONArray("_obstacles", obstacles);


    int outFileLen = outputFile.length();
    if(outFileLen < 5 || !this.outputFile.substring(outFileLen - 5, outFileLen).equals(".json")){
      this.outputFile = this.outputFile + ".json";
    }

    saveJSONObject(json, filename);

    this.consoleOutLabel.setText("++++ Track file saved! ++++ " + hour() + ":" + minute() + ":" + second() + "\n" + filename);
  }


  // Create the notes JSON array to save to the track file
  private void setNotesArray(){
    // Go through every index in the track, but go across all tracks and get the current note
    int trackCount = 0;
    int multiCount = 0;
    int noteCount = 0;
    multiCount = 0;
    Note n = null;
    for(int i = 1; i < 4; ++i){
      MultiTrack m = seq.multiTracks.get(i);
      trackCount = 0;
      for(Track t : m.tracks){

        // Iterate through all gridblocks in hashmap
        for (Float f: t.gridBlocks.keySet()) {
          Note block = (Note)t.gridBlocks.get(f);
          if(block != null){
            JSONObject note = new JSONObject();

            note.setFloat("_time", block.getTime());
            note.setInt("_lineIndex", trackCount);
            note.setInt("_lineLayer", multiCount);
            note.setInt("_type", block.getType());
            note.setInt("_cutDirection", block.getCutDirection());

            notes.setJSONObject(noteCount, note);
            ++noteCount;
          }
        }
        ++trackCount;
      }
      ++multiCount;
    }
  }

  // Create the notes JSON array
  private void setObstaclesArray(){
    // Go through every index in the track, but go across all tracks and get the current note
    int trackCount = 0;
    int multiCount = 0;
    int obstacleCount = 0;
    MultiTrack m = seq.multiTracks.get(4);
    trackCount = 0;
    for(Track t : m.tracks){
      // Iterate through all gridblocks in hashmap
      for (Float f: t.gridBlocks.keySet()) {
        Obstacle block = (Obstacle)t.gridBlocks.get(f);
        if(block != null){
          JSONObject obstacle = new JSONObject();

          // {"_lineIndex":2, "_type":0, "_duration":1, "_time":76, "_width":2},
          obstacle.setFloat("_time", block.getTime());
          obstacle.setInt("_lineIndex", trackCount);
          obstacle.setInt("_type", block.getType());
          obstacle.setFloat("_duration", block.getDuration());
          obstacle.setInt("_width", block.getWallWidth());

          obstacles.setJSONObject(obstacleCount, obstacle);
          ++obstacleCount;
        }
      }
      ++trackCount;
    }
  }

  private void setEventsArray(){

    // Go through every index in the track, but go across all tracks and get the current note
    int trackCount = 0;
    int eventCount = 0;
    MultiTrack m = seq.multiTracks.get(0);
    trackCount = 0;
    for(Track t : m.tracks){
      // Iterate through all gridblocks in hashmap
      for (Float f: t.gridBlocks.keySet()) {
        Event block = (Event)t.gridBlocks.get(f);
        if(block != null){
          JSONObject event = new JSONObject();

          event.setFloat("_time", block.getTime());
          event.setInt("_type", trackCount);
          event.setInt("_value", block.getValue());

          events.setJSONObject(eventCount, event);
          ++eventCount;
        }
      }

      ++trackCount;
      if(trackCount == 5){
        trackCount = 8;
        //println("Changing trackcount to: " + trackCount);
      }else if(trackCount == 10){
        trackCount = 12;
        //println("Changing trackcount to: " + trackCount);
      }
    }

  }

  private void createPlaceholderEvents(){
    int eventCount = 0;

    events = new JSONArray();

    for(int i = 0; i < 5; ++i){
      JSONObject event = new JSONObject();

      event.setInt("_time", 0);
      event.setInt("_type", i);
      event.setInt("_value", 1);

      events.setJSONObject(eventCount, event);
      ++eventCount;
    }
  }
}