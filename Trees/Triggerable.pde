public interface Triggerable {
  public boolean isTriggered();
  public void onTriggered(float strength);
  public void onRelease();
  public void addOutputTriggeredListener(LXParameterListener listener);
}

public class ParameterTriggerableAdapter implements Triggerable, LXLoopTask {

  private final BooleanParameter triggeredEventParameter = new BooleanParameter("ANON");
  private final DampedParameter triggeredEventDampedParameter = new DampedParameter(triggeredEventParameter, 2);
  private final BooleanParameter isDampening = new BooleanParameter("ANON");
  private double strength;

  private final LXNormalizedParameter enabledParameter;
  private final double offValue;
  private final double onValue;
  
  ParameterTriggerableAdapter(LXNormalizedParameter enabledParameter) {
    this(enabledParameter, 0, 1);
  }
  
  ParameterTriggerableAdapter(LXNormalizedParameter enabledParameter, double offValue, double onValue) {
    this.enabledParameter = enabledParameter;
    this.offValue = offValue;
    this.onValue = onValue;

    lx.engine.addLoopTask(this);
    speedIndependentContainer.addLoopTask(triggeredEventDampedParameter.start());
  }

  public void loop(double deltaMs) {
    if (isDampening.isOn()) {
      enabledParameter.setValue((onValue - offValue) * strength * triggeredEventDampedParameter.getValue() + offValue);
      if (triggeredEventDampedParameter.getValue() == triggeredEventParameter.getValue()) {
        isDampening.setValue(false);
      }
    } else {
      if (triggeredEventDampedParameter.getValue() != triggeredEventParameter.getValue()) {
        enabledParameter.setValue((onValue - offValue) * strength * triggeredEventDampedParameter.getValue() + offValue);
        isDampening.setValue(true);
      }
    }
  }

  public boolean isTriggered() {
    return triggeredEventParameter.isOn();
  }

  public void addOutputTriggeredListener(final LXParameterListener listener) {
    isDampening.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        listener.onParameterChanged(triggeredEventDampedParameter);
      }
    });
  }
  
  public void onTriggered(float strength) {
    this.strength = strength;
    triggeredEventDampedParameter.setValue((enabledParameter.getValue() - offValue) / (onValue - offValue));
    // println((enabledParameter.getValue() - offValue) / (onValue - offValue));
    triggeredEventParameter.setValue(true);
  }
  
  public void onRelease() {
    triggeredEventDampedParameter.setValue((enabledParameter.getValue() - offValue) / (onValue - offValue));
    triggeredEventParameter.setValue(false);
  }
}

// This is a place to add loop tasks that ignore the engine speed modifier
// This is helpful when you're adding something that isn't directly modifying
// the visuals. For example, a timer or modulator affecting UI controls.
class SpeedIndependentContainer implements LXLoopTask {

  private final List<LXLoopTask> loopTasks = new ArrayList<LXLoopTask>();

  private long nowMillis;
  private long lastMillis;

  SpeedIndependentContainer(LX lx) {
    lastMillis = System.currentTimeMillis();
  }

  public void addLoopTask(LXLoopTask loopTask) {
    this.loopTasks.add(loopTask);
  }

  public void loop(double deltaMsSkewed) {
    this.nowMillis = System.currentTimeMillis();
    double deltaMs = this.nowMillis - this.lastMillis;
    this.lastMillis = this.nowMillis;

    // Run loop tasks
    for (LXLoopTask loopTask : this.loopTasks) {
      loopTask.loop(deltaMs);
    }
  }
}

