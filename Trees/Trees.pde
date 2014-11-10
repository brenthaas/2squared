import heronarts.lx.*;
import heronarts.lx.audio.*;
import heronarts.lx.color.*;
import heronarts.lx.effect.*;
import heronarts.lx.midi.*;
import heronarts.lx.model.*;
import heronarts.lx.output.*;
import heronarts.lx.parameter.*;
import heronarts.lx.pattern.*;
import heronarts.lx.transform.*;
import heronarts.lx.transition.*;
import heronarts.lx.midi.*;
import heronarts.lx.modulator.*;

import heronarts.p2lx.*;
import heronarts.p2lx.ui.*;
import heronarts.p2lx.ui.component.*;
import heronarts.p2lx.ui.control.*;

import ddf.minim.*;
import processing.opengl.*;
import processing.net.*;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

final static int INCHES = 1;
final static int FEET = 12 * INCHES;

final static int SECONDS = 1000;
final static int MINUTES = 60*SECONDS;

final static float CHAIN = -12*INCHES;
final static float BOLT = 22*INCHES;

final static int FRONT = 0;
final static int RIGHT = 1;
final static int REAR = 2;
final static int LEFT = 3;
final static int FRONT_RIGHT = 4;
final static int REAR_RIGHT = 5;
final static int REAR_LEFT = 6;
final static int FRONT_LEFT = 7;

final static int NUM_AUTOMATION = 4;
final static int NUM_CHANNELS = 3;

/**
 * This defines the positions of the trees, which are
 * x (left to right), z (front to back), and rotation
 * in degrees.
 */
final static float[][] TREE_POSITIONS = {
  /*  X-pos    Y-pos    Rot  */
  {  15*FEET,  15*FEET,   0  }
};

final static String CLUSTER_CONFIG_FILE = "data/clusters.json";

void registerPatternTriggerables() {
  registerPattern("None", new NoPattern(lx));
  registerPattern("Twister", new Twister(lx));
  // registerPattern(new MarkLottor(lx));
  registerPattern("Ripple", new Ripple(lx));
  registerPattern("Stripes", new Stripes(lx));
  registerPattern("Lattice", new Lattice(lx));
  registerPattern("Fumes", new Fumes(lx));
  registerPattern("Voronoi", new Voronoi(lx));
  registerPattern("Candy Cloud", new CandyCloud(lx));
  registerPattern("Galaxy Cloud", new GalaxyCloud(lx));

  registerPattern("Color Strobe", new ColorStrobe(lx));
  registerPattern("Strobe", new Strobe(lx));
  registerPattern("Sparkle Takeover", new SparkleTakeOver(lx));
  registerPattern("Multi-Sine", new MultiSine(lx));
  registerPattern("Seesaw", new SeeSaw(lx));
  registerPattern("Cells", new Cells(lx));
  registerPattern("Fade", new Fade(lx));
  
  // registerPattern(new IceCrystals(lx));
  registerPattern("Fire", new Fire(lx));

  registerPattern("Acid Trip", new AcidTrip(lx));
  registerPattern("Rain", new Rain(lx));
  registerPattern("Bass Slam", new BassSlam(lx));

  registerPattern("Fireflies", new Fireflies(lx));
  registerPattern("Bubbles", new Bubbles(lx));
  // registerPattern(new Lightning(lx));
  registerPattern("Wisps", new Wisps(lx));
  registerPattern("Fireworks", new Explosions(lx));

  // registerPattern(new Explosions(lx, 20));
  // registerPattern(new Wisps(lx, 1, 60, 50, 270, 20, 3.5, 10)); // downward yellow wisp
  // registerPattern(new Wisps(lx, 30, 210, 100, 90, 20, 3.5, 10)); // colorful wisp storm
  // registerPattern(new Wisps(lx, 1, 210, 100, 90, 130, 3.5, 10)); // multidirection colorful wisps
  // registerPattern(new Wisps(lx, 3, 210, 10, 270, 0, 3.5, 10)); // rain storm of wisps
  // registerPattern(new Wisps(lx, 35, 210, 180, 180, 15, 2, 15)); // twister of wisps
  // registerPattern(new Fireflies(lx, 70, 6, 180));
  // registerPattern(new Fireflies(lx, 40, 7.5, 90));
}

