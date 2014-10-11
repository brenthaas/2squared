
BooleanParameter[] previewChannels = new BooleanParameter[NUM_CHANNELS];

int focusedChannel() {
  return lx.engine.focusedChannel.getValuei();
}

final static byte[] APC_MODE_SYSEX = {
  (byte) 0xf0, // sysex start
  (byte) 0x47, // manufacturers id
  (byte) 0x00, // device id
  (byte) 0x73, // product model id
  (byte) 0x60, // message
  (byte) 0x00, // bytes MSB
  (byte) 0x04, // bytes LSB
  (byte) 0x42, // ableton mode 2
  (byte) 0x08, // version maj
  (byte) 0x01, // version min
  (byte) 0x01, // version bugfix
  (byte) 0xf7, // sysex end
};

class MidiEngine {
  
  public MidiEngine(LXListenableNormalizedParameter[] effectKnobParameters) {
    try {
      setAPC40Mode();
    } catch (java.lang.UnsatisfiedLinkError e){
      return;
    }
    LXMidiInput apcInput = APC40.matchInput(lx);
    LXMidiOutput apcOutput = APC40.matchOutput(lx);
        
    if (apcInput != null) {
      
      // Add this input to the midi engine so that events are recorded
      lx.engine.midiEngine.addInput(apcInput);

      final APC40 apc40 = new APC40(apcInput, apcOutput) {
        protected void noteOn(LXMidiNoteOn note) {
          int channel = note.getChannel();
          switch (note.getPitch()) {
          
          case APC40.SOLO_CUE:
            if (previewChannels[channel].isOn() && channel != focusedChannel()) {
              lx.engine.focusedChannel.setValue(channel);
            }
            break;
                        
          case APC40.SEND_A:
            bpmTool.beatType.increment();
            break;
          case APC40.SEND_B:
            bpmTool.tempoLfoType.increment();
            break;
            
          case APC40.MASTER_TRACK:
          case APC40.SHIFT:
            uiDeck.select();
            break;
          case APC40.BANK_UP:
            uiDeck.scroll(-1);
            break;
          case APC40.BANK_DOWN:
            uiDeck.scroll(1);
            break;
          case APC40.BANK_RIGHT:
            lx.engine.focusedChannel.increment();
            break;
          case APC40.BANK_LEFT:
            lx.engine.focusedChannel.decrement();
            break;
          }
        }
        
        protected void controlChange(LXMidiControlChange controller) {
          switch (controller.getCC()) {
          case APC40.CUE_LEVEL:
            uiDeck.knob(controller.getValue());
            break;
          }
        }
      };
      
      int[] channelIndices = new int[NUM_CHANNELS];
      for (int i = 0; i < NUM_CHANNELS; ++i) {
        channelIndices[i] = i;
      }
      
      // Track selection
      apc40.bindNotes(lx.engine.focusedChannel, channelIndices, APC40.TRACK_SELECTION);
      
      for (int i = 0; i < NUM_CHANNELS; i++) {
        // Cue activators
        apc40.bindNote(previewChannels[i], i, APC40.SOLO_CUE, LXMidiDevice.TOGGLE);

        apc40.bindController(lx.engine.getChannel(i).getFader(), i, APC40.VOLUME, LXMidiDevice.TakeoverMode.PICKUP);
      }
      
      for (int i = 0; i < 8; ++i) {
        apc40.sendController(0, APC40.TRACK_CONTROL_LED_MODE + i, APC40.LED_MODE_VOLUME);
        apc40.sendController(0, APC40.DEVICE_CONTROL_LED_MODE + i, APC40.LED_MODE_VOLUME);
      }
      
      // Master fader
      apc40.bindController(Trees.this.output.brightness, 0, APC40.MASTER_FADER, LXMidiDevice.TakeoverMode.PICKUP);

      apc40.bindController(drumpadVelocity, 0, APC40.CROSSFADER);
      
      // Effect knobs + buttons
      for (int i = 0; i < effectKnobParameters.length; ++i) {
        if (effectKnobParameters[i] != null) {
          apc40.bindController(effectKnobParameters[i], 0, APC40.TRACK_CONTROL + i);
        }
      }
      
      // Pattern control
      apc40.bindDeviceControlKnobs(lx.engine);
      lx.engine.focusedChannel.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          apc40.bindNotes(
            getFaderTransition(lx.engine.getFocusedChannel()).blendMode,
            0,
            new int[] { APC40.CLIP_TRACK, APC40.DEVICE_ON_OFF, APC40.LEFT_ARROW, APC40.RIGHT_ARROW }
          );
        }
      });
      
      // Tap Tempo
      apc40.bindNote(new BooleanParameter("ANON", false), 0, APC40.SEND_A, APC40.DIRECT);
      apc40.bindNote(new BooleanParameter("ANON", false), 0, APC40.SEND_B, APC40.DIRECT);
      apc40.bindNote(bpmTool.addTempoLfo, 0, APC40.PAN, APC40.DIRECT);
      apc40.bindNote(bpmTool.clearAllTempoLfos, 0, APC40.SEND_C, APC40.DIRECT);
      apc40.bindNote(bpmTool.tapTempo, 0, APC40.TAP_TEMPO, APC40.DIRECT);
      apc40.bindNote(bpmTool.nudgeUpTempo, 0, APC40.NUDGE_PLUS, APC40.DIRECT);
      apc40.bindNote(bpmTool.nudgeDownTempo, 0, APC40.NUDGE_MINUS, APC40.DIRECT);
      
      apc40.bindNotes(
        getFaderTransition(lx.engine.getFocusedChannel()).blendMode,
        0,
        new int[] { APC40.CLIP_TRACK, APC40.DEVICE_ON_OFF, APC40.LEFT_ARROW, APC40.RIGHT_ARROW }
      );
      apc40.bindNotes(
        automationSlot,
        0,
        new int[] { APC40.DETAIL_VIEW, APC40.REC_QUANTIZATION, APC40.MIDI_OVERDUB, APC40.METRONOME }
      );
      automationSlot.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          setAutomation(apc40);
        }
      });
      setAutomation(apc40);
    }
    
  }
  
  void setAutomation(APC40 apc40) {
    LXAutomationRecorder auto = automation[automationSlot.getValuei()];
    apc40.bindNoteOn(auto.isRunning, 0, APC40.PLAY, LXMidiDevice.TOGGLE);
    apc40.bindNoteOn(auto.armRecord, 0, APC40.REC, LXMidiDevice.TOGGLE);
    apc40.bindNote(automationStop[automationSlot.getValuei()], 0, APC40.STOP, LXMidiDevice.DIRECT);
  }
  
  void setAPC40Mode() {
    int i = 0;
    for (String info : de.humatic.mmj.MidiSystem.getOutputs()) { 
      if (info.contains("APC40")) {
        de.humatic.mmj.MidiSystem.openMidiOutput(i).sendMidi(APC_MODE_SYSEX);
        break;
      }
      ++i;
    }
  }
}

