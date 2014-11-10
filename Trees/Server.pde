Gson gson = new Gson();
ClientCommunicator clientCommunicator = new ClientCommunicator();
ClientModelUpdater clientModelUpdater;

class AppServer {
  LX lx;

  AppServer(LX lx) {
    this.lx = lx;
  }

  void start() {
    Server server = new Server(Trees.this, 5204);
    clientCommunicator.server = server;

    ServerController serverController = new ServerController(lx);
    clientModelUpdater = new ClientModelUpdater(lx, clientCommunicator);
    ParseClientTask parseClientTask = new ParseClientTask(server, clientModelUpdater, serverController);
    lx.engine.addLoopTask(parseClientTask);
  }
}

class ParseClientTask implements LXLoopTask {
  Server server;
  ClientModelUpdater clientModelUpdater;
  ServerController serverController;

  ParseClientTask(Server server, ClientModelUpdater clientModelUpdater, ServerController serverController) {
    this.server = server;
    this.clientModelUpdater = clientModelUpdater;
    this.serverController = serverController;
  }

  public void loop(double deltaMs) {
    try {
      Client client = server.available();
      if (client == null) return;

      String whatClientSaid = client.readStringUntil('\n');
      if (whatClientSaid == null) return;

      print("Request: " + whatClientSaid);

      Map<String, Object> message;
      try {
        message = gson.fromJson(whatClientSaid.trim(), Map.class);
      } catch (Exception e) {
        println(e);
        return;
      }

      String method = (String)message.get("method");
      Map<String, Object> params = (Map)message.get("params");

      if (method == null) return;
      if (params == null) params = new HashMap<String, Object>();

      if (method.equals("loadModel")) {
        clientModelUpdater.sendModel();
      } else if (method.equals("setChannelPattern")) {
        Double channelIndex = (Double)params.get("channelIndex");
        Double patternIndex = (Double)params.get("patternIndex");
        if (channelIndex == null || patternIndex == null) return;
        serverController.setChannelPattern(channelIndex.intValue(), patternIndex.intValue());
      } else if (method.equals("setChannelVisibility")) {
        Double channelIndex = (Double)params.get("channelIndex");
        Double visibility = (Double)params.get("visibility");
        if (channelIndex == null || visibility == null) return;
        serverController.setChannelVisibility(channelIndex.intValue(), visibility);
      } else if (method.equals("setActiveColorEffect")) {
        Double effectIndex = (Double)params.get("effectIndex");
        if (effectIndex == null) return;
        serverController.setActiveColorEffect(effectIndex.intValue());
      } else if (method.equals("setSpeed")) {
        Double amount = (Double)params.get("amount");
        if (amount == null) return;
        serverController.setSpeed(amount);
      } else if (method.equals("setSpin")) {
        Double amount = (Double)params.get("amount");
        if (amount == null) return;
        serverController.setSpin(amount);
      } else if (method.equals("setBlur")) {
        Double amount = (Double)params.get("amount");
        if (amount == null) return;
        serverController.setBlur(amount);
      } else if (method.equals("setStatic")) {
        Double amount = (Double)params.get("amount");
        if (amount == null) return;
        serverController.setStatic(amount);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}

class ServerController {
  LX lx;

  ServerController(LX lx) {
    this.lx = lx;
  }

  void setChannelPattern(int channelIndex, int patternIndex) {
    if (patternIndex == -1) {
      patternIndex = 0;
    } else {
      patternIndex++;
    }
    lx.engine.getChannel(channelIndex).goIndex(patternIndex);
  }

  void setChannelVisibility(int channelIndex, double visibility) {
    lx.engine.getChannel(channelIndex).getFader().setValue(visibility);
  }

  void setActiveColorEffect(int effectIndex) {
    if (activeEffectControllerIndex == effectIndex) {
      return;
    }
    if (activeEffectControllerIndex != -1) {
      TSEffectController effectController = effectControllers.get(activeEffectControllerIndex);
      effectController.setEnabled(false);
    }
    activeEffectControllerIndex = effectIndex;
    if (activeEffectControllerIndex != -1) {
      TSEffectController effectController = effectControllers.get(activeEffectControllerIndex);
      effectController.setEnabled(true);
    }
  }

  void setSpeed(double amount) {
    speedEffect.speed.setValue(amount);
  }

  void setSpin(double amount) {
    spinEffect.spin.setValue(amount);
  }

  void setBlur(double amount) {
    blurEffect.amount.setValue(amount);
  }

  void setStatic(double amount) {
    staticEffect.amount.setValue(amount);
  }
}

class ClientModelUpdater {
  ClientCommunicator communicator;
  LX lx;

  ClientModelUpdater(LX lx, ClientCommunicator communicator) {
    this.lx = lx;
    this.communicator = communicator;
  }

  void sendModel() {
    Map<String, Object> returnParams = new HashMap<String, Object>();

    List<Map> channelsParams = new ArrayList<Map>(lx.engine.getChannels().size());
    for (LXChannel channel : lx.engine.getChannels()) {
      Map<String, Object> channelParams = new HashMap<String, Object>();
      channelParams.put("index", channel.getIndex());
      int currentPatternIndex = channel.getNextPatternIndex();
      if (currentPatternIndex == 0) {
        currentPatternIndex = -1;
      } else {
        currentPatternIndex--;
      }
      channelParams.put("currentPatternIndex", currentPatternIndex);
      channelParams.put("visibility", channel.getFader().getValue());

      List<Map> patternsParams = new ArrayList<Map>(channel.getPatterns().size());
      for (int i = 1; i < channel.getPatterns().size(); i++) {
        TSPattern pattern = (TSPattern)channel.getPatterns().get(i);
        Map<String, Object> patternParams = new HashMap<String, Object>();
        patternParams.put("name", pattern.readableName);
        patternParams.put("index", i-1);
        patternsParams.add(patternParams);
      }
      channelParams.put("patterns", patternsParams);

      channelsParams.add(channelParams);
    }
    returnParams.put("channels", channelsParams);

    List<Map> effectsParams = new ArrayList<Map>(effectControllers.size());
    for (int i = 0; i < effectControllers.size(); i++) {
      TSEffectController effectController = effectControllers.get(i);
      Map<String, Object> effectParams = new HashMap<String, Object>();
      effectParams.put("index", i);
      effectParams.put("name", effectController.getName());
      effectsParams.add(effectParams);
    }
    returnParams.put("colorEffects", effectsParams);

    int activeColorEffectIndex = activeEffectControllerIndex;
    returnParams.put("activeColorEffectIndex", activeColorEffectIndex);

    returnParams.put("speed", speedEffect.speed.getValue());
    returnParams.put("spin", spinEffect.spin.getValue());
    returnParams.put("blur", blurEffect.amount.getValue());
    returnParams.put("static", staticEffect.amount.getValue());

    communicator.send("model", returnParams);
  }
}

class ClientCommunicator {
  Server server;

  void send(String method, Map params) {
    Map<String, Object> json = new HashMap<String, Object>();
    json.put("method", method);
    json.put("params", params);
    println("Response: " + gson.toJson(json));
    server.write(gson.toJson(json) + "\r\n");
  }

  void disconnectClient(Client client) {
    client.dispose();
    server.disconnect(client);
  }
}

// Hack because of a bug
// See: https://github.com/processing/processing/issues/2577
void disconnectEvent(Client client) {
  clientCommunicator.disconnectClient(client);
}