SpeedEffect speedEffect;
SpinEffect spinEffect;
BlurEffect blurEffect;
StaticEffect staticEffect;

void registerEffectTriggerables() {
  ColorEffect colorEffect = new ColorEffect(lx);
  ColorStrobeTextureEffect colorStrobeTextureEffect = new ColorStrobeTextureEffect(lx);
  FadeTextureEffect fadeTextureEffect = new FadeTextureEffect(lx);
  AcidTripTextureEffect acidTripTextureEffect = new AcidTripTextureEffect(lx);
  CandyTextureEffect candyTextureEffect = new CandyTextureEffect(lx);
  CandyCloudTextureEffect candyCloudTextureEffect = new CandyCloudTextureEffect(lx);
  // GhostEffect ghostEffect = new GhostEffect(lx);
  // ScrambleEffect scrambleEffect = new ScrambleEffect(lx);
  // RotationEffect rotationEffect = new RotationEffect(lx);

  speedEffect = new SpeedEffect(lx);
  spinEffect = new SpinEffect(lx);
  blurEffect = new BlurEffect(lx);
  staticEffect = new StaticEffect(lx);

  lx.addEffect(blurEffect);
  lx.addEffect(colorEffect);
  lx.addEffect(staticEffect);
  lx.addEffect(spinEffect);
  lx.addEffect(speedEffect);
  lx.addEffect(colorStrobeTextureEffect);
  lx.addEffect(fadeTextureEffect);
  lx.addEffect(acidTripTextureEffect);
  lx.addEffect(candyTextureEffect);
  lx.addEffect(candyCloudTextureEffect);
  // lx.addEffect(ghostEffect);
  // lx.addEffect(scrambleEffect);
  // lx.addEffect(rotationEffect);

  registerEffectControlParameter("Rainbow", candyCloudTextureEffect, candyCloudTextureEffect.amount);
  registerEffectControlParameter("Candy Chaos", candyTextureEffect, candyTextureEffect.amount);
  registerEffectControlParameter("Color Strobe", colorStrobeTextureEffect, colorStrobeTextureEffect.amount);
  registerEffectControlParameter("Fade", fadeTextureEffect, fadeTextureEffect.amount);
  registerEffectControlParameter("Monochrome", colorEffect, colorEffect.mono);
  registerEffectControlParameter("White", colorEffect, colorEffect.desaturation);
  // registerEffectControlParameter("Acid", acidTripTextureEffect, acidTripTextureEffect.amount);
  // registerEffectControlParameter("Rainbow", colorEffect, colorEffect.rainbow);
  // registerEffectControlParameter("Slow", speedEffect, speedEffect.speed, 1, 0.4);
  // registerEffectControlParameter("Fast", speedEffect, speedEffect.speed, 1, 5);
  // registerEffectControlParameter("Blur", blurEffect, blurEffect.amount, 0.65);
  // registerEffectControlParameter("Spin", spinEffect, spinEffect.spin, 0.65);
  // registerEffectControlParameter("Sharpen", colorEffect, colorEffect.sharp);
  // registerEffectControlParameter("Ghost", ghostEffect, ghostEffect.amount, 0, 0.16);
  // registerEffectControlParameter("Scramble", scrambleEffect, scrambleEffect.amount);
  // registerEffectControlParameter("Static", staticEffect, staticEffect.amount, 0, .3);
}

static JSONArray clusterConfig;
static Geometry geometry = new Geometry();

Model model;
P2LX lx;
FadecandyOutput output;
final BasicParameter bgLevel = new BasicParameter("BG", 25, 0, 50);
final BasicParameter dissolveTime = new BasicParameter("DSLV", 400, 50, 1000);
MappingTool mappingTool;
LXAutomationRecorder[] automation = new LXAutomationRecorder[NUM_AUTOMATION];
BooleanParameter[] automationStop = new BooleanParameter[NUM_AUTOMATION]; 
DiscreteParameter automationSlot = new DiscreteParameter("AUTO", NUM_AUTOMATION);
SpeedIndependentContainer speedIndependentContainer;

