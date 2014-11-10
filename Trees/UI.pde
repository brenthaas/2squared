class UITrees extends UI3dComponent {
  
  color[] previewBuffer;
  color[] black;
  
  UITrees() {
    previewBuffer = new int[lx.total];
    black = new int[lx.total];
    for (int i = 0; i < black.length; ++i) {
      black[i] = #000000;
    }
  }
  
  protected void onDraw(UI ui, PGraphics pg) {
    lights();
    pointLight(0, 0, 80, model.cx, geometry.HEIGHT/2, -10*FEET);

    noStroke();
    fill(#191919);
    beginShape();
    vertex(0, 0, 0);
    vertex(30*FEET, 0, 0);
    vertex(30*FEET, 0, 30*FEET);
    vertex(0, 0, 30*FEET);
    endShape(CLOSE);

    drawTrees(ui);
    drawLights(ui);
  }
  
  private void drawTrees(UI ui) {
    noStroke();
    fill(#333333);
    for (Tree tree : Trees.this.model.trees) {
      pushMatrix();
      translate(tree.x, 0, tree.z);
      rotateY(-tree.ry * PI / 180);
      drawTree(ui);
      popMatrix();
    }
  }
  
  private void drawTree(UI ui) {
    for (int i = 0; i < 4; ++i) {
      for (int y = 1; y < geometry.distances.length; ++y) {
        float beamY = geometry.heights[y];
        float prevY = geometry.heights[y-1];
        float distance = geometry.distances[y];
        float prevDistance = geometry.distances[y-1];
        
        if (y <= geometry.NUM_BEAMS) {
          beginShape();
          vertex(-distance, beamY - geometry.BEAM_WIDTH/2, -distance);
          vertex(-distance, beamY + geometry.BEAM_WIDTH/2, -distance);
          vertex(distance, beamY + geometry.BEAM_WIDTH/2, -distance);
          vertex(distance, beamY - geometry.BEAM_WIDTH/2, -distance);
          endShape(CLOSE);
        }
        
        beginShape();
        vertex(-geometry.BEAM_WIDTH/2, prevY, -prevDistance);
        vertex(geometry.BEAM_WIDTH/2, prevY, -prevDistance);
        vertex(geometry.BEAM_WIDTH/2, beamY, -distance);
        vertex(-geometry.BEAM_WIDTH/2, beamY, -distance);
        endShape(CLOSE);
        
        beginShape();
        vertex(prevDistance-geometry.BEAM_WIDTH/2, prevY, -prevDistance-geometry.BEAM_WIDTH/2);
        vertex(prevDistance+geometry.BEAM_WIDTH/2, prevY, -prevDistance+geometry.BEAM_WIDTH/2);
        vertex(distance+geometry.BEAM_WIDTH/2, beamY, -distance+geometry.BEAM_WIDTH/2);
        vertex(distance-geometry.BEAM_WIDTH/2, beamY, -distance-geometry.BEAM_WIDTH/2);
        endShape(CLOSE);        
      }
      rotateY(PI/2); 
    }    
  }
     
  private void drawLights(UI ui) {
    
    color[] colors = lx.getColors();
    noStroke();
    noFill();
    
    if (mappingTool.isEnabled()) {
      Cluster cluster = mappingTool.getCluster();
      JSONObject config = mappingTool.getConfig();
      Tree tree = Trees.this.model.trees.get(config.getInt("treeIndex"));
      
      pushMatrix();
      translate(tree.x, 0, tree.z);
      rotateY(-tree.ry * PI / 180);
      
      // This is some bad duplicated code from Model, hack for now
      int clusterLevel = config.getInt("level");
      int clusterFace = config.getInt("face");
      float clusterOffset = config.getFloat("offset");
      float clusterMountPoint = config.getFloat("mountPoint");
      float clusterSkew = config.getFloat("skew", 0);
      float cry = 0;
      switch (clusterFace) {
        // Could be math, but this way it's readable!
        case FRONT: case FRONT_RIGHT:                  break;
        case RIGHT: case REAR_RIGHT:  cry = HALF_PI;   break;
        case REAR:  case REAR_LEFT:   cry = PI;        break;
        case LEFT:  case FRONT_LEFT:  cry = 3*HALF_PI; break;
      }
      switch (clusterFace) {
        case FRONT_RIGHT:
        case REAR_RIGHT:
        case REAR_LEFT:
        case FRONT_LEFT:
          clusterOffset = 0;
          break;
      }
      rotateY(-cry);
      translate(clusterOffset * geometry.distances[clusterLevel], geometry.heights[clusterLevel] + clusterMountPoint, -geometry.distances[clusterLevel]);
      
      switch (clusterFace) {
        case FRONT_RIGHT:
        case REAR_RIGHT:
        case REAR_LEFT:
        case FRONT_LEFT:
          translate(geometry.distances[clusterLevel], 0, 0);
          rotateY(-QUARTER_PI);
          cry += QUARTER_PI;
          break;
      }
      
      rotateX(-geometry.angleFromAxis(geometry.heights[clusterLevel]));
      rotateZ(-clusterSkew * PI / 180);
      drawCubes(cluster, colors);
      
      popMatrix();
    } else {
      for (Cluster cluster : model.clusters) {
        drawCluster(cluster, colors);
      }
    }
    
    noLights();
  }
  
  void drawCluster(Cluster cluster, color[] colors) {
    pushMatrix();
    translate(cluster.x, cluster.y, cluster.z);
    rotateY(-cluster.ry * PI / 180);
    rotateX(-cluster.rx * PI / 180);
    rotateZ(-cluster.skew * PI / 180);
    drawCubes(cluster, colors);
    popMatrix();
  }
  
  void drawCubes(Cluster cluster, color[] colors) {
    for (Cube cube : cluster.cubes) {
      pushMatrix();
      fill(colors[cube.index]);
      translate(cube.lx, cube.ly, cube.lz);
      rotateY(-cube.ry * PI / 180);
      rotateX(-cube.rx * PI / 180);
      rotateZ(-cube.rz * PI / 180);
      box(cube.size, cube.size, cube.size);
      popMatrix();
    }
  }
}

public class UILoopRecorder extends UIWindow {
  
  private final UILabel slotLabel;
  private final String[] labels = new String[] { "-", "-", "-", "-" };
  
  UILoopRecorder(UI ui) {
    super(ui, "LOOP RECORDER", Trees.this.width-144, Trees.this.height - 126, 140, 122);
    float yPos = TITLE_LABEL_HEIGHT;
    
    final UIButton playButton = new UIButton(6, yPos, 40, 20);
    playButton
    .setLabel("PLAY")
    .addToContainer(this);
      
    final UIButton stopButton = new UIButton(6 + (this.width-8)/3, yPos, 40, 20);
    stopButton
    .setMomentary(true)
    .setLabel("STOP")
    .addToContainer(this);
      
    final UIButton armButton = new UIButton(6 + 2*(this.width-8)/3, yPos, 40, 20);
    armButton
    .setLabel("ARM")
    .setActiveColor(#cc3333)
    .addToContainer(this);
    
    yPos += 24;
    final UIButton loopButton = new UIButton(4, yPos, this.width-8, 20);
    loopButton
    .setInactiveLabel("One-shot")
    .setActiveLabel("Looping")
    .addToContainer(this);
    
    yPos += 24;
    slotLabel = new UILabel(4, yPos, this.width-8, 20);
    slotLabel
    .setLabel("-")
    .setAlignment(CENTER, CENTER)
    .setBackgroundColor(#333333)
    .setBorderColor(#666666)
    .addToContainer(this); 
    
    yPos += 24;
    new UIButton(4, yPos, (this.width-12)/2, 20) {
      protected void onToggle(boolean active) {
        if (active) {
          String fileName = labels[automationSlot.getValuei()].equals("-") ? "set.json" : labels[automationSlot.getValuei()]; 
          selectOutput("Save Set",  "saveSet", new File(dataPath(fileName)), UILoopRecorder.this);
        }
      }
    }
    .setMomentary(true)
    .setLabel("Save")
    .addToContainer(this);
    
    new UIButton(this.width - (this.width-12)/2 - 4, yPos, (this.width-12)/2, 20) {
      protected void onToggle(boolean active) {
        if (active) {
          selectInput("Load Set",  "loadSet", new File(dataPath("")), UILoopRecorder.this);
        }
      }
    }
    .setMomentary(true)
    .setLabel("Load")
    .addToContainer(this);
    
    final LXParameterListener listener;
    automationSlot.addListener(listener = new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        LXAutomationRecorder auto = automation[automationSlot.getValuei()];
        stopButton.setParameter(automationStop[automationSlot.getValuei()]);
        playButton.setParameter(auto.isRunning);
        armButton.setParameter(auto.armRecord);
        loopButton.setParameter(auto.looping);
        slotLabel.setLabel(labels[automationSlot.getValuei()]);
      }
    });
    listener.onParameterChanged(null);
  }

  public void saveSet(File file) {
    if (file != null) {
      saveBytes(file.getPath(), automation[automationSlot.getValuei()].toJson().toString().getBytes());
      slotLabel.setLabel(labels[automationSlot.getValuei()] = file.getName());
    }
  }
  
  public void loadSet(File file) {
    if (file != null) {
      String jsonStr = new String(loadBytes(file.getPath()));
      JsonArray jsonArr = new Gson().fromJson(jsonStr, JsonArray.class);
      automation[automationSlot.getValuei()].loadJson(jsonArr);
      slotLabel.setLabel(labels[automationSlot.getValuei()] = file.getName());
    }
  }

}

class UIChannelFaders extends UI2dContext {
  
  final static int SPACER = 30;
  final static int PADDING = 4;
  final static int BUTTON_HEIGHT = 14;
  final static int FADER_WIDTH = 40;
  final static int WIDTH = SPACER + PADDING + PADDING + FADER_WIDTH;
  final static int HEIGHT = 130;
  final static int PERF_PADDING = PADDING + 1;
  
  UIChannelFaders(final UI ui) {
    super(ui, Trees.this.width/2-WIDTH/2, Trees.this.height-HEIGHT-PADDING, WIDTH, HEIGHT);
    setBackgroundColor(#292929);
    setBorderColor(#444444);
    
    float labelX = PADDING;
    
    new UIPerfMeters()
    .setPosition(PADDING, PADDING)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING, PADDING, BUTTON_HEIGHT - 1)
    .setLabel("CHAN")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("COPY")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 2 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("FX")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 3 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("INPUT")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 4 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("MIDI")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 5 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("OUT")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 6 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("TOTAL")
    .setFontColor(#666666)
    .addToContainer(this);
    
  }
  
  class UIPerfMeters extends UI2dComponent {
    
    DampedParameter dampers[] = new DampedParameter[7];
    BasicParameter perfs[] = new BasicParameter[7];
   
    UIPerfMeters() {
      for (int i = 0; i < 7; ++i) {
        lx.addModulator((dampers[i] = new DampedParameter(perfs[i] = new BasicParameter("PERF", 0), 3))).start();
      }
    } 
    
    public void onDraw(UI ui, PGraphics pg) {

      float engMillis = lx.engine.timer.channelNanos / 1000000.;
      perfs[0].setValue(constrain(engMillis / (1000. / 60.), 0, 1));
      
      engMillis = lx.engine.timer.copyNanos / 1000000.;
      perfs[1].setValue(constrain(engMillis / (1000. / 60.), 0, 1));
      
      engMillis = lx.engine.timer.fxNanos / 1000000.;
      perfs[2].setValue(constrain(engMillis / (1000. / 60.), 0, 1));
      
      engMillis = lx.engine.timer.inputNanos / 1000000.;
      perfs[3].setValue(constrain(engMillis / (1000. / 60.), 0, 1));
      
      engMillis = lx.engine.timer.midiNanos / 1000000.;
      perfs[4].setValue(constrain(engMillis / (1000. / 60.), 0, 1));
      
      engMillis = lx.engine.timer.outputNanos / 1000000.;
      perfs[5].setValue(constrain(engMillis / (1000. / 60.), 0, 1));

      engMillis = lx.engine.timer.runNanos / 1000000.;
      perfs[6].setValue(constrain(engMillis / (1000. / 60.), 0, 1));

      for (int i = 0; i < 7; ++i) {
        float val = dampers[i].getValuef();
        pg.stroke(#666666);
        pg.fill(#292929);
        pg.rect(0, i*(PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH-1, BUTTON_HEIGHT-1); 
        pg.fill(lx.hsb(120*(1-val), 50, 80));
        pg.noStroke();
        pg.rect(1, i*(PERF_PADDING + BUTTON_HEIGHT-1)+1, val * (FADER_WIDTH-2), BUTTON_HEIGHT-2);
      }

      redraw();
    }
  }
}

