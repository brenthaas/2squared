class TSEffectController {

  String name;
  LXEffect effect;
  Triggerable triggerable;

  TSEffectController(String name, LXEffect effect, Triggerable triggerable) {
    this.name = name;
    this.effect = effect;
    this.triggerable = triggerable;
  }

  String getName() {
    return name;
  }

  boolean getEnabled() {
    return triggerable.isTriggered();
  }

  void setEnabled(boolean enabled) {
    if (enabled) {
      triggerable.onTriggered(1);
    } else {
      triggerable.onRelease();
    }
  }
}