boolean headless = false;
boolean disableAutomation = true;
boolean disableMainChannels = true;

void setup() {
  if (headless) {
    noLoop();
  } else {
    size(1148, 720, OPENGL);
  }
  
  clusterConfig = loadJSONArray(CLUSTER_CONFIG_FILE);
  geometry = new Geometry();
  model = new Model();
  
  lx = new P2LX(this, model);
  lx.engine.addLoopTask(speedIndependentContainer = new SpeedIndependentContainer(lx));

  configureTriggerables();

  lx.engine.removeChannel(lx.engine.getDefaultChannel());

  if (!headless) {
    lx.addEffect(mappingTool = new MappingTool(lx));
  }
  lx.engine.addLoopTask(new ModelTransformTask());

  if (disableAutomation) {
    configureAutomation();
  }

  configureFadeCandyOutput();

  if (!headless) {
    configureUI();
  }

  configureRPC();
  
  lx.engine.setThreaded(true);
}

/* configureChannels */

void setupChannel(final LXChannel channel, boolean noOpWhenNotRunning) {
  channel.setFaderTransition(new TreesTransition(lx, channel));

  if (noOpWhenNotRunning) {
    channel.enabled.setValue(channel.getFader().getValue() != 0);
    channel.getFader().addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        channel.enabled.setValue(channel.getFader().getValue() != 0);
      }
    });
  }
}

/* configureAutomation */

void configureAutomation() {
  // Example automation message to change master fader
  // {
  //   "message": "master/0.5",
  //   "event": "MESSAGE",
  //   "millis": 0
  // },
  lx.engine.addMessageListener(new LXEngine.MessageListener() {
    public void onMessage(LXEngine engine, String message) {
      if (message.length() > 8 && message.substring(0, 7).equals("master/")) {
        double value = Double.parseDouble(message.substring(7));
        output.brightness.setValue(value);
      }
    }
  });

  // Automation recorders
  for (int i = 0; i < automation.length; ++i) {
    final int ii = i;
    automation[i] = new LXAutomationRecorder(lx.engine);
    lx.engine.addLoopTask(automation[i]);
    automationStop[i] = new BooleanParameter("STOP", false);
    automationStop[i].addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        if (parameter.getValue() > 0) {
          automation[ii].reset();
          automation[ii].armRecord.setValue(false);
        }
      }
    });
  }
}

/* configureTriggerables */

ArrayList<TSPattern> patterns;
ArrayList<TSEffectController> effectControllers;
int activeEffectControllerIndex = -1;

void configureTriggerables() {
  for (int i = 0; i < NUM_CHANNELS; i++) {
    patterns = new ArrayList<TSPattern>();
    registerPatternTriggerables();

    LXChannel channel = lx.engine.addChannel(patterns.toArray(new TSPattern[0]));
    if (i == 0) {
      channel.goIndex(1);
    }
    channel.getFader().setValue(1);
    setupChannel(channel, true);
  }
  patterns = null;

  effectControllers = new ArrayList<TSEffectController>();
  registerEffectTriggerables();
}

void registerPattern(String name, TSPattern pattern) {
  LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
  pattern.setTransition(t);
  pattern.readableName = name;
  patterns.add(pattern);
}

/* configureEffects */

void registerEffectControlParameter(String name, LXEffect effect, LXListenableNormalizedParameter parameter) {
  registerEffectControlParameter(name, effect, parameter, 0, 1);
}

void registerEffectControlParameter(String name, LXEffect effect, LXListenableNormalizedParameter parameter, double onValue) {
  registerEffectControlParameter(name, effect, parameter, 0, onValue);
}

void registerEffectControlParameter(String name, LXEffect effect, LXListenableNormalizedParameter parameter, double offValue, double onValue) {
  ParameterTriggerableAdapter triggerable = new ParameterTriggerableAdapter(parameter, offValue, onValue);
  TSEffectController effectController = new TSEffectController(name, effect, triggerable);

  effectControllers.add(effectController);
}

/* configureUI */

void configureUI() {
  // UI initialization
  lx.ui.addLayer(new UI3dContext(lx.ui) {
      protected void beforeDraw() {
        hint(ENABLE_DEPTH_TEST);
        pushMatrix();
        translate(0, 12*FEET, 0);
      }
      protected void afterDraw() {
        popMatrix();
        hint(DISABLE_DEPTH_TEST);
      }  
    }
    .setRadius(90*FEET)
    .setCenter(model.cx, model.cy, model.cz)
    .setTheta(30*PI/180)
    .setPhi(10*PI/180)
    .addComponent(new UITrees())
  );
  lx.ui.addLayer(new UIMapping(lx.ui));
  lx.ui.addLayer(new UIChannelFaders(lx.ui));
  if (!disableAutomation) {
    lx.ui.addLayer(new UILoopRecorder(lx.ui));
  }
}

/* configureFadeCandyOutput */

void configureFadeCandyOutput() {
  int[] clusterOrdering = new int[] { 0, 1, 2, 3, 4, 5, 8, 7, 9, 10, 11, 12, 13, 15, 14, 6 };
  int numCubesInCluster = clusterOrdering.length;
  int numClusters = 48;
  int[] pixelOrder = new int[numClusters * numCubesInCluster];
  for (int cluster = 0; cluster < numClusters; cluster++) {
    for (int cube = 0; cube < numCubesInCluster; cube++) {
      pixelOrder[cluster * numCubesInCluster + cube] = cluster * numCubesInCluster + clusterOrdering[cube];
    }
  }
  try {
    output = new FadecandyOutput(lx, "127.0.0.1", 7890, pixelOrder);
    lx.addOutput(output);
  } catch (Exception e) {
    println(e);
  }
}

/* configureRPC */

void configureRPC() {
  new AppServer(lx).start();
}

void draw() {
  background(#222222);
}

TreesTransition getFaderTransition(LXChannel channel) {
  return (TreesTransition)channel.getFaderTransition();
}

static class Blender {
  static void computeBlend(int[] output, int[] c1, int[] c2, double progress, LXColor.Blend blendType) {
    if (progress == 0) {
      for (int i = 0; i < output.length; ++i) {
        output[i] = c1[i];
      }
    } else if (progress == 1) {
      for (int i = 0; i < output.length; ++i) {
        int color2 = (blendType == LXColor.Blend.SUBTRACT) ? LX.hsb(0, 0, LXColor.b(c2[i])) : c2[i]; 
        output[i] = LXColor.blend(c1[i], color2, blendType);
      }
    } else {
      for (int i = 0; i < output.length; ++i) {
        int color2 = (blendType == LXColor.Blend.SUBTRACT) ? LX.hsb(0, 0, LXColor.b(c2[i])) : c2[i];
        output[i] = LXColor.lerp(c1[i], LXColor.blend(c1[i], color2, blendType), progress);
      }
    }
  }
}

class TreesTransition extends LXTransition {
  
  private final LXChannel channel;
  
  public final DiscreteParameter blendMode = new DiscreteParameter("MODE", 4);
  private LXColor.Blend blendType = LXColor.Blend.ADD;

  final BasicParameter fade = new BasicParameter("FADE", 1);
    
  TreesTransition(LX lx, LXChannel channel) {
    super(lx);
    addParameter(blendMode);
    
    this.channel = channel;
    blendMode.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        switch (blendMode.getValuei()) {
        case 0: blendType = LXColor.Blend.ADD; break;
        case 1: blendType = LXColor.Blend.MULTIPLY; break;
        case 2: blendType = LXColor.Blend.LIGHTEST; break;
        case 3: blendType = LXColor.Blend.SUBTRACT; break;
        }
      }
    });
  }
  
  protected void computeBlend(int[] c1, int[] c2, double progress) {
    Blender.computeBlend(colors, c1, c2, progress, blendType);
    // LXColor.scaleBrightness(c2, fade.getValuef(), colors);
    // Blender.computeBlend(colors, c1, colors, progress, blendType);
  }
}

int focusedChannel() {
  return lx.engine.focusedChannel.getValuei();
}

